import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_models.dart';
import '../repositories/chat_repository.dart';
import 'auth_provider.dart';
import 'moderation_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance);
});

/// Pending incoming chat requests for the signed-in user.
final incomingRequestsProvider = StreamProvider<List<ChatRequest>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream.value(const []);
  return ref.read(chatRepositoryProvider).watchIncomingPending(uid);
});

/// Outgoing chat requests the signed-in user has sent that haven't
/// resolved into a chat yet — i.e. still pending, or declined and not
/// yet dismissed by the sender. Powers the "Sent" section of the inbox.
final outgoingRequestsProvider = StreamProvider<List<ChatRequest>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream.value(const []);
  return ref.read(chatRepositoryProvider).watchOutgoing(uid);
});

/// Active chats the signed-in user is part of.
final myChatsProvider = StreamProvider<List<Chat>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream.value(const []);
  return ref.read(chatRepositoryProvider).watchMyChats(uid);
});

/// Messages for a specific chat (live stream).
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  return ref.read(chatRepositoryProvider).watchMessages(chatId);
});

/// Badge count for the Inbox tab: pending requests + chats that have
/// messages the signed-in user hasn't read yet. Blocked users are
/// excluded so a blocked person can't keep the badge lit.
final inboxBadgeCountProvider = Provider<int>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  final iBlocked = ref.watch(iBlockedProvider).valueOrNull ?? const <String>{};
  final blockedAny = ref.watch(blockedUidsProvider);

  final pending = ref.watch(incomingRequestsProvider).valueOrNull ?? const [];
  final visiblePending =
      pending.where((r) => !blockedAny.contains(r.fromUser)).length;

  final chats = ref.watch(myChatsProvider).valueOrNull ?? const [];
  final unreadChats = uid == null
      ? 0
      : chats
          .where((c) => !iBlocked.contains(c.otherUid(uid)))
          .where((c) => !c.isHiddenFor(uid))
          .where((c) => c.hasUnreadFor(uid))
          .length;
  return visiblePending + unreadChats;
});
