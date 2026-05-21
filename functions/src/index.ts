/**
 * Stickers Master — Cloud Functions
 *
 * Currently two Firestore-triggered functions:
 *   - onChatRequestCreated: fires when a new doc lands in chat_requests/.
 *     Sends an FCM push to the recipient.
 *   - onMessageCreated: fires when a new message is appended to a chat.
 *     Sends an FCM push to the other participant.
 *
 * Notification text is built in Serbian Latin by default (the app's
 * default UI language). When we add per-user locale preference we'll
 * read it off the recipient's profile and switch text accordingly.
 */

import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging, MulticastMessage } from "firebase-admin/messaging";
import { logger } from "firebase-functions";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();
const fcm = getMessaging();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

interface FcmTokenDoc {
  token?: string;
  platform?: string;
}

/**
 * Read the FCM token for a given uid. Returns null if the user hasn't
 * registered one yet (e.g. anonymous user, or a user who declined the
 * notification permission).
 */
async function getFcmTokenForUid(uid: string): Promise<string | null> {
  const snap = await db.doc(`users/${uid}/private/fcm`).get();
  if (!snap.exists) return null;
  const data = snap.data() as FcmTokenDoc | undefined;
  const token = data?.token;
  return token && token.length > 0 ? token : null;
}

/**
 * Send a push to a single uid. Quietly no-ops if the user has no token.
 * If the FCM API tells us the token is invalid, we delete the doc so we
 * don't keep trying.
 */
async function sendToUid(opts: {
  uid: string;
  title: string;
  body: string;
  data: Record<string, string>;
}): Promise<void> {
  const token = await getFcmTokenForUid(opts.uid);
  if (!token) {
    logger.info(`No FCM token for ${opts.uid}; skipping push.`);
    return;
  }

  const msg: MulticastMessage = {
    tokens: [token],
    notification: { title: opts.title, body: opts.body },
    data: opts.data,
    android: {
      priority: "high",
      notification: {
        channelId: "stickers_master_chat",
        defaultSound: true,
      },
    },
  };

  try {
    const res = await fcm.sendEachForMulticast(msg);
    for (const r of res.responses) {
      if (r.success) continue;
      const err = r.error;
      logger.warn(`FCM send to ${opts.uid} failed: ${err?.code} ${err?.message}`);
      if (
        err?.code === "messaging/registration-token-not-registered" ||
        err?.code === "messaging/invalid-registration-token"
      ) {
        // Stale token — clear it so future sends don't keep failing.
        void db
          .doc(`users/${opts.uid}/private/fcm`)
          .delete()
          .catch(() => undefined);
      }
    }
  } catch (e) {
    logger.error(`FCM send threw for ${opts.uid}:`, e);
  }
}

/** Truncate text for the notification body. */
function clip(s: string, max = 140): string {
  if (s.length <= max) return s;
  return s.slice(0, max - 1) + "…";
}

/**
 * True if `blockerUid` has blocked `blockedUid`. Block docs live at
 * /blocks/{blocker}_{blocked}.
 */
async function isBlockedBy(
  blockerUid: string,
  blockedUid: string
): Promise<boolean> {
  const snap = await db.doc(`blocks/${blockerUid}_${blockedUid}`).get();
  return snap.exists;
}

// ---------------------------------------------------------------------------
// Triggers
// ---------------------------------------------------------------------------

/**
 * Triggered when a new chat_request is created. Sends a push to the
 * recipient (to_user) with the sender's name and intro message.
 */
export const onChatRequestCreated = onDocumentCreated(
  "chat_requests/{requestId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const toUser = data.to_user as string | undefined;
    const fromUser = data.from_user as string | undefined;
    const fromName = (data.from_display_name as string | undefined) ?? "";
    const intro = (data.intro_message as string | undefined) ?? "";

    if (!toUser || !fromUser) return;

    const senderLabel = fromName.length > 0 ? fromName : "Kolekcionar";

    await sendToUid({
      uid: toUser,
      title: `Nova poruka od ${senderLabel}`,
      body: clip(intro, 160),
      data: {
        type: "chat_request",
        request_id: event.params.requestId,
        from_user: fromUser,
      },
    });

    // Stamp delivery time so we can debug delivery latency if needed.
    await event.data?.ref
      .update({ notified_at: FieldValue.serverTimestamp() })
      .catch(() => undefined);
  }
);

