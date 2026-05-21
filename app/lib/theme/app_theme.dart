import 'package:flutter/material.dart';

/// Central brand palette and theme construction for Stickers Master.
///
/// One source of truth for the app's brand colours, so they are not
/// re-typed as raw literals across widgets. The launcher icon and the
/// splash screen use the same [AppColors.brandBlue].
class AppColors {
  AppColors._();

  /// Primary brand blue — the seed colour the Material 3 scheme is built
  /// from. Matches the launcher icon background and the splash screen.
  static const Color brandBlue = Color(0xFF1565C0);

  /// Foil / special-sticker accent gold. The single source of truth for
  /// the gold used on foil sticker borders, the stats "specials" badge,
  /// and the foil avatar highlight.
  static const Color foilGold = Color(0xFFC9A227);
}

/// The app's light theme.
ThemeData buildLightTheme() => _buildTheme(Brightness.light);

/// The app's dark theme.
ThemeData buildDarkTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brandBlue,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
  );
}
