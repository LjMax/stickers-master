import '../models/chat_models.dart';

/// Synthetic message id used for the intro that lives on the chat doc.
/// Real Firestore message ids are random; this constant lets us defend
/// against accidental duplication if a real message ever lands with the
/// same id (it won't, but it's cheap to be careful).
const String kSyntheticIntroId = '__intro__';

/// Build the list of messages [myUid] should see in [chat].
///
/// Two transformations, applied in this order:
///
///   1. **Per-user history cutoff** ([Chat.historyCutoffFor]). When a
///      user picks "Delete forever for me" we stamp a server timestamp
///      in `deleted_at_for[myUid]`. Messages whose `createdAt` is at or
///      before that stamp are filtered out of *their* view — even
///      though they remain in Firestore for the other participant.
///
///   2. **Intro insertion**. The intro message (denormalised onto the
///      chat doc at accept time, since the recipient can't write a
///      /messages doc with the requester's uid as sender) is inserted
///      at the chronologically correct position. If the intro predates
///      [myUid]'s cutoff, it isn't shown.
///
/// Why chronological insertion (not always-prepend): for the user who
/// hard-deleted, after step 1 only post-cutoff messages remain and the
/// intro lands at the top naturally. For the *other* participant (who
/// kept the history), unconditionally prepending a fresh intro on top
/// of an existing thread was misleading — they'd see today's intro
/// above last week's messages. Inserting by timestamp keeps the
/// timeline truthful for everyone.
List<ChatMessage> messagesForUser(
  Chat chat,
  List<ChatMessage> messages,
  String myUid,
) {
  final cutoff = chat.historyCutoffFor(myUid);

  // Step 1: apply the per-user delete cutoff.
  final visible = cutoff == null
      ? messages
      : messages.where((m) => m.createdAt.isAfter(cutoff)).toList();

  // Step 2: insert the synthesized intro at its chronological position.
  if (!chat.hasIntro) return visible;
  final introAt = chat.introAt ?? chat.createdAt;
  // Intro predates this user's cutoff — they've moved on; don't show it.
  if (cutoff != null && !introAt.isAfter(cutoff)) return visible;
  // Defensive: if a real message already has the synthetic id, skip.
  if (visible.any((m) => m.id == kSyntheticIntroId)) return visible;

  final intro = ChatMessage(
    id: kSyntheticIntroId,
    senderId: chat.introSender!,
    text: chat.introMessage!,
    createdAt: introAt,
  );

  // visible is ordered ascending by createdAt. Find the insertion
  // point: the first index where the existing message is NOT older
  // than the intro. The intro is inserted there, preserving order.
  var idx = 0;
  while (idx < visible.length &&
      visible[idx].createdAt.isBefore(introAt)) {
    idx++;
  }
  return [
    ...visible.sublist(0, idx),
    intro,
    ...visible.sublist(idx),
  ];
}