/**
 * Triggered when a new message lands in any chat's messages subcollection.
 * Sends a push to the recipient (the other participant).
 */
export const onMessageCreated = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const msg = event.data?.data();
    if (!msg) return;

    const senderId = msg.sender_id as string | undefined;
    const text = (msg.text as string | undefined) ?? "";
    if (!senderId) return;

    const chatId = event.params.chatId;
    const chatSnap = await db.doc(`chats/${chatId}`).get();
    if (!chatSnap.exists) return;
    const chat = chatSnap.data() as {
      participants?: string[];
      participant_names?: Record<string, string>;
    };

    const participants = chat.participants ?? [];
    const recipient = participants.find((p) => p !== senderId);
    if (!recipient) return;

    // If the recipient has blocked the sender, don't push. (Messages from
    // a blocked user can still be written — they're just hidden on the
    // recipient's side — so this check is what stops the notification.
    // Chat *requests* don't need an equivalent check: the Firestore rules
    // reject creating a request between a blocked pair outright.)
    if (await isBlockedBy(recipient, senderId)) {
      logger.info(
        `Recipient ${recipient} blocked sender ${senderId}; skipping push.`
      );
      return;
    }

    const senderName =
      chat.participant_names?.[senderId] ?? "Kolekcionar";

    await sendToUid({
      uid: recipient,
      title: senderName,
      body: clip(text, 160),
      data: {
        type: "chat_message",
        chat_id: chatId,
        sender_id: senderId,
      },
    });
  }
);

// ---------------------------------------------------------------------------
// Account deletion
// ---------------------------------------------------------------------------

/**
 * Callable: permanently deletes the calling user's account and every piece
 * of their data, then deletes the Firebase Auth user. Irreversible.
 *
 * Chats the user took part in are deleted whole — the other participant
 * loses the conversation too. Abuse reports are intentionally NOT deleted;
 * the privacy policy reserves the right to keep them for safety.
 *
 * Pinned to europe-west3 to match the Firestore database region; the Flutter
 * client must call it via FirebaseFunctions.instanceFor(region: ...).
 */
export const deleteAccount = onCall(
  { region: "europe-west3" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "You must be signed in to delete your account."
      );
    }

    logger.info(`Account deletion requested for ${uid}.`);

    try {
      // 1. Private user subtree: collection counts + FCM token.
      await db.recursiveDelete(db.doc(`users/${uid}`));

      // 2. Public profile and its swap-index subcollection.
      await db.recursiveDelete(db.doc(`public_profiles/${uid}`));

      // 3. Chat requests this user sent or received.
      for (const field of ["from_user", "to_user"]) {
        const snap = await db
          .collection("chat_requests")
          .where(field, "==", uid)
          .get();
        await Promise.all(snap.docs.map((d) => d.ref.delete()));
      }

      // 4. Every chat the user took part in — the whole thread and all of
      //    its messages.
      const chatsSnap = await db
        .collection("chats")
        .where("participants", "array-contains", uid)
        .get();
      for (const chat of chatsSnap.docs) {
        await db.recursiveDelete(chat.ref);
      }

      // 5. Block records in either direction.
      for (const field of ["blocker", "blocked"]) {
        const snap = await db
          .collection("blocks")
          .where(field, "==", uid)
          .get();
        await Promise.all(snap.docs.map((d) => d.ref.delete()));
      }

      // 6. Finally, the Auth account itself.
      await getAuth().deleteUser(uid);

      logger.info(`Account deletion complete for ${uid}.`);
      return { ok: true };
    } catch (e) {
      logger.error(`Account deletion failed for ${uid}:`, e);
      throw new HttpsError(
        "internal",
        "Account deletion failed. Please try again."
      );
    }
  }
);
