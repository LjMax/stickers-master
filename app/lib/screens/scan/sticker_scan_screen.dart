import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../l10n/app_localizations.dart';
import '../../models/album.dart';
import '../../models/sticker.dart';
import '../../providers/album_provider.dart';
import '../../providers/collection_provider.dart';
import '../../providers/scan_settings_provider.dart';
import '../../services/sticker_ocr_parser.dart';

/// In-app sticker scanner.
///
/// Workflow:
///   1. Camera streams frames at the device's natural rate.
///   2. Each frame (single-flight; never queue) is fed to ML Kit's text
///      recogniser.
///   3. The recognised text is parsed by [StickerOcrParser] and
///      cross-checked against the album's known sticker codes — invalid
///      candidates (FIFA, CUP 2026, etc.) are silently dropped.
///   4. When the same valid code is seen on two consecutive successful
///      OCR passes, it's "locked in", the stream is paused, and the user
///      is shown the result card.
///   5. The user adds it (or another duplicate). If the auto-advance
///      preference is on, scanning resumes immediately; otherwise the
///      user taps "Scan next sticker".
///
/// The two-frame stability check is what lets us go shutter-less without
/// becoming twitchy on transient mis-reads.
class StickerScanScreen extends ConsumerStatefulWidget {
  const StickerScanScreen({super.key});

  @override
  ConsumerState<StickerScanScreen> createState() => _StickerScanScreenState();
}

enum _ScanPhase {
  initializing,
  permissionDenied,
  scanning,
  matched,
  cameraError,
}

