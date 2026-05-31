import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/sticker.dart';
import '../providers/collection_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/locale_provider.dart';
import '../screens/sticker_edit_sheet.dart';
import '../services/scan_launcher.dart';
import 'sticker_tile.dart';
import 'team_flag.dart';

/// Renders one team's stickers (or any single sticker group) as a small
/// header followed by a wrap of [StickerTile]s.
///
/// Applies the active [albumFilterProvider]. If the filter leaves zero
/// matching stickers, this widget renders nothing (collapses out).
///
/// Team subsections also show a small "scan page" camera-icon button. The
/// FWC specials section passes empty group names and gets neither the
/// mini-header nor the scan button.
class GroupSection extends ConsumerWidget {
  const GroupSection({
    super.key,
    required this.albumId,
    required this.groupCode,
    required this.groupNameSrLatn,
    required this.groupNameEn,
    required this.stickers,
  });

  final String albumId;
  final String groupCode;
  final String groupNameSrLatn;
  final String groupNameEn;
  final List<Sticker> stickers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final counts = ref.watch(collectionProvider(albumId));
    final notifier = ref.read(collectionProvider(albumId).notifier);
    final filter = ref.watch(albumFilterProvider);

    final visible = stickers
        .where((s) => filter.matches(
              isSpecial: s.isSpecial,
              ownedCount: counts[s.code] ?? 0,
            ))
        .toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    final ownedInGroup =
        stickers.where((s) => (counts[s.code] ?? 0) >= 1).length;
    final title = pickLocalized(locale, groupNameSrLatn, groupNameEn);
    final showMiniHeader = title.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showMiniHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 4),
            child: Row(
              children: [
                // Flag in front of the team name. fifaToFlagCode maps
                // FIFA 3-letter codes to ISO alpha-2 (or gb-eng / gb-sct
                // for home nations). The widget falls back to a neutral
                // pill if the code isn't mapped — so non-team groups
                // like 'FWC' don't crash anything (they don't render
                // this header at all today, but the safety net stays).
                TeamFlag(teamCode: groupCode),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '$ownedInGroup / ${stickers.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: l.scanPageTooltip,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.photo_camera_outlined),
                  onPressed: () => launchScanForTeam(
                    context,
                    albumId: albumId,
                    teamCode: groupCode,
                    teamStickers: stickers,
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 72,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.1,
            ),
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final s = visible[index];
              return StickerTile(
                sticker: s,
                ownedCount: counts[s.code] ?? 0,
                onTap: () => notifier.increment(s.code),
                onLongPress: () => showStickerEditSheet(
                  context,
                  albumId: albumId,
                  sticker: s,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
