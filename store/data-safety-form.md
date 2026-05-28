# Stickers Master — Google Play Data Safety Form

A walkthrough of the Data Safety section in the Play Console (App content → Data safety),
based on what the app actually transmits off the device. Verified against the code on
2026-05-25 (`public_profile.dart`, `chat_models.dart`, `fcm_service.dart`,
`moderation_repository.dart`, `AndroidManifest.xml`).

**Ground truth — what the app sends off the device:**

- Firebase Auth: a user ID (UID) for everyone; for Google sign-in, also the Google
  account's email, name, and profile-photo URL.
- `public_profiles/{uid}`: display name, city, country, profile-photo URL.
- `users/{uid}/private/fcm`: the device's FCM push token + platform string.
- Chats: message text, plus participants' display names and photo URLs.
- Chat requests: a short intro message, sender name/photo.
- Blocks / reports: UIDs, a name/photo, a report reason and optional details.
- Collection progress (which stickers you own/duplicate) synced to Firestore.

**What the app does NOT send off the device:**

- Page-scan photos. The camera photo is shown on-device as a visual reference only
  and is never uploaded or stored remotely. Data Safety covers only data transmitted
  off the device, so the page-scan photo is **not** declared.
- No analytics SDK, no Crashlytics, no advertising SDK (none are in `pubspec.yaml`).
- No device location — there is no location permission; the city is typed by the user.

---

## Section 1 — Overview questions

**Does your app collect or share any of the required user data types?**
→ **Yes**

**Is all of the user data collected by your app encrypted in transit?**
→ **Yes.** Firebase (Auth, Firestore, Cloud Functions, Cloud Messaging) uses HTTPS/TLS
for all connections.

**Do you provide a way for users to request that their data is deleted?**
→ **Yes.** The app has an in-app "Delete account" action (Settings → Account) that
erases the user's data, and users can also email a request. When asked for a deletion
URL, give the privacy-policy page (it documents the in-app deletion path).

---

## Section 2 — Data types collected

For every type below: **Collected = Yes**, **Shared = No**, **Processed ephemerally = No**.

"Shared = No" is correct: data lives in Firebase, which is Google acting as your
processor/hosting provider — that is not "sharing" under Data Safety rules. Profile
names and chat messages being visible to *other app users* is also not "sharing"
(sharing means transfer to a separate company/entity).

### 2.1 Location — Approximate location
- **Collected:** Yes
- **Shared:** No
- **Required or optional:** Optional (only collected if the user fills in a swap profile)
- **Purpose:** App functionality
- *Why:* the user-typed city is used to match nearby collectors. There is no GPS access.

### 2.2 Personal info — Name
- **Collected:** Yes
- **Shared:** No
- **Required or optional:** Optional
- **Purpose:** App functionality; Account management
- *Why:* display name (from the Google account, or edited in Settings) is shown to
  other collectors on swap cards and in chats.

### 2.3 Personal info — Email address
- **Collected:** Yes
- **Shared:** No
- **Required or optional:** Optional
- **Purpose:** Account management
- *Why:* Firebase Auth records the email for Google sign-in users. Guests (anonymous
  sign-in) have no email.

### 2.4 Personal info — User IDs
- **Collected:** Yes
- **Shared:** No
- **Required or optional:** Required
- **Purpose:** App functionality; Account management
- *Why:* every user (including guests) gets a Firebase Auth UID; it keys their data.

### 2.5 Photos and videos — Photos
- **Collected:** Yes
- **Shared:** No
- **Required or optional:** Optional
- **Purpose:** App functionality
- *Why:* for Google sign-in users the app stores and displays the Google account
  profile photo as an avatar. **Judgment call — see notes below.**

### 2.6 Messages — Other in-app messages
- **Collected:** Yes
- **Shared:** No
- **Required or optional:** Optional
- **Purpose:** App functionality
- *Why:* the request-gated 1:1 chat stores message text in Firestore.

### 2.7 App activity — Other user-generated content
- **Collected:** Yes
- **Shared:** No
- **Required or optional:** Optional
- **Purpose:** App functionality
- *Why:* sticker collection progress and the chat-request intro message are
  user-generated content synced to Firestore.

### 2.8 Device or other IDs
- **Collected:** Yes
- **Shared:** No
- **Required or optional:** Optional
- **Purpose:** App functionality
- *Why:* the FCM registration token is stored so Cloud Functions can deliver push
  notifications. Only non-anonymous users get a token written.

---

## Section 3 — Judgment calls to confirm

These are the spots where the form is genuinely ambiguous. My recommendation is the
conservative (declare-it) choice, because Google penalises under-declaration far more
than over-declaration. Decide whether you agree before submitting.

1. **Profile photo as "Photos" (2.5).** The app stores a *URL* to the Google-hosted
   profile image, not the image bytes. Some developers would not declare this. I
   recommend declaring it — it is the user's photo and it is shown to others. If you
   prefer not to, you can drop section 2.5, but be consistent with the privacy policy.

2. **City as "Approximate location" (2.1).** The city is typed, not sensed from the
   device. It is still the user's location, so I recommend declaring it under
   Approximate location. There is no location permission, so a reviewer will not
   expect GPS — this declaration just matches the privacy policy.

3. **Required vs optional.** I marked User IDs as Required (unavoidable — even guests
   get one) and everything else Optional (guest mode works without sign-in, profile,
   chat, or notifications). If the app cannot actually be used in guest mode without
   an account, several of these shift to Required.

---

## Section 4 — Things NOT to declare (and why)

- **Page-scan camera photo** — never leaves the device; Data Safety only covers
  transmitted data.
- **Crash logs / Diagnostics / Analytics** — no Crashlytics or Analytics SDK is
  integrated. Declare nothing here.
- **Precise location** — no location permission of any kind.
- **Financial info, Health, Contacts, Calendar, Web history** — none collected.

Keep the privacy policy (`docs/privacy-policy.html`) and this form consistent — Google
cross-checks them, and a reviewer will compare both.
