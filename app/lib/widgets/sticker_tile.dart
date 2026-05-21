import 'package:flutter/material.dart';

import '../models/sticker.dart';
import '../theme/app_theme.dart';

/// A compact tile showing the sticker [code] with a visual treatment for
/// its current owned_count. No images — just the code.
///
/// Visual rules:
///  * owned_count == 0: muted/outlined.
///  * owned_count == 1: filled "have" color.
///  * owned_count >= 2: filled + small "x{count}" badge for duplicates.
///  * isSpecial: gold-tinted border regardless of count.
class StickerTile extends StatelessWidget {
  const StickerTile({
    super.key,
    required this.sticker,
    required this.ownedCount,
    required this.onTap,
    this.onLongPress,
  });

  final Sticker sticker;
  final int ownedCount;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOwned = ownedCount >= 1;
    final hasDuplicates = ownedCount >= 2;

    final fillColor = isOwned ? scheme.primaryContainer : scheme.surface;
    final textColor = isOwned ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final borderColor = sticker.isSpecial
        ? AppColors.foilGold // gold for foils
        : (isOwned ? scheme.primary : scheme.outlineVariant);

    return Material(
      color: fillColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: sticker.isSpecial ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  sticker.code,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight:
                        sticker.isSpecial ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              if (hasDuplicates)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: scheme.tertiary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'x${ownedCount - 1}',
                      style: TextStyle(
                        color: scheme.onTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
