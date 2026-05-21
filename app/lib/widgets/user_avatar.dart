import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Circular avatar that:
/// - Treats `null` AND empty-string photo URLs the same way (shows the
///   letter fallback) — silently empty URLs from Firebase Auth are a
///   common surprise.
/// - Logs a `debugPrint` when image loading fails (so we can diagnose
///   "blank circle" cases caused by 403/CORS on Google photo URLs).
/// - Renders the first letter of [name] in a coloured circle when no
///   image is available.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    required this.photoUrl,
    this.radius = 18,
    this.backgroundColor,
    this.foregroundColor,
    this.foilHighlight = false,
  });

  final String name;
  final String? photoUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool foilHighlight;

  bool get _hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ??
        (foilHighlight
            ? AppColors.foilGold
            : scheme.primaryContainer);
    final fg = foregroundColor ??
        (foilHighlight ? Colors.white : scheme.onPrimaryContainer);

    final letter = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      foregroundColor: fg,
      backgroundImage: _hasPhoto ? NetworkImage(photoUrl!) : null,
      onBackgroundImageError: _hasPhoto
          ? (e, st) {
              if (kDebugMode) {
                debugPrint('UserAvatar: failed to load $photoUrl — $e');
              }
            }
          : null,
      child: _hasPhoto
          ? null
          : Text(
              letter,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
