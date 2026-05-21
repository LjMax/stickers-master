import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/sticker.dart';
import '../providers/locale_provider.dart';
import '../screens/scan/scan_review_screen.dart';

/// Opens the system camera for the user to snap an album page, then navigates
/// to [ScanReviewScreen] for OCR + confirmation.
///
/// Uses `image_picker` rather than the `camera` package: this opens the OS
/// camera (familiar UI, handles permissions, flash, focus, etc.) and returns
/// a single image file. No custom preview widget needed — simpler and more
/// reliable for v1.
Future<void> launchScanForTeam(
  BuildContext context, {
  required String albumId,
  required String teamCode,
  required List<Sticker> teamStickers,
}) async {
  if (teamStickers.isEmpty) return;
  final l = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context);
  final first = teamStickers.first;
  final teamLabel = pickLocalized(
    locale,
    first.groupNameSrLatn,
    first.groupNameEn,
  );

  final picker = ImagePicker();
  XFile? picked;
  try {
    picked = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      // Keep full resolution. ML Kit's text recognition benefits from more
      // pixels per character, especially for the small slot numbers Panini
      // prints inside each sticker outline.
      imageQuality: 95,
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.scanCameraError(e.toString()))),
    );
    return;
  }

  if (picked == null) {
    // User cancelled.
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.scanCancelled)),
    );
    return;
  }

  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ScanReviewScreen(
        imagePath: picked!.path,
        albumId: albumId,
        teamCode: teamCode,
        teamLabel: teamLabel,
        teamStickers: teamStickers,
      ),
    ),
  );
}
