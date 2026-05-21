import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../models/sticker.dart';
import '../../providers/collection_provider.dart';
import '../../providers/locale_provider.dart';

/// Bulk-mark screen. Shows the captured photo at the top and a 20-row
/// checkbox list below. The user eyeballs the photo and ticks the stickers
/// they've placed on this page, then taps Save.
///
/// Already-owned stickers (`owned_count >= 1`) are shown locked — scan only
/// flips `0 → 1` (never decreases counts).
class ScanReviewScreen extends ConsumerStatefulWidget {
  const ScanReviewScreen({
    super.key,
    required this.imagePath,
    required this.albumId,
    required this.teamCode,
    required this.teamLabel,
    required this.teamStickers,
  });

  final String imagePath;
  final String albumId;
  final String teamCode;
  final String teamLabel;
  final List<Sticker> teamStickers;

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  final Set<String> _userChecked = {};
  bool _saving = false;

  Future<void> _apply() async {
    if (_userChecked.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);

    final notifier =
        ref.read(collectionProvider(widget.albumId).notifier);
    final changed = await notifier.applyAdditiveOwnedMarks(_userChecked);

    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          changed > 0 ? l.scanAppliedCount(changed) : l.scanNothingChanged,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  void _selectAllEmpty(Map<String, int> counts) {
    setState(() {
      _userChecked
        ..clear()
        ..addAll(widget.teamStickers
            .where((s) => (counts[s.code] ?? 0) == 0)
            .map((s) => s.code));
    });
  }

  void _clearAll() {
    setState(() => _userChecked.clear());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final counts = ref.watch(collectionProvider(widget.albumId));

    final eligibleCount = widget.teamStickers
        .where((s) => (counts[s.code] ?? 0) == 0)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.scanReviewTitle(widget.teamLabel)),
      ),
      body: Column(
        children: [
          _ImagePreview(path: widget.imagePath),
          _InfoBar(message: l.scanBulkInstructions),
          _BulkActions(
            selected: _userChecked.length,
            eligible: eligibleCount,
            onSelectAll: () => _selectAllEmpty(counts),
            onClear: _clearAll,
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: widget.teamStickers.length,
              itemBuilder: (context, i) {
                final s = widget.teamStickers[i];
                final alreadyOwned = (counts[s.code] ?? 0) >= 1;
                final checked = _userChecked.contains(s.code);
                return CheckboxListTile(
                  value: alreadyOwned ? true : checked,
                  onChanged: alreadyOwned
                      ? null
                      : (v) {
                          setState(() {
                            if (v == true) {
                              _userChecked.add(s.code);
                            } else {
                              _userChecked.remove(s.code);
                            }
                          });
                        },
                  secondary: CircleAvatar(
                    backgroundColor: s.isSpecial
                        ? const Color(0xFFC9A227)
                        : Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: s.isSpecial
                        ? Colors.white
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                    child: Text(
                      s.code,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(pickLocalized(
                    locale,
                    s.subcategorySrLatn,
                    s.subcategoryEn,
                  )),
                  subtitle: alreadyOwned
                      ? Text('${l.statusHave} (${counts[s.code]})')
                      : null,
                );
              },
            ),
          ),
          _BottomActions(
            saving: _saving,
            selectedCount: _userChecked.length,
            onRetake: () => Navigator.of(context).pop(),
            onApply: _apply,
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => _openFullscreen(context),
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 48),
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBar extends StatelessWidget {
  const _InfoBar({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _BulkActions extends StatelessWidget {
  const _BulkActions({
    required this.selected,
    required this.eligible,
    required this.onSelectAll,
    required this.onClear,
  });

  final int selected;
  final int eligible;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: eligible == 0 ? null : onSelectAll,
            icon: const Icon(Icons.check_box_outlined, size: 18),
            label: Text(l.scanSelectAllEmpty),
          ),
          TextButton.icon(
            onPressed: selected == 0 ? null : onClear,
            icon: const Icon(Icons.clear, size: 18),
            label: Text(l.scanClearAll),
          ),
          const Spacer(),
          Text(
            '$selected / $eligible',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.saving,
    required this.selectedCount,
    required this.onRetake,
    required this.onApply,
  });

  final bool saving;
  final int selectedCount;
  final VoidCallback onRetake;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: saving ? null : onRetake,
                icon: const Icon(Icons.refresh),
                label: Text(l.scanRetake),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: saving ? null : onApply,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text('${l.scanApply}  ($selectedCount)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
