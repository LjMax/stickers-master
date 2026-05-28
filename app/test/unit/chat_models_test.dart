import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickers_master/models/chat_models.dart';

void main() {
  group('chatIdFor', () {
    test('is deterministic regardless of argument order', () {
      expect(chatIdFor('alice', 'bob'), chatIdFor('bob', 'alice'));
    });

    test('joins the two uids in sorted order', () {
      expect(chatIdFor('bob', 'alice'), 'alice_bob');
    });
  });

  group('Chat.fromMap', () {
    Chat buildChat(Map<String, dynamic> overrides) {
      final data = <String, dynamic>{
        'participants': <String>['me', 'you'],
        'participant_names': <String, dynamic>{'me': 'Me', 'you': 'You'},
        'participant_photos': <String, dynamic>{
          'me': null,
          'you': 'http://x/p.png',
        },
        'album_id': 'panini-fifa-world-cup-2026',
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 1)),
        ...overrides,
      };
      return Chat.fromMap('me_you', data);
    }

    test('parses participants, names and photos', () {
      final chat = buildChat({});
      expect(chat.id, 'me_you');
      expect(chat.participants, ['me', 'you']);
      expect(chat.participantNames['you'], 'You');
      expect(chat.participantPhotos['me'], isNull);
      expect(chat.albumId, 'panini-fifa-world-cup-2026');
    });

    test('otherUid and otherName return the non-me participant', () {
      final chat = buildChat({});
      expect(chat.otherUid('me'), 'you');
      expect(chat.otherName('me'), 'You');
    });

    test('isHiddenFor reflects the hidden_for list', () {
      final chat = buildChat({
        'hidden_for': <String>['me'],
      });
      expect(chat.isHiddenFor('me'), isTrue);
      expect(chat.isHiddenFor('you'), isFalse);
    });
  });

  group('Chat.hasUnreadFor', () {
    final lastMsgAt = Timestamp.fromDate(DateTime(2026, 5, 10, 12, 0));

    Chat chatWith(Map<String, dynamic> overrides) {
      final data = <String, dynamic>{
        'participants': <String>['me', 'you'],
        'participant_names': <String, dynamic>{'me': 'Me', 'you': 'You'},
        'participant_photos': <String, dynamic>{},
        'album_id': 'a',
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'last_message': 'hi',
        'last_message_at': lastMsgAt,
        'last_message_sender': 'you',
        ...overrides,
      };
      return Chat.fromMap('me_you', data);
    }

    test('a chat with no last message has nothing unread', () {
      final chat = Chat.fromMap('me_you', {
        'participants': <String>['me', 'you'],
        'participant_names': <String, dynamic>{},
        'participant_photos': <String, dynamic>{},
        'album_id': 'a',
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 1)),
      });
      expect(chat.hasUnreadFor('me'), isFalse);
    });

    test('my own last message is never unread for me', () {
      final chat = chatWith({'last_message_sender': 'me'});
      expect(chat.hasUnreadFor('me'), isFalse);
    });

    test('a message from the other user with no read record is unread', () {
      expect(chatWith({}).hasUnreadFor('me'), isTrue);
    });

    test('reading after the last message clears the unread state', () {
      final chat = chatWith({
        'last_read': <String, dynamic>{
          'me': Timestamp.fromDate(DateTime(2026, 5, 10, 13, 0)),
        },
      });
      expect(chat.hasUnreadFor('me'), isFalse);
    });

    test('a read timestamp older than the last message stays unread', () {
      final chat = chatWith({
        'last_read': <String, dynamic>{
          'me': Timestamp.fromDate(DateTime(2026, 5, 10, 11, 0)),
        },
      });
      expect(chat.hasUnreadFor('me'), isTrue);
    });
  });

  group('Chat per-user history cutoff', () {
    // historyCutoffFor reflects the per-user "delete forever for me"
    // timestamp stored on the chat doc under `deleted_at_for.{uid}`.
    // Messages with createdAt <= cutoff must be filtered out of that
    // user's view (chat detail screen does the filtering); the OTHER
    // user keeps their copy.

    Chat buildChat(Map<String, dynamic> overrides) {
      final data = <String, dynamic>{
        'participants': <String>['me', 'you'],
        'participant_names': <String, dynamic>{'me': 'Me', 'you': 'You'},
        'participant_photos': <String, dynamic>{},
        'album_id': 'a',
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 1)),
        ...overrides,
      };
      return Chat.fromMap('me_you', data);
    }

    test('historyCutoffFor returns null when no cutoff is set', () {
      final chat = buildChat({});
      expect(chat.historyCutoffFor('me'), isNull);
      expect(chat.deletedAtFor, isEmpty);
    });

    test('historyCutoffFor returns my timestamp when I have deleted', () {
      final myCutoff = DateTime(2026, 5, 10, 14, 30);
      final chat = buildChat({
        'deleted_at_for': <String, dynamic>{
          'me': Timestamp.fromDate(myCutoff),
        },
      });
      expect(chat.historyCutoffFor('me'), myCutoff);
      expect(chat.historyCutoffFor('you'), isNull);
    });

    test('historyCutoffFor is per-user: my delete does not affect you', () {
      final myCutoff = DateTime(2026, 5, 10);
      final yourCutoff = DateTime(2026, 5, 12);
      final chat = buildChat({
        'deleted_at_for': <String, dynamic>{
          'me': Timestamp.fromDate(myCutoff),
          'you': Timestamp.fromDate(yourCutoff),
        },
      });
      expect(chat.historyCutoffFor('me'), myCutoff);
      expect(chat.historyCutoffFor('you'), yourCutoff);
    });

    test('hasUnreadFor ignores last message that predates my cutoff', () {
      // If the only message arrived before I deleted, I shouldn't
      // see an unread badge for it.
      final cutoff = DateTime(2026, 5, 10, 12, 0);
      final lastMsgAt = DateTime(2026, 5, 10, 11, 0); // before cutoff
      final chat = buildChat({
        'participants': <String>['me', 'you'],
        'last_message': 'hi',
        'last_message_at': Timestamp.fromDate(lastMsgAt),
        'last_message_sender': 'you',
        'deleted_at_for': <String, dynamic>{
          'me': Timestamp.fromDate(cutoff),
        },
      });
      expect(chat.hasUnreadFor('me'), isFalse);
    });

    test('hasUnreadFor still fires for a message after my cutoff', () {
      // A NEW message that arrived after my delete should resurface the
      // chat as unread.
      final cutoff = DateTime(2026, 5, 10, 12, 0);
      final lastMsgAt = DateTime(2026, 5, 11, 8, 0); // after cutoff
      final chat = buildChat({
        'participants': <String>['me', 'you'],
        'last_message': 'still here?',
        'last_message_at': Timestamp.fromDate(lastMsgAt),
        'last_message_sender': 'you',
        'deleted_at_for': <String, dynamic>{
          'me': Timestamp.fromDate(cutoff),
        },
      });
      expect(chat.hasUnreadFor('me'), isTrue);
    });
  });

  group('Chat intro persistence', () {
    // The intro message lives on the chat doc itself (not in /messages)
    // because Firestore rules require sender_id == request.auth.uid on
    // message create, so the recipient can't post on the requester's
    // behalf. See ChatRepository.acceptRequest for the full reasoning.

    Chat buildChat(Map<String, dynamic> overrides) {
      final data = <String, dynamic>{
        'participants': <String>['me', 'you'],
        'participant_names': <String, dynamic>{'me': 'Me', 'you': 'You'},
        'participant_photos': <String, dynamic>{},
        'album_id': 'panini-fifa-world-cup-2026',
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 1)),
        ...overrides,
      };
      return Chat.fromMap('me_you', data);
    }

    test('fromMap parses intro_message, intro_sender, intro_at', () {
      final introAt = DateTime(2026, 5, 10, 9, 30);
      final chat = buildChat({
        'intro_message': 'Hi, want to trade ENG2?',
        'intro_sender': 'you',
        'intro_at': Timestamp.fromDate(introAt),
      });
      expect(chat.introMessage, 'Hi, want to trade ENG2?');
      expect(chat.introSender, 'you');
      expect(chat.introAt, introAt);
    });

    test('hasIntro is true when both message and sender are present', () {
      final chat = buildChat({
        'intro_message': 'Hi!',
        'intro_sender': 'you',
        'intro_at': Timestamp.fromDate(DateTime(2026, 5, 10)),
      });
      expect(chat.hasIntro, isTrue);
    });

    test('hasIntro is false when intro fields are missing', () {
      expect(buildChat({}).hasIntro, isFalse);
    });

    test('hasIntro is false when intro_message is the empty string', () {
      final chat = buildChat({
        'intro_message': '',
        'intro_sender': 'you',
      });
      expect(chat.hasIntro, isFalse);
    });

    test('hasIntro is false when intro_sender is missing', () {
      final chat = buildChat({'intro_message': 'Hi!'});
      expect(chat.hasIntro, isFalse);
    });

    test('intro fields default to null when absent', () {
      final chat = buildChat({});
      expect(chat.introMessage, isNull);
      expect(chat.introSender, isNull);
      expect(chat.introAt, isNull);
    });
  });

  group('ChatRequest.fromMap', () {
    test('parses fields and a known status', () {
      final req = ChatRequest.fromMap('req1', {
        'from_user': 'a',
        'to_user': 'b',
        'from_display_name': 'Alice',
        'album_id': 'panini',
        'intro_message': 'Hi, want to swap?',
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 2)),
        'status': 'accepted',
      });
      expect(req.id, 'req1');
      expect(req.fromUser, 'a');
      expect(req.toUser, 'b');
      expect(req.introMessage, 'Hi, want to swap?');
      expect(req.status, ChatRequestStatus.accepted);
    });

    test('an unknown status falls back to pending', () {
      final req = ChatRequest.fromMap('r', {
        'from_user': 'a',
        'to_user': 'b',
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 2)),
        'status': 'not-a-real-status',
      });
      expect(req.status, ChatRequestStatus.pending);
    });

    test('parses recipient denormalised fields when present', () {
      final req = ChatRequest.fromMap('r', {
        'from_user': 'a',
        'to_user': 'b',
        'from_display_name': 'Alice',
        'to_display_name': 'Bob',
        'to_photo_url': 'http://example.com/bob.png',
        'album_id': 'panini',
        'intro_message': 'Hey',
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 2)),
        'status': 'pending',
      });
      expect(req.toDisplayName, 'Bob');
      expect(req.toPhotoUrl, 'http://example.com/bob.png');
    });

    test('toDisplayName and toPhotoUrl are null on old requests', () {
      // Requests written before the denormalisation must still parse cleanly.
      final req = ChatRequest.fromMap('r', {
        'from_user': 'a',
        'to_user': 'b',
        'from_display_name': 'Alice',
        'album_id': 'panini',
        'intro_message': 'Hey',
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 2)),
        'status': 'pending',
      });
      expect(req.toDisplayName, isNull);
      expect(req.toPhotoUrl, isNull);
    });

    test('cancelled is a parseable status', () {
      final req = ChatRequest.fromMap('r', {
        'from_user': 'a',
        'to_user': 'b',
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 2)),
        'status': 'cancelled',
      });
      expect(req.status, ChatRequestStatus.cancelled);
    });

    test('isFromHidden reflects the from_hidden_at timestamp', () {
      final hidden = ChatRequest.fromMap('r', {
        'from_user': 'a',
        'to_user': 'b',
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 2)),
        'status': 'declined',
        'from_hidden_at': Timestamp.fromDate(DateTime(2026, 5, 3)),
      });
      expect(hidden.isFromHidden, isTrue);
      expect(hidden.fromHiddenAt, DateTime(2026, 5, 3));

      final visible = ChatRequest.fromMap('r2', {
        'from_user': 'a',
        'to_user': 'b',
        'created_at': Timestamp.fromDate(DateTime(2026, 5, 2)),
        'status': 'declined',
      });
      expect(visible.isFromHidden, isFalse);
      expect(visible.fromHiddenAt, isNull);
    });
  });
}
