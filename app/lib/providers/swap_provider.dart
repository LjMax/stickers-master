import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/album.dart';
import '../models/public_profile.dart';
import 'album_provider.dart';
import 'auth_provider.dart';
import 'collection_provider.dart';
import 'moderation_provider.dart';
import 'profile_provider.dart';

/// Result of [swapMatchesProvider] — either matches or a hint about why
/// there aren't any.
class SwapMatchesResult {
  const SwapMatchesResult({
    required this.matches,
    required this.reason,
  });

  final List<SwapMatch> matches;
  final SwapMatchesReason reason;
}

enum SwapMatchesReason {
  ok,
  notSignedIn,
  noCitySet,
  noMissing,
  noMatches,
}

/// Computes and uploads my duplicates, then queries for partners with
/// overlap in my city. Refreshed every time the user opens the Swap tab.
///
/// Use `autoDispose` so the query re-runs when the screen is reopened (gives
/// the user a fresh list of matches each visit) and stale data is dropped.
final swapMatchesProvider =
    FutureProvider.autoDispose.family<SwapMatchesResult, String>((ref, albumId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const SwapMatchesResult(matches: [], reason: SwapMatchesReason.notSignedIn);
  }

  final profile = await ref.watch(myProfileProvider.future);
  if (profile == null || profile.city.trim().isEmpty) {
    return const SwapMatchesResult(matches: [], reason: SwapMatchesReason.noCitySet);
  }

  final counts = ref.watch(collectionProvider(albumId));
  final album = await ref.watch(albumProvider.future);

  // My missing = album sticker codes I don't yet have.
  final myMissing = <String>{
    for (final s in album.stickers)
      if ((counts[s.code] ?? 0) == 0) s.code,
  };
  if (myMissing.isEmpty) {
    return const SwapMatchesResult(matches: [], reason: SwapMatchesReason.noMissing);
  }

  // My duplicates — push fresh state to Firestore so other people see it.
  final myDuplicates = <String>[
    for (final entry in counts.entries)
      if (entry.value >= 2) entry.key,
  ];

  final repo = ref.read(swapRepositoryProvider);
  await repo.updateMyDuplicates(
    uid: user.uid,
    albumId: albumId,
    duplicates: myDuplicates,
  );

  final found = await repo.findMatches(
    myUid: user.uid,
    city: profile.city,
    albumId: albumId,
    myMissing: myMissing,
  );

  // Drop anyone involved in a block (either direction) so blocked users
  // never surface in the swap area.
  final blocked = ref.watch(blockedUidsProvider);
  final matches = blocked.isEmpty
      ? found
      : found.where((m) => !blocked.contains(m.profile.uid)).toList();

  return SwapMatchesResult(
    matches: matches,
    reason: matches.isEmpty
        ? SwapMatchesReason.noMatches
        : SwapMatchesReason.ok,
  );
});

/// Album to use for swap. v1 has just one album (Panini FIFA WC 2026);
/// when we add multiple albums this becomes user-selectable.
final swapAlbumIdProvider = Provider<String>((ref) {
  // Could also derive from albumProvider once available.
  // ignore: unused_local_variable
  final _ = ref;
  return 'panini-fifa-world-cup-2026';
});

/// Convenience: result for the currently-selected swap album.
final currentSwapMatchesProvider =
    FutureProvider.autoDispose<SwapMatchesResult>((ref) async {
  final albumId = ref.watch(swapAlbumIdProvider);
  return ref.watch(swapMatchesProvider(albumId).future);
});

// Re-export so screens don't need to import the Album type from the model
// file just to access `album.stickers` size.
// ignore: unused_element
typedef _AlbumAlias = Album;
