import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Circular avatar that:
/// - Treats `null` AND empty-string photo URLs the same way (shows the
///   letter fallback) — silently empty URLs from Firebase Auth are a
///   common surprise.
/// - Falls back to the letter — and logs a `debugPrint` — when the image
///   fails to load (e.g. 403/CORS on Google photo URLs), instead of
///   leaving a blank coloured circle.
/// - Renders the first letter of [name] in a coloured circle when no
///   image is available.
class UserAvatar extends StatefulWidget {
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

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  /// Latched true once a network image fails to load, so we render the
  /// letter fallback instead of a blank circle. Reset when the URL changes.
  bool _imageFailed = false;

  bool get _hasPhoto =>
      widget.photoUrl != null && widget.photoUrl!.isNotEmpty && !_imageFailed;

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new URL deserves a fresh attempt — clear the failure latch.
    if (oldWidget.photoUrl != widget.photoUrl) {
      _imageFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.backgroundColor ??
        (widget.foilHighlight ? AppColors.foilGold : scheme.primaryContainer);
    final fg = widget.foregroundColor ??
        (widget.foilHighlight ? Colors.white : scheme.onPrimaryContainer);

    final trimmed = widget.name.trim();
    final letter =
        trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: bg,
      foregroundColor: fg,
      backgroundImage: _hasPhoto ? NetworkImage(widget.photoUrl!) : null,
      onBackgroundImageError: _hasPhoto
          ? (e, st) {
              if (kDebugMode) {
                debugPrint(
                  'UserAvatar: failed to load ${widget.photoUrl} — $e',
                );
              }
              // Fall back to the letter instead of a blank circle.
              if (mounted) setState(() => _imageFailed = true);
            }
          : null,
      child: _hasPhoto
          ? null
          : Text(
              letter,
              style: TextStyle(
                fontSize: widget.radius * 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
