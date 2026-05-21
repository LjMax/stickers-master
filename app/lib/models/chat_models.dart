import 'package:cloud_firestore/cloud_firestore.dart';

/// One participant's cached display info, denormalised into chat docs so
/// the chat list can render without N additional reads.
class ChatParticipant {
  const ChatParticipant({
    required this.uid,
    required this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'display_name': displayName,
        if (photoUrl != null) 'photo_url': photoUrl,
      };

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      uid: json['uid'] as String,
      displayName: json['display_name'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
    );
  }
}

/// A pending / accepted / declined request to start a chat.
class ChatRequest {
  const ChatRequest({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.fromDisplayName,
    this.fromPhotoUrl,
    required this.albumId,
    required this.introMessage,
    required this.createdAt,
    required this.status,
    this.chatId,
  });

  final String id;
  final String fromUser;
  final String toUser;
  final String fromDisplayName;
  final String? fromPhotoUrl;
  final String albumId;
  final String introMessage;
  final DateTime createdAt;
  final ChatRequestStatus status;

  /// Filled when the request is accepted — used to navigate the recipient
  /// to the newly-created chat.
  final String? chatId;

  factory ChatRequest.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return ChatRequest.fromMap(doc.id, doc.data());
  }

  factory ChatRequest.fromMap(String id, Map<String, dynamic> data) {
    return ChatRequest(
      id: id,
      fromUser: data['from_user'] as String,
      toUser: data['to_user'] as String,
      fromDisplayName: data['from_display_name'] as String? ?? '',
      fromPhotoUrl: data['from_photo_url'] as String?,
      albumId: data['album_id'] as String? ?? '',
      introMessage: data['intro_message'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ChatRequestStatus.fromString(data['status'] as String? ?? 'pending'),
      chatId: data['chat_id'] as String?,
    );
  }
}

enum ChatRequestStatus {
  pending,
  accepted,
  declined,
  cancelled;

  static ChatRequestStatus fromString(String v) {
    switch (v) {
      case 'accepted':
        return ChatRequestStatus.accepted;
      case 'declined':
        return ChatRequestStatus.declined;
      case 'cancelled':
        return ChatRequestStatus.cancelled;
      default:
        return ChatRequestStatus.pending;
    }
  }

  String get wireValue => name;
}

/// A 1:1 chat between two users. Created on Accept.
class Chat {
  const Chat({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    required this.albumId,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSender,
    this.lastRead = const {},
    this.hiddenFor = const {},
  });

  final String id;

  /// Sorted [uidA, uidB].
  final List<String> participants;

  /// Map uid → display name. Used for chat-list rendering without extra reads.
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;

  final String albumId;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSender;

  /// Map uid → the time that user last opened/read this chat. Used to
  /// derive the unread indicator without storing a per-message read flag.
  final Map<String, DateTime> lastRead;

  /// uids that have deleted (hidden) this chat from their own inbox. The
  /// chat and its messages are kept; sending a new message clears this
  /// set so the chat reappears for everyone.
  final Set<String> hiddenFor;

  /// True when [uid] has hidden this chat from their inbox.
  bool isHiddenFor(String uid) => hiddenFor.contains(uid);

  /// The other participant (relative to [myUid]).
  String otherUid(String myUid) =>
      participants.firstWhere((u) => u != myUid, orElse: () => myUid);

  String otherName(String myUid) =>
      participantNames[otherUid(myUid)] ?? '';

  String? otherPhoto(String myUid) =>
      participantPhotos[otherUid(myUid)];

  /// True when there is a last message that [myUid] did not send and has
  /// not yet read (no `last_read` entry, or it predates the last message).
  bool hasUnreadFor(String myUid) {
    final at = lastMessageAt;
    if (at == null) return false;
    if (lastMessageSender == null || lastMessageSender == myUid) return false;
    final read = lastRead[myUid];
    if (read == null) return true;
    return at.isAfter(read);
  }

  factory Chat.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return Chat.fromMap(doc.id, doc.data());
  }

  factory Chat.fromMap(String id, Map<String, dynamic> data) {
    final names = <String, String>{};
    final photos = <String, String?>{};
    final rawNames = data['participant_names'];
    if (rawNames is Map) {
      rawNames.forEach((k, v) {
        if (k is String && v is String) names[k] = v;
      });
    }
    final rawPhotos = data['participant_photos'];
    if (rawPhotos is Map) {
      rawPhotos.forEach((k, v) {
        if (k is String) photos[k] = v as String?;
      });
    }
    final participants = <String>[];
    final rawParticipants = data['participants'];
    if (rawParticipants is List) {
      for (final p in rawParticipants) {
        if (p is String) participants.add(p);
      }
    }
    final lastRead = <String, DateTime>{};
    final rawLastRead = data['last_read'];
    if (rawLastRead is Map) {
      rawLastRead.forEach((k, v) {
        if (k is String && v is Timestamp) lastRead[k] = v.toDate();
      });
    }
    final hiddenFor = <String>{};
    final rawHidden = data['hidden_for'];
    if (rawHidden is List) {
      for (final h in rawHidden) {
        if (h is String) hiddenFor.add(h);
      }
    }
    return Chat(
      id: id,
      participants: participants,
      participantNames: names,
      participantPhotos: photos,
      albumId: data['album_id'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['last_message'] as String?,
      lastMessageAt: (data['last_message_at'] as Timestamp?)?.toDate(),
      lastMessageSender: data['last_message_sender'] as String?,
      lastRead: lastRead,
      hiddenFor: hiddenFor,
    );
  }
}

/// A single message in a chat. Immutable after creation.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  factory ChatMessage.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return ChatMessage(
      id: doc.id,
      senderId: data['sender_id'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Deterministic chat ID from two uids. Used so both clients agree on the
/// same document path without needing a server query.
String chatIdFor(String uidA, String uidB) {
  final sorted = [uidA, uidB]..sort();
  return '${sorted[0]}_${sorted[1]}';
}
