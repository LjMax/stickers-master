import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/moderation_repository.dart';
import 'auth_provider.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(FirebaseFirestore.instance);
});

/// uids the signed-in user has blocked. Used to hide their chats and to
/// keep them out of swap results.
final iBlockedProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream.value(const <String>{});
  return ref.read(moderationRepositoryProvider).watchBlockedByMe(uid);
});

/// uids that have blocked the signed-in user. Used so we don't surface
/// people in the swap area who would reject a chat request anyway.
final blockedMeProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream.value(const <String>{});
  return ref.read(moderationRepositoryProvider).watchWhoBlockedMe(uid);
});

/// Union of both directions — anyone the signed-in user should not be
/// matched with in the swap area.
final blockedUidsProvider = Provider<Set<String>>((ref) {
  final mine = ref.watch(iBlockedProvider).valueOrNull ?? const <String>{};
  final theirs = ref.watch(blockedMeProvider).valueOrNull ?? const <String>{};
  return {...mine, ...theirs};
});

/// Full block entries (with name/photo) for the "Blocked users" screen.
final myBlockEntriesProvider = StreamProvider<List<BlockEntry>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream.value(const <BlockEntry>[]);
  return ref.read(moderationRepositoryProvider).watchMyBlockEntries(uid);
});