class _StickerScanScreenState extends ConsumerState<StickerScanScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  TextRecognizer? _ocr;
  StickerOcrParser? _parser;
  Album? _album;

  _ScanPhase _phase = _ScanPhase.initializing;

  /// Single-flight latch: while a frame is in the recogniser we ignore
  /// all incoming frames so we don't pile up work.
  bool _busy = false;

  /// Stable-match tracker: the last validated code we saw. We commit a
  /// match once the *same* code appears on two consecutive reads.
  String? _lastSeenCode;

  /// Just-added confirmation, briefly shown after Add/Duplicate. Cleared
  /// when scanning resumes (auto-advance) or the user taps "Scan next".
  String? _justAddedSummary;

  /// The currently-locked match shown to the user.
  Sticker? _matchedSticker;

  /// Toggleable during a session: tapping the icon in the AppBar flips
  /// the auto-advance setting and persists it.
  bool get _autoAdvance => ref.read(scanSettingsProvider).autoAdvance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shutdownCamera();
    _ocr?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _shutdownCamera();
    } else if (state == AppLifecycleState.resumed) {
      _bootstrap();
    }
  }

  Future<void> _bootstrap() async {
    try {
      // Load the album dictionary once. The scan workflow is gated on
      // it; if the album doesn't load, OCR has nothing to validate against.
      _album ??= await ref.read(albumProvider.future);
      _parser ??= StickerOcrParser(
        _album!.stickers.map((s) => s.code).toSet(),
      );

      _ocr ??= TextRecognizer(script: TextRecognitionScript.latin);

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _phase = _ScanPhase.cameraError);
        return;
      }
      final rear = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        rear,
        ResolutionPreset.medium, // 720p is plenty for clean sans-serif text
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      _camera = controller;

      await controller.startImageStream(_onFrame);
      if (!mounted) return;
      setState(() => _phase = _ScanPhase.scanning);
    } on CameraException catch (e) {
      if (kDebugMode) debugPrint('scan: camera init failed: ${e.code} ${e.description}');
      if (!mounted) return;
      setState(() {
        _phase = e.code == 'CameraAccessDenied'
            ? _ScanPhase.permissionDenied
            : _ScanPhase.cameraError;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('scan: bootstrap failed: $e');
      if (!mounted) return;
      setState(() => _phase = _ScanPhase.cameraError);
    }
  }

  Future<void> _shutdownCamera() async {
    final cam = _camera;
    _camera = null;
    if (cam == null) return;
    try {
      if (cam.value.isStreamingImages) {
        await cam.stopImageStream();
      }
    } catch (_) {/* ignore */}
    await cam.dispose();
  }

  /// Camera image-stream callback. Single-flight: while a recogniser
  /// pass is running, subsequent frames are dropped.
  Future<void> _onFrame(CameraImage image) async {
    if (_busy || _phase != _ScanPhase.scanning) return;
    final parser = _parser;
    final ocr = _ocr;
    final cam = _camera;
    if (parser == null || ocr == null || cam == null) return;

    _busy = true;
    try {
      final input = _toInputImage(image, cam.description);
      if (input == null) return;
      final recognised = await ocr.processImage(input);
      if (!mounted) return;
      _consumeOcrText(recognised.text, parser);
    } catch (e) {
      if (kDebugMode) debugPrint('scan: OCR failed: $e');
    } finally {
      _busy = false;
    }
  }

  void _consumeOcrText(String text, StickerOcrParser parser) {
    final code = parser.firstValidCode(text);
    if (code == null) {
      // Lost the candidate — reset the stability tracker so we don't
      // accidentally commit a stale match later.
      _lastSeenCode = null;
      return;
    }
    if (_lastSeenCode == code) {
      // Same code twice in a row → commit it.
      _commitMatch(code);
    } else {
      _lastSeenCode = code;
    }
  }

  void _commitMatch(String code) {
    final album = _album;
    if (album == null) return;
    Sticker? sticker;
    for (final s in album.stickers) {
      if (s.code == code) {
        sticker = s;
        break;
      }
    }
    if (sticker == null) return;
    // Pause the stream while the result card is up.
    _camera?.stopImageStream();
    setState(() {
      _phase = _ScanPhase.matched;
      _matchedSticker = sticker;
      _justAddedSummary = null;
    });
  }

  Future<void> _addOrDuplicate(Sticker sticker) async {
    final album = _album!;
    final notifier = ref.read(collectionProvider(album.id).notifier);
    final l = AppLocalizations.of(context);
    await notifier.increment(sticker.code);
    if (!mounted) return;
    final newCount = notifier.countFor(sticker.code);
    final summary = newCount > 1
        ? l.scanAddedDuplicateSummary(sticker.code, newCount - 1)
        : l.scanAddedSummary(sticker.code);
    setState(() => _justAddedSummary = summary);

    if (_autoAdvance) {
      // Brief in-place confirmation, then resume scanning automatically.
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;
      _resumeScanning();
    }
  }

  void _resumeScanning() {
    final cam = _camera;
    if (cam == null) {
      _bootstrap();
      return;
    }
    _lastSeenCode = null;
    _matchedSticker = null;
    _justAddedSummary = null;
    setState(() => _phase = _ScanPhase.scanning);
    if (!cam.value.isStreamingImages) {
      cam.startImageStream(_onFrame);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final autoAdvance = ref.watch(
      scanSettingsProvider.select((s) => s.autoAdvance),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l.scanStickerTitle),
        actions: [
          IconButton(
            tooltip: l.scanAutoAdvanceTooltip,
            icon: Icon(autoAdvance ? Icons.fast_forward : Icons.fast_forward_outlined),
            onPressed: () => ref
                .read(scanSettingsProvider.notifier)
                .setAutoAdvance(!autoAdvance),
          ),
        ],
      ),
      body: _buildBody(l),
    );
  }

  Widget _buildBody(AppLocalizations l) {
    switch (_phase) {
      case _ScanPhase.initializing:
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      case _ScanPhase.permissionDenied:
        return _MessagePane(
          icon: Icons.no_photography_outlined,
          title: l.scanPermissionDeniedTitle,
          body: l.scanPermissionDeniedBody,
        );
      case _ScanPhase.cameraError:
        return _MessagePane(
          icon: Icons.error_outline,
          title: l.scanCameraErrorTitle,
          body: l.scanCameraErrorBody,
        );
      case _ScanPhase.scanning:
        return _scanningView(l);
      case _ScanPhase.matched:
        return _matchedView(l);
    }
  }

  Widget _scanningView(AppLocalizations l) {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: cam.value.aspectRatio,
            child: CameraPreview(cam),
          ),
        ),
        // Guide overlay: a centered framing rectangle + instruction.
        const _ScanFrameOverlay(),
        Positioned(
          left: 20,
          right: 20,
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l.scanInstruction,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_justAddedSummary != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _justAddedSummary!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _matchedView(AppLocalizations l) {
    final sticker = _matchedSticker;
    if (sticker == null) return const SizedBox.shrink();
    final album = _album!;
    final counts = ref.watch(collectionProvider(album.id));
    final ownedCount = counts[sticker.code] ?? 0;
    final justAdded = _justAddedSummary != null;
    final scheme = Theme.of(context).colorScheme;

    String statusText;
    if (ownedCount == 0) {
      statusText = l.scanStatusMissing;
    } else if (ownedCount == 1) {
      statusText = l.scanStatusHave;
    } else {
      statusText = l.scanStatusHaveWithDuplicates(ownedCount - 1);
    }

    String actionLabel;
    if (ownedCount == 0) {
      actionLabel = l.scanActionAddToAlbum;
    } else {
      actionLabel = l.scanActionAddDuplicate;
    }

    return Container(
      color: Colors.black.withOpacity(0.85),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sticker.code,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _stickerDisplayName(sticker, l),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (!justAdded)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: Icon(
                            ownedCount == 0
                                ? Icons.add_circle_outline
                                : Icons.add_to_photos_outlined,
                          ),
                          onPressed: () => _addOrDuplicate(sticker),
                          label: Text(actionLabel),
                        ),
                      )
                    else
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _justAddedSummary!,
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: _resumeScanning,
                              label: Text(l.scanNextSticker),
                            ),
                          ),
                        ],
                      ),
                    if (!justAdded) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _resumeScanning,
                        child: Text(l.scanSkipThis),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stickerDisplayName(Sticker sticker, AppLocalizations l) {
    // Use the localized group label + the number within group.
    final groupLabel = Localizations.localeOf(context).languageCode == 'sr'
        ? sticker.groupNameSrLatn
        : sticker.groupNameEn;
    if (groupLabel.isEmpty) return sticker.code;
    return '$groupLabel · ${sticker.numberInGroup}';
  }

  /// Build an ML Kit InputImage from a [CameraImage].
  ///
  /// Implementation notes: we initialise the camera with NV21 (Android)
  /// and BGRA8888 (iOS) so both formats give a single plane, which is
  /// what ML Kit's `InputImage.fromBytes` expects. Camera rotation comes
  /// from the sensor's natural orientation; we don't re-rotate for
  /// device orientation because the screen is locked portrait-ish.
  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
}

class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260,
        height: 160,
        child: CustomPaint(
          painter: _FramePainter(color: Colors.white.withOpacity(0.85)),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    // Four L-shaped corners — less visually heavy than a full rectangle.
    const corner = 28.0;
    final p = Path()
      ..moveTo(0, corner)
      ..lineTo(0, 0)
      ..lineTo(corner, 0)
      ..moveTo(size.width - corner, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, corner)
      ..moveTo(size.width, size.height - corner)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - corner, size.height)
      ..moveTo(corner, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height - corner);
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) => old.color != color;
}

class _MessagePane extends StatelessWidget {
  const _MessagePane({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
