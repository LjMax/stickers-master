import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/album.dart';
import '../models/sticker.dart';
import '../providers/collection_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/team_flag.dart';
import 'sticker_edit_sheet.dart';

/// Full-screen search for stickers by their code. Type "ENG" to see all
/// ENG1..ENG20; type "ENG12" to jump to a specific sticker. Tap a result
/// to open the editor sheet.
class StickerSearchDelegate extends SearchDelegate<void> {
  StickerSearchDelegate({
    required this.album,
    required this.hintText,
  }) : super(searchFieldLabel: hintText);

  final Album album;
  final String hintText;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) =>
      _SearchResults(album: album, query: query.trim().toUpperCase());

  @override
  Widget buildSuggestions(BuildContext context) =>
      _SearchResults(album: album, query: query.trim().toUpperCase());
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.album, required this.query});

  final Album album;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    if (query.isEmpty) return const SizedBox.shrink();

    final results =
        album.stickers.where((s) => s.code.toUpperCase().contains(query)).toList();

    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: l.searchNoResults,
      );
    }

    final counts = ref.watch(collectionProvider(album.id));
    final locale = ref.watch(localeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            l.searchResultCount(results.length),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, i) {
              final s = results[i];
              return _ResultTile(
                sticker: s,
                albumId: album.id,
                count: counts[s.code] ?? 0,
                locale: locale,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.sticker,
    required this.albumId,
    required this.count,
    required this.locale,
  });

  final Sticker sticker;
  final String albumId;
  final int count;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final groupLabel =
        pickLocalized(locale, sticker.groupNameSrLatn, sticker.groupNameEn);
    final subcat = pickLocalized(
      locale,
      sticker.subcategorySrLatn,
      sticker.subcategoryEn,
    );
    final wcSuffix =
        sticker.wcGroup != null ? ' · Grupa ${sticker.wcGroup}' : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: sticker.isSpecial
            ? AppColors.foilGold
            : Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: sticker.isSpecial
            ? Colors.white
            : Theme.of(context).colorScheme.onPrimaryContainer,
        child: Text(
          sticker.code,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
      title: Row(
        children: [
          // Flag for the team this sticker belongs to. For non-team
          // stickers (specials / cover) the widget renders a neutral
          // pill, which still aligns with the title baseline.
          TeamFlag(teamCode: sticker.groupCode, width: 22, height: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              groupLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text('$subcat$wcSuffix'),
      trailing: count == 0
          ? Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      onTap: () => showStickerEditSheet(
        context,
        albumId: albumId,
        sticker: sticker,
      ),
    );
  }
}
