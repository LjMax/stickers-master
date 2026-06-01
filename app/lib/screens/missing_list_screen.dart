import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/album_provider.dart';
import '../providers/collection_provider.dart';
import '../services/missing_list_builder.dart';
import '../widgets/empty_state.dart';
import '../widgets/team_flag.dart';

/// Simplified read-only view of the user's missing stickers, grouped
/// by team. Designed for the "I'm 90% complete, here's what I still
/// need" use case — e.g. quick reference before a swap meet.
///
/// Layout per team:
///   [flag]  Team name                 (8 missing)
///           ENG2, ENG7, ENG13, ENG18, ENG22, …
///
/// Top-right Copy button copies the whole thing as plain text, in
/// the user's current language, so it can be pasted into any chat.
class MissingListScreen extends ConsumerWidget {
  const MissingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final asyncAlbum = ref.watch(albumProvider);
    final useSerbian = Localizations.localeOf(context).languageCode == 'sr';

    // Wrap the Scaffold in its own ScaffoldMessenger so the
    // "Added X · Undo" snackbar from _markFound is scoped to this
    // screen. Without this, ScaffoldMessenger.of(context) resolves
    // to the root one MaterialApp installed, and the snackbar
    // outlives the Navigator pop — it ends up lingering on the
    // album / stats / inbox tab after the user navigates away.
    return ScaffoldMessenger(
      // The Builder gives the body (including the Copy button) a context
      // *below* this ScaffoldMessenger, so both the Copy and the tap-to-mark
      // snackbars resolve to the scoped messenger and are torn down with the
      // route on pop — rather than the root one, where they'd linger on the
      // tab the user returns to.
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(l.missingListTitle),
          ),
          body: asyncAlbum.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (album) {
              final counts = ref.watch(collectionProvider(album.id));
              final groups = buildMissingGroups(album, counts);
              if (groups.isEmpty) {
                return EmptyState(
                  icon: Icons.emoji_events_outlined,
                  title: l.missingListCompleteTitle,
                  message: l.missingListCompleteBody,
                );
              }

              final totalMissing =
                  groups.fold<int>(0, (sum, g) => sum + g.missingCodes.length);

              return Column(
                children: [
                  // Summary + Copy button.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.missingListSummary(totalMissing),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            final text = formatMissingAsText(
                              groups,
                              useSerbian: useSerbian,
                            );
                            await Clipboard.setData(ClipboardData(text: text));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.missingListCopied)),
                            );
                          },
                          icon: const Icon(Icons.copy_outlined),
                          label: Text(l.missingListCopy),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final g = groups[i];
                        final teamName =
                            useSerbian ? g.teamNameSrLatn : g.teamNameEn;
                        return _GroupRow(
                          groupCode: g.groupCode,
                          teamName: teamName.isEmpty ? g.groupCode : teamName,
                          codes: g.missingCodes,
                          // Tapping a code marks it as owned; the list
                          // recomputes via collectionProvider's stream and
                          // the chip disappears on the next frame.
                          onCodeTap: (code) => _markFound(
                            context: context,
                            ref: ref,
                            albumId: album.id,
                            code: code,
                            l: l,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Tap-to-mark handler: increment the sticker's owned count, then show
/// a snackbar with Undo. The collection notifier's stream notifies
/// [collectionProvider]'s subscribers; the missing-list rebuilds and
/// the just-tapped chip disappears from the screen.
///
/// Undo restores the user's previous count (which is 0 in the normal
/// case, but the helper is defensive: if the user tapped a code that
/// was somehow already partially-owned, we don't reset to 0 — we put
/// it back to whatever it was before this tap).
void _markFound({
  required BuildContext context,
  required WidgetRef ref,
  required String albumId,
  required String code,
  required AppLocalizations l,
}) {
  final notifier = ref.read(collectionProvider(albumId).notifier);
  final prev = notifier.countFor(code);
  notifier.increment(code);
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l.missingListMarkedFound(code)),
        action: SnackBarAction(
          label: l.actionUndo,
          onPressed: () => notifier.setCount(code, prev),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.groupCode,
    required this.teamName,
    required this.codes,
    required this.onCodeTap,
  });

  final String groupCode;
  final String teamName;
  final List<String> codes;
  final ValueChanged<String> onCodeTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TeamFlag(teamCode: groupCode),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        teamName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${codes.length}',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Each code is a small tappable chip. Tap = "I found
                // it!", and the chip disappears as the list rebuilds.
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final code in codes)
                      _CodeChip(
                        code: code,
                        onTap: () => onCodeTap(code),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact tappable pill rendering a single sticker code.
///
/// Sized to roughly fit a 3-letter team prefix + 1–3 digit number
/// (`ENG13`, `FWC68`) without truncation. Uses InkWell for the ripple
/// feedback users expect from a tap target.
class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code, required this.onTap});

  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            code,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: scheme.onSurface,
                ),
          ),
        ),
      ),
    );
  }
}
