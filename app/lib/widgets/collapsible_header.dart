import 'package:flutter/material.dart';

/// A tappable section header used for the FWC specials and the WC group
/// dividers in the album view. Shows a chevron that rotates when collapsed.
class CollapsibleHeader extends StatelessWidget {
  const CollapsibleHeader({
    super.key,
    required this.title,
    required this.progressOwned,
    required this.progressTotal,
    required this.collapsed,
    required this.onTap,
    this.emphasised = false,
  });

  final String title;
  final int progressOwned;
  final int progressTotal;
  final bool collapsed;
  final VoidCallback onTap;

  /// `true` for WC group headers (slightly larger / accent color), `false`
  /// for team subsection headers.
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = progressTotal == 0 ? 0.0 : progressOwned / progressTotal;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, emphasised ? 16 : 8, 12, 6),
      child: Material(
        color: emphasised
            ? scheme.secondaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: emphasised ? 14 : 6,
              vertical: emphasised ? 12 : 6,
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  duration: const Duration(milliseconds: 150),
                  turns: collapsed ? -0.25 : 0,
                  child: Icon(
                    Icons.expand_more,
                    color: emphasised
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: emphasised
                        ? Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                            )
                        : Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                ),
                Text(
                  '$progressOwned / $progressTotal',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: emphasised
                            ? scheme.onSecondaryContainer
                            : scheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
                if (emphasised) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 36,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 4,
                        backgroundColor:
                            scheme.onSecondaryContainer.withOpacity(0.18),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
