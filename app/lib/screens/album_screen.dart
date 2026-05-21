import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/album.dart';
import '../models/sticker.dart';
import '../providers/album_provider.dart';
import '../providers/collapse_provider.dart';
import '../providers/collection_provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/collapsible_header.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/group_section.dart';
import 'sticker_search.dart';

/// Main browse screen — progress card at the top, filter row, then
/// collapsible sections: the FWC specials block, followed by 12 WC group
/// blocks (A → L), each containing 4 team subsections.
class AlbumScreen extends ConsumerWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final asyncAlbum = ref.watch(albumProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.albumPaniniFifa2026),
        centerTitle: false,
        actions: [
          asyncAlbum.maybeWhen(
            data: (album) => IconButton(
              tooltip: l.searchHint,
              icon: const Icon(Icons.search),
              onPressed: () => showSearch<void>(
                context: context,
                delegate: StickerSearchDelegate(
                  album: album,
                  hintText: l.searchHint,
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncAlbum.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('$e')),
        data: (album) => _AlbumBody(album: album),
      ),
    );
  }
}

class _AlbumBody extends ConsumerWidget {
  const _AlbumBody({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(collectionProvider(album.id));
    final collapsed = ref.watch(collapsedSectionsProvider(album.id));
    final collapseN =
        ref.read(collapsedSectionsProvider(album.id).notifier);
    final filter = ref.watch(albumFilterProvider);
    final l = AppLocalizations.of(context);

    final groups = album.stickersByGroup;
    final specials = groups['FWC'] ?? const <Sticker>[];

    // Whether any sticker at all survives the active filter. When nothing
    // matches, every section collapses to nothing — so we show a single
    // album-level empty state instead of a blank screen.
    final anyVisible = album.stickers.any(
      (s) => filter.matches(
        isSpecial: s.isSpecial,
        ownedCount: counts[s.code] ?? 0,
      ),
    );

    final slivers = <Widget>[
      SliverToBoxAdapter(child: _ProgressCard(album: album, counts: counts)),
      const SliverToBoxAdapter(child: FilterChipRow()),
      if (!anyVisible)
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: l.albumFilterEmpty,
          ),
        )
      else ...[
        // FWC specials section.
        SliverToBoxAdapter(
          child: _SpecialsSection(
            albumId: album.id,
            stickers: specials,
            counts: counts,
            filter: filter,
            collapsed: collapsed.contains('specials'),
            onToggle: () => collapseN.toggle('specials'),
          ),
        ),

        // WC groups A → L.
        for (final wcg in album.wcGroups)
          SliverToBoxAdapter(
            child: _WcGroupBlock(
              albumId: album.id,
              wcGroup: wcg,
              stickersByTeam: groups,
              counts: counts,
              filter: filter,
              collapsed: collapsed.contains('wc:${wcg.letter}'),
              onToggle: () => collapseN.toggle('wc:${wcg.letter}'),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    ];

    return CustomScrollView(slivers: slivers);
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.album, required this.counts});

  final Album album;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final owned = counts.values.where((c) => c >= 1).length;
    final duplicates =
        counts.values.fold<int>(0, (sum, c) => sum + (c > 1 ? c - 1 : 0));
    final pct = album.totalStickers == 0
        ? '0.0'
        : (owned * 100 / album.totalStickers).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.stickersOwnedOfTotal(owned, album.totalStickers),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              l.stickersOwnedPercent(pct),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: album.totalStickers == 0
                    ? 0
                    : owned / album.totalStickers,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.copy_all_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text('${l.statusDuplicate}: $duplicates'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialsSection extends StatelessWidget {
  const _SpecialsSection({
    required this.albumId,
    required this.stickers,
    required this.counts,
    required this.filter,
    required this.collapsed,
    required this.onToggle,
  });

  final String albumId;
  final List<Sticker> stickers;
  final Map<String, int> counts;
  final AlbumFilter filter;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final visible = stickers
        .where((s) => filter.matches(
              isSpecial: s.isSpecial,
              ownedCount: counts[s.code] ?? 0,
            ))
        .toList();

    // Hide the whole section if filter eliminates all stickers.
    if (visible.isEmpty) return const SizedBox.shrink();

    final owned = stickers.where((s) => (counts[s.code] ?? 0) >= 1).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CollapsibleHeader(
          title: l.sectionSpecials,
          progressOwned: owned,
          progressTotal: stickers.length,
          collapsed: collapsed,
          onTap: onToggle,
          emphasised: true,
        ),
        if (!collapsed)
          GroupSection(
            albumId: albumId,
            groupCode: 'FWC',
            groupNameSrLatn: '',
            groupNameEn: '',
            stickers: stickers,
          ),
      ],
    );
  }
}

class _WcGroupBlock extends StatelessWidget {
  const _WcGroupBlock({
    required this.albumId,
    required this.wcGroup,
    required this.stickersByTeam,
    required this.counts,
    required this.filter,
    required this.collapsed,
    required this.onToggle,
  });

  final String albumId;
  final WcGroup wcGroup;
  final Map<String, List<Sticker>> stickersByTeam;
  final Map<String, int> counts;
  final AlbumFilter filter;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    int totalVisible = 0, owned = 0, total = 0;
    final teamSections = <Widget>[];

    for (final teamCode in wcGroup.teamCodes) {
      final teamStickers = stickersByTeam[teamCode] ?? const <Sticker>[];
      total += teamStickers.length;
      owned += teamStickers.where((s) => (counts[s.code] ?? 0) >= 1).length;
      totalVisible += teamStickers
          .where((s) => filter.matches(
                isSpecial: s.isSpecial,
                ownedCount: counts[s.code] ?? 0,
              ))
          .length;
      if (teamStickers.isNotEmpty) {
        final first = teamStickers.first;
        teamSections.add(GroupSection(
          albumId: albumId,
          groupCode: teamCode,
          groupNameSrLatn: first.groupNameSrLatn,
          groupNameEn: first.groupNameEn,
          stickers: teamStickers,
        ));
      }
    }

    // If the filter leaves zero stickers across the whole WC group, hide the
    // header too.
    if (totalVisible == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CollapsibleHeader(
          title: l.wcGroupHeader(wcGroup.letter),
          progressOwned: owned,
          progressTotal: total,
          collapsed: collapsed,
          onTap: onToggle,
          emphasised: true,
        ),
        if (!collapsed) ...teamSections,
      ],
    );
  }
}
