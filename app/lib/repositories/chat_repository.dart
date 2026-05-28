import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_models.dart';

/// How long after a request is declined the sender must wait before they
/// may send another request to the same person.
const Duration kRequestCooldown = Duration(hours: 24);

/// Outcome of [ChatRepository.checkCanSendRequest].
enum SendRequestCheck {
  /// The sender may send a request.
  ok,

  /// There is already a pending request from the sender to this person.
  alreadyPending,

  /// The person declined a recent request; the cooldown is still active.
  cooldown,
}

/// Result of a pre-send check, carrying the remaining cooldown when
/// [check] is [SendRequestCheck.cooldown].
class SendRequestResult {
  const SendRequestResult(this.check, {this.cooldownRemaining});

  final SendRequestCheck check;
  final Duration? cooldownRemaining;
}

/// All Firestore reads/writes for chat requests, chats, and messages.
class ChatRepository {
  ChatRepository(this._db);

  final FirebaseFirestore _db;

  // ---- Chat requests -------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('chat_requests');

  /// Stream incoming requests for [uid] (pending only — accepted/declined
  /// disappear from the inbox once the user has acted on them).
  ///
  /// Note: we sort client-side after parsing rather than using `orderBy`
  /// in the Firestore query, because the combination of two equality
  /// filters + a descending order would require a composite index. With
  /// the expected handful of pending requests per user, client-side
  /// sorting is trivial and avoids a deploy-the-index dance.
  Stream<List<ChatRequest>> watchIncomingPending(String uid) {
    return _requests
        .where('to_user', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((q) {
      final list = q.docs.map(ChatRequest.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Send a chat request to [toUser]. Returns the new request's id.
  Future<String> sendRequest({
    required String fromUid,
    required String fromDisplayName,
    String? fromPhotoUrl,
    required String toUid,
    required String albumId,
    required String introMessage,
  }) async {
    final ref = await _requests.add({
      'from_user': fromUid,
      'to_user': toUid,
      'from_display_name': fromDisplayName,
      if (fromPhotoUrl != null) 'from_photo_url': fromPhotoUrl,
      'album_id': albumId,
      'intro_message': introMessage,
      'created_at': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
    return ref.id;
  }

  /// Recipient accepts the request: marks accepted, creates the chat doc
  /// (with the requester's intro message embedded as fields on the doc),
  /// fills in the request's chat_id. Returns the chat id.
  ///
  /// **Why intro lives on the chat doc, not in /messages:** the Firestore
  /// rule for `chats/{chatId}/messages/create` requires
  /// `sender_id == request.auth.uid`. The recipient (who runs this batch)
  /// cannot legally write a message with `sender_id = req.fromUser`. So
  /// we denormalise the intro onto the chat doc itself
  /// (`intro_message` / `intro_sender` / `intro_at`) and the chat detail
  /// screen prepends a synthetic `ChatMessage` built from those fields.
  /// `last_message*` is also seeded so the chat surfaces at the top of
  /// both users' inboxes right after accept.
  Future<String> acceptRequest({
    required ChatRequest req,
    required ChatParticipant me,
  }) async {
    final chatId = chatIdFor(req.fromUser, req.toUser);
    final chatDoc = _db.doc('chats/$chatId');

    // Use a batch so the chat doc + request status update happen atomically.
    final batch = _db.batch();

    final intro = req.introMessage.trim();
    final hasIntro = intro.isNotEmpty;

    batch.set(chatDoc, {
      'participants': [req.fromUser, req.toUser]..sort(),
      'participant_names': {
        req.fromUser: req.fromDisplayName,
        req.toUser: me.displayName,
      },
      'participant_photos': {
        req.fromUser: req.fromPhotoUrl,
        req.toUser: me.photoUrl,
      },
      'album_id': req.albumId,
      'created_at': FieldValue.serverTimestamp(),
      if (hasIntro) ...{
        'intro_message': intro,
        'intro_sender': req.fromUser,
        'intro_at': FieldValue.serverTimestamp(),
        // Seed last_message* so the chat appears at the top of the
        // inbox with the intro as preview, until someone replies.
        'last_message': intro,
        'last_message_at': FieldValue.serverTimestamp(),
        'last_message_sender': req.fromUser,
      },
    });

    batch.update(_requests.doc(req.id), {
      'status': 'accepted',
      'chat_id': chatId,
    });

    await batch.commit();
    return chatId;
  }

  Future<void> declineRequest(String requestId) async {
    await _requests.doc(requestId).update({
      'status': 'declined',
      // Stamp the decline time so the re-request cooldown runs from when
      // the request was declined, not when it was originally sent.
      'declined_at': FieldValue.serverTimestamp(),
    });
  }

  /// Check whether [fromUid] may send a chat request to [toUid].
  ///
  /// Returns [SendRequestCheck.alreadyPending] if a request is still
  /// awaiting a response, [SendRequestCheck.cooldown] (with the remaining
  /// time) if the person declined a request within [kRequestCooldown],
  /// otherwise [SendRequestCheck.ok].
  ///
  /// Uses two equality filters only — no composite index required.
  Future<SendRequestResult> checkCanSendRequest(
      String fromUid, String toUid) async {
    final q = await _requests
        .where('from_user', isEqualTo: fromUid)
        .where('to_user', isEqualTo: toUid)
        .get();

    DateTime? latestDeclineAt;
    for (final doc in q.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? 'pending';
      if (status == 'pending') {
        return const SendRequestResult(SendRequestCheck.alreadyPending);
      }
      if (status == 'declined') {
        final declinedAt = (data['declined_at'] as Timestamp?)?.toDate() ??
            (data['created_at'] as Timestamp?)?.toDate();
        if (declinedAt != null &&
            (latestDeclineAt == null || declinedAt.isAfter(latestDeclineAt))) {
          latestDeclineAt = declinedAt;
        }
      }
    }

    if (latestDeclineAt != null) {
      final elapsed = DateTime.now().difference(latestDeclineAt);
      if (elapsed < kRequestCooldown) {
        return SendRequestResult(
          SendRequestCheck.cooldown,
          cooldownRemaining: kRequestCooldown - elapsed,
        );
      }
    }
    return const SendRequestResult(SendRequestCheck.ok);
  }

  // ---- Chats ---------------------------------------------------------------

  /// Stream chats for [uid]. Sorted client-side by `last_message_at`
  /// descending — see [watchIncomingPending] for why we avoid the
  /// composite Firestore index that `arrayContains + orderBy` would need.
  Stream<List<Chat>> watchMyChats(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((q) {
      final list = q.docs.map(Chat.fromDoc).toList();
      list.sort((a, b) {
        final aT = a.lastMessageAt ?? a.createdAt;
        final bT = b.lastMessageAt ?? b.createdAt;
        return bT.compareTo(aT);
      });
      return list;
    });
  }

  Future<Chat?> getChat(String chatId) async {
    final snap = await _db.doc('chats/$chatId').get();
    if (!snap.exists) return null;
    return Chat.fromMap(snap.id, snap.data() ?? const {});
  }

  /// Hide [chatId] from [uid]'s inbox ("delete for me"). The chat and its
  /// messages are kept; the chat reappears for [uid] if a new message is
  /// sent (see [sendMessage], which clears `hidden_for`).
  Future<void> hideChatForMe(String chatId, String uid) async {
    await _db.doc('chats/$chatId').update({
      'hidden_for': FieldValue.arrayUnion([uid]),
    });
  }

  /// Mark [chatId] as read by [uid] right now. Stamps `last_read.{uid}` so
  /// the unread indicator (see [Chat.hasUnreadFor]) clears for this user.
  /// Safe to call on every chat open — it's a single field write.
  Future<void> markChatRead(String chatId, String uid) async {
    try {
      await _db.doc('chats/$chatId').update({
        'last_read.$uid': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Non-fatal: a failed read-stamp just leaves the badge up briefly.
      // Don't surface this to the user.
    }
  }

  // ---- Messages ------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _messagesRef(String chatId) =>
      _db.collection('chats/$chatId/messages');

  Stream<List<ChatMessage>> watchMessages(String chatId, {int limit = 200}) {
    return _messagesRef(chatId)
        .orderBy('created_at', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map((q) => q.docs.map(ChatMessage.fromDoc).toList());
  }

  /// Append a new message and bump the parent chat's last_message fields.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final batch = _db.batch();
    final msg = _messagesRef(chatId).doc();
    batch.set(msg, {
      'sender_id': senderId,
      'text': trimmed,
      'created_at': FieldValue.serverTimestamp(),
    });
    batch.update(_db.doc('chats/$chatId'), {
      'last_message': trimmed,
      'last_message_at': FieldValue.serverTimestamp(),
      'last_message_sender': senderId,
      // A new message resurrects the chat for anyone who hid it.
      'hidden_for': <String>[],
    });
    await batch.commit();
  }
}
