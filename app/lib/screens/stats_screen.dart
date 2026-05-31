import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/album.dart';
import '../providers/album_provider.dart';
import '../providers/collection_provider.dart';
import '../providers/locale_provider.dart';
import '../repositories/share_list.dart';
import '../theme/app_theme.dart';
import 'missing_list_screen.dart';

/// Per-group breakdown of progress + share-list export.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final asyncAlbum = ref.watch(albumProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.tabStats)),
      body: asyncAlbum.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('$e')),
        data: (album) {
          final counts = ref.watch(collectionProvider(album.id));
          final groups = album.stickersByGroup;
          final groupCodes = groups.keys.toList();

          final totalOwned = counts.values.where((c) => c >= 1).length;
          final totalDuplicates =
              counts.values.fold<int>(0, (sum, c) => sum + (c > 1 ? c - 1 : 0));

          return ListView.builder(
            itemCount: groupCodes.length + 3,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _OverallCard(
                  owned: totalOwned,
                  total: album.totalStickers,
                  duplicates: totalDuplicates,
                );
              }
              if (index == 1) {
                return const _MissingListButton();
              }
              if (index == 2) {
                return _ShareButton(
                  onPressed: () => _shareSwapList(
                    context: context,
                    album: album,
                    counts: counts,
                    locale: locale,
                    l10n: l,
                  ),
                );
              }
              final code = groupCodes[index - 3];
              final stickers = groups[code]!;
              final label = pickLocalized(
                locale,
                stickers.first.groupNameSrLatn,
                stickers.first.groupNameEn,
              );
              final ownedInGroup =
                  stickers.where((s) => (counts[s.code] ?? 0) >= 1).length;
              final wcGroup = stickers.first.wcGroup;

              return ListTile(
                leading: wcGroup != null
                    ? CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        foregroundColor: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                        child: Text(
                          wcGroup,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.foilGold,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.star, size: 14),
                      ),
                title: Text(label),
                trailing: Text('$ownedInGroup / ${stickers.length}'),
              );
            },
          );
        },
      ),
    );
  }

  /// Opens the system share sheet (WhatsApp, Viber, SMS, Gmail, Copy, ...)
  /// pre-filled with the generated swap list text. The "Copy" option remains
  /// available inside the share sheet, so we lose nothing.
  Future<void> _shareSwapList({
    required BuildContext context,
    required Album album,
    required Map<String, int> counts,
    required Locale locale,
    required AppLocalizations l10n,
  }) async {
    final text = ShareListBuilder(
      album: album,
      counts: counts,
      locale: locale,
      l10n: l10n,
    ).build();

    // share_plus handles platform differences (Android sheet, iOS UIActivityViewController).
    await Share.share(
      text,
      subject: l10n.shareTitle,
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({
    required this.owned,
    required this.total,
    required this.duplicates,
  });

  final int owned;
  final int total;
  final int duplicates;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pct = total == 0 ? '0.0' : (owned * 100 / total).toStringAsFixed(1);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.stickersOwnedOfTotal(owned, total),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l.stickersOwnedPercent(pct),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : owned / total,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.copy_all_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
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

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: const Icon(Icons.share_outlined),
          label: Text(l.shareOpenSheet),
        ),
      ),
    );
  }
}

/// "Show what I'm missing" CTA on the stats screen — sits right above
/// the share-list button. Same destination as the equivalent button
/// on the album tab; mirrored here so it's reachable wherever the
/// user is thinking about their collection.
class _MissingListButton extends StatelessWidget {
  const _MissingListButton();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MissingListScreen(),
            ),
          ),
          icon: const Icon(Icons.checklist_outlined),
          label: Text(l.missingListTitle),
        ),
      ),
    );
  }
}
