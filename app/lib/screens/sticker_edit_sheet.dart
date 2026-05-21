import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sticker.dart';
import '../providers/collection_provider.dart';
import '../providers/locale_provider.dart';

/// Modal bottom sheet for setting an exact owned_count for a sticker
/// (including 0 to mark as missing again).
Future<void> showStickerEditSheet(
  BuildContext context, {
  required String albumId,
  required Sticker sticker,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _StickerEditSheet(albumId: albumId, sticker: sticker),
  );
}

class _StickerEditSheet extends ConsumerWidget {
  const _StickerEditSheet({required this.albumId, required this.sticker});

  final String albumId;
  final Sticker sticker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final counts = ref.watch(collectionProvider(albumId));
    final notifier = ref.read(collectionProvider(albumId).notifier);
    final count = counts[sticker.code] ?? 0;

    final groupLabel = pickLocalized(
      locale,
      sticker.groupNameSrLatn,
      sticker.groupNameEn,
    );
    final subcategoryLabel = pickLocalized(
      locale,
      sticker.subcategorySrLatn,
      sticker.subcategoryEn,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.stickerEditTitle(sticker.code),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '$groupLabel  ·  $subcategoryLabel${sticker.isSpecial ? '  ·  ${l.statusFoil}' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            Text(
              l.stickerEditOwnedCount,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed:
                      count > 0 ? () => notifier.decrement(sticker.code) : null,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      count.toString(),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => notifier.increment(sticker.code),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _statusLabel(l, count),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed:
                      count > 0 ? () => notifier.setCount(sticker.code, 0) : null,
                  child: Text(l.actionReset),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.actionDone),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l, int count) {
    if (count == 0) return l.stickerEditNone;
    if (count == 1) return l.stickerEditHaveOne;
    return l.stickerEditDuplicates(count - 1);
  }
}
