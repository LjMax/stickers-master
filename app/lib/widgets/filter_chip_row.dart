import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/filter_provider.dart';

/// Horizontal scrollable row of filter chips. Selecting one updates the
/// album-wide filter; selecting the same chip again clears it back to All.
class FilterChipRow extends ConsumerWidget {
  const FilterChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final selected = ref.watch(albumFilterProvider);

    final chips = <(AlbumFilter, String)>[
      (AlbumFilter.all, l.filterAll),
      (AlbumFilter.missing, l.filterMissing),
      (AlbumFilter.have, l.filterHave),
      (AlbumFilter.duplicates, l.filterDuplicates),
      (AlbumFilter.foils, l.filterFoils),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (filter, label) = chips[i];
          return ChoiceChip(
            label: Text(label),
            selected: selected == filter,
            onSelected: (_) {
              // Tapping the active chip clears back to "all".
              ref.read(albumFilterProvider.notifier).state =
                  (selected == filter) ? AlbumFilter.all : filter;
            },
          );
        },
      ),
    );
  }
}
