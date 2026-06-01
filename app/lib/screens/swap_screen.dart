import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/public_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/moderation_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/swap_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/moderation_dialogs.dart';
import '../widgets/user_avatar.dart';
import 'chat/send_request_dialog.dart';
import 'profile_edit_screen.dart';
import 'sign_in_screen.dart';

/// Swap area: lists collectors in the same country who hold duplicates of
/// stickers I'm missing. An optional "Only {city}" filter chip narrows the
/// list to my own city.
class SwapScreen extends ConsumerWidget {
  const SwapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final asyncResult = ref.watch(currentSwapMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.swapTitle),
        actions: [
          IconButton(
            tooltip: l.swapRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(currentSwapMatchesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          const _FilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(currentSwapMatchesProvider),
              child: asyncResult.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                // Hide raw Firestore errors from the user (they sometimes
                // embed project IDs and aren't actionable). Log to console,
                // render the friendly "no matches" empty state.
                error: (e, st) {
                  debugPrint('swap: matches error: $e');
                  return const _EmptyState(reason: SwapMatchesReason.noMatches);
                },
                data: (result) {
                  if (result.matches.isEmpty) {
                    return _EmptyState(reason: result.reason);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: result.matches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, i) =>
                        _MatchCard(match: result.matches[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Row under the AppBar:
///   - Country label (informational — e.g. "Srbija")
///   - FilterChip "Only {city}" that, when selected, narrows the matches
///     to the user's own city.
///
/// Hidden when the user has no profile yet (the empty state below will
/// prompt them to set one up).
class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(myProfileProvider).valueOrNull;
    final narrow = ref.watch(swapNarrowByCityProvider);

    final country = profile?.country.trim() ?? '';
    final city = profile?.city.trim() ?? '';

    // No profile yet — empty state below handles the prompt.
    if (country.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
      child: Row(
        children: [
          Icon(
            Icons.public_outlined,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              country,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          const Spacer(),
          if (city.isNotEmpty)
            FilterChip(
              selected: narrow,
              avatar: Icon(
                Icons.location_city_outlined,
                size: 18,
                color: narrow
                    ? scheme.onSecondaryContainer
                    : scheme.onSurfaceVariant,
              ),
              label: Text(l.swapFilterCityOnly(city)),
              onSelected: (v) =>
                  ref.read(swapNarrowByCityProvider.notifier).state = v,
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.reason});
  final SwapMatchesReason reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    var icon = Icons.swap_horiz;
    var message = '';
    Widget? action;

    switch (reason) {
      case SwapMatchesReason.notSignedIn:
        icon = Icons.lock_outline;
        message = l.swapEmptyNotSignedIn;
        action = FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
          ),
          icon: const Icon(Icons.login),
          label: Text(l.signInTitle),
        );
        break;
      case SwapMatchesReason.noCountrySet:
        icon = Icons.public_off_outlined;
        message = l.swapEmptyNoCountry;
        action = FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ProfileEditScreen()),
          ),
          icon: const Icon(Icons.badge_outlined),
          label: Text(l.swapOpenProfile),
        );
        break;
      case SwapMatchesReason.noCityForFilter:
        icon = Icons.location_off_outlined;
        message = l.swapEmptyNoCity;
        action = FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ProfileEditScreen()),
          ),
          icon: const Icon(Icons.badge_outlined),
          label: Text(l.swapOpenProfile),
        );
        break;
      case SwapMatchesReason.noMissing:
        icon = Icons.check_circle_outline;
        message = l.swapEmptyNoMissing;
        break;
      case SwapMatchesReason.noMatches:
        icon = Icons.swap_horiz;
        final profile = ref.watch(myProfileProvider).valueOrNull;
        final narrow = ref.watch(swapNarrowByCityProvider);
        message = narrow
            ? l.swapEmptyNoMatches(profile?.city ?? '')
            : l.swapEmptyNoMatchesCountry(profile?.country ?? '');
        break;
      case SwapMatchesReason.ok:
        break;
    }

    return ListView(
      // ListView so pull-to-refresh works even in the empty state.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 48),
        EmptyState(icon: icon, title: message, action: action),
      ],
    );
  }
}

class _MatchCard extends ConsumerWidget {
  const _MatchCard({required this.match});
  final SwapMatch match;

  String _label(AppLocalizations l) => match.profile.displayName.isNotEmpty
      ? match.profile.displayName
      : l.swapAnonymous;

  void _onModerationMenu(BuildContext context, WidgetRef ref, String action) {
    final l = AppLocalizations.of(context);
    final label = _label(l);
    if (action == 'report') {
      showReportDialog(
        context,
        reportedUid: match.profile.uid,
        reportedName: label,
      );
      return;
    }
    if (action == 'block') {
      _blockUser(context, ref, label);
    }
  }

  Future<void> _blockUser(
      BuildContext context, WidgetRef ref, String label) async {
    final confirmed = await showBlockConfirmDialog(context, label);
    if (!confirmed || !context.mounted) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final myUid = ref.read(currentUserProvider)?.uid;
    if (myUid == null) return;
    try {
      await ref.read(moderationRepositoryProvider).blockUser(
            blockerUid: myUid,
            blockedUid: match.profile.uid,
            blockedName: label,
            blockedPhotoUrl: match.profile.photoUrl,
          );
      // The swap list re-runs once the block lands and drops this card.
      messenger.showSnackBar(
        SnackBar(content: Text(l.modBlockedSnack(label))),
      );
    } catch (e) {
      debugPrint('swap: block failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(l.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profile = match.profile;
    final scheme = Theme.of(context).colorScheme;

    // Show the first ~6 overlap codes, then "+N more".
    final preview = match.overlapCodes.take(6).join(', ');
    final remaining = match.overlapCodes.length - 6;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  name: profile.displayName.isNotEmpty
                      ? profile.displayName
                      : l.swapAnonymous,
                  photoUrl: profile.photoUrl,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName.isNotEmpty
                            ? profile.displayName
                            : l.swapAnonymous,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        profile.city,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${match.overlapCount}',
                    style: TextStyle(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: '',
                  onSelected: (v) => _onModerationMenu(context, ref, v),
                  itemBuilder: (ctx) => [
                    PopupMenuItem<String>(
                      value: 'block',
                      child: ModerationMenuRow(
                        icon: Icons.block,
                        label: l.modBlockUser,
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'report',
                      child: ModerationMenuRow(
                        icon: Icons.flag_outlined,
                        label: l.modReportUser,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l.swapMatchCount(match.overlapCount),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              remaining > 0 ? '$preview, +$remaining' : preview,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => showSendRequestSheet(
                    context,
                    toProfile: profile,
                    albumId: 'panini-fifa-world-cup-2026',
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: Text(l.swapChat),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
