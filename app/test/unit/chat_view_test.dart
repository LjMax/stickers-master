import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickers_master/models/chat_models.dart';
import 'package:stickers_master/services/chat_view.dart';

void main() {
  // Helpers.
  Chat buildChat({
    Map<String, DateTime> deletedAtFor = const {},
    String? introMessage,
    String? introSender,
    DateTime? introAt,
  }) {
    final data = <String, dynamic>{
      'participants': <String>['me', 'you'],
      'participant_names': <String, dynamic>{'me': 'Me', 'you': 'You'},
      'participant_photos': <String, dynamic>{},
      'album_id': 'a',
      'created_at': Timestamp.fromDate(DateTime(2026, 5, 1)),
      if (deletedAtFor.isNotEmpty)
        'deleted_at_for': deletedAtFor.map(
            (k, v) => MapEntry(k, Timestamp.fromDate(v))),
      if (introMessage != null) 'intro_message': introMessage,
      if (introSender != null) 'intro_sender': introSender,
      if (introAt != null) 'intro_at': Timestamp.fromDate(introAt),
    };
    return Chat.fromMap('me_you', data);
  }

  ChatMessage msg(String id, String sender, DateTime at) => ChatMessage(
        id: id,
        senderId: sender,
        text: 't',
        createdAt: at,
      );

  group('messagesForUser — cutoff filtering', () {
    test('drops messages older than my cutoff', () {
      final chat = buildChat(deletedAtFor: {'me': DateTime(2026, 5, 10, 12)});
      final messages = [
        msg('m1', 'you', DateTime(2026, 5, 9)),
        msg('m2', 'you', DateTime(2026, 5, 11)),
      ];
      expect(
        messagesForUser(chat, messages, 'me').map((m) => m.id).toList(),
        ['m2'],
      );
    });

    test('keeps messages for the other participant (no cutoff)', () {
      final chat = buildChat(deletedAtFor: {'me': DateTime(2026, 5, 10, 12)});
      final messages = [
        msg('m1', 'you', DateTime(2026, 5, 9)),
        msg('m2', 'you', DateTime(2026, 5, 11)),
      ];
      expect(
        messagesForUser(chat, messages, 'you').map((m) => m.id).toList(),
        ['m1', 'm2'],
      );
    });

    test('messages exactly at the cutoff timestamp are dropped', () {
      final cutoff = DateTime(2026, 5, 10, 12, 0, 0);
      final chat = buildChat(deletedAtFor: {'me': cutoff});
      final messages = [msg('m1', 'you', cutoff)];
      // !createdAt.isAfter(cutoff) → drop
      expect(messagesForUser(chat, messages, 'me'), isEmpty);
    });
  });

  group('messagesForUser — intro insertion (regression for v1.0.5 bug)', () {
    test('intro lands at the top when no real messages remain', () {
      // The deleter case: after cutoff filtering, there are no older
      // messages, so the intro shows first.
      final cutoff = DateTime(2026, 5, 10);
      final introAt = DateTime(2026, 5, 12);
      final chat = buildChat(
        deletedAtFor: {'me': cutoff},
        introMessage: 'Hi again',
        introSender: 'you',
        introAt: introAt,
      );
      final messages = [
        // Pre-delete message — filtered out by cutoff.
        msg('old1', 'you', DateTime(2026, 5, 5)),
      ];
      final shown = messagesForUser(chat, messages, 'me');
      expect(shown.length, 1);
      expect(shown.first.id, kSyntheticIntroId);
      expect(shown.first.text, 'Hi again');
    });

    test('intro is inserted chronologically, not pinned to the top', () {
      // The other-party case (one user deleted, the other didn't).
      // Old messages must stay visible, and a newly-set intro should
      // appear AFTER them — not be pinned at the top.
      final introAt = DateTime(2026, 5, 12);
      final chat = buildChat(
        introMessage: 'Hi again',
        introSender: 'me',
        introAt: introAt,
      );
      final messages = [
        msg('old1', 'me', DateTime(2026, 5, 5)),
        msg('old2', 'you', DateTime(2026, 5, 6)),
      ];
      final shown = messagesForUser(chat, messages, 'you');
      expect(shown.map((m) => m.id).toList(),
          ['old1', 'old2', kSyntheticIntroId]);
    });

    test('intro lands between older and newer real messages', () {
      final introAt = DateTime(2026, 5, 12);
      final chat = buildChat(
        introMessage: 'Hi again',
        introSender: 'me',
        introAt: introAt,
      );
      final messages = [
        msg('before', 'me', DateTime(2026, 5, 5)),
        msg('after', 'you', DateTime(2026, 5, 13)),
      ];
      final shown = messagesForUser(chat, messages, 'you');
      expect(shown.map((m) => m.id).toList(),
          ['before', kSyntheticIntroId, 'after']);
    });

    test('intro is suppressed when it predates my cutoff', () {
      // The "ghost intro" case: long-ago intro should not be revived
      // for a user who has since wiped history.
      final introAt = DateTime(2026, 5, 5);
      final cutoff = DateTime(2026, 5, 10);
      final chat = buildChat(
        deletedAtFor: {'me': cutoff},
        introMessage: 'Old intro',
        introSender: 'you',
        introAt: introAt,
      );
      final messages = [msg('m1', 'you', DateTime(2026, 5, 11))];
      final shown = messagesForUser(chat, messages, 'me');
      expect(shown.map((m) => m.id).toList(), ['m1']);
    });

    test('no intro on the chat doc → messages are returned untouched', () {
      final chat = buildChat();
      final messages = [
        msg('m1', 'you', DateTime(2026, 5, 5)),
        msg('m2', 'me', DateTime(2026, 5, 6)),
      ];
      expect(messagesForUser(chat, messages, 'me'), messages);
    });

    test('cutoff + intro + new messages: deleter sees a clean fresh thread',
        () {
      // End-to-end regression: this is the exact scenario the user
      // reported in v1.0.5 closed testing — both users delete-forever,
      // a new request is accepted, and the deleter must NOT see the
      // old history when the new chat resurfaces.
      final cutoff = DateTime(2026, 5, 10);
      final introAt = DateTime(2026, 5, 12);
      final chat = buildChat(
        deletedAtFor: {'me': cutoff, 'you': cutoff},
        introMessage: 'Want to swap again?',
        introSender: 'you',
        introAt: introAt,
      );
      final messages = [
        // Pre-delete history — should be invisible to both.
        msg('old1', 'me', DateTime(2026, 5, 4)),
        msg('old2', 'you', DateTime(2026, 5, 6)),
        // A new message that came after the accept.
        msg('new1', 'me', DateTime(2026, 5, 13)),
      ];
      final shown = messagesForUser(chat, messages, 'me');
      expect(shown.map((m) => m.id).toList(),
          [kSyntheticIntroId, 'new1']);
    });
  });
}
