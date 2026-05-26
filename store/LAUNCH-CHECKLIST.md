# Stickers Master — Play Store Launch Checklist

Everything needed to publish v1.0.0, in the order the Play Console walks you through it.
Work through this once your developer account is verified.

Legend: **[DONE]** prepared and ready · **[YOU]** only you can do this (in the Console
or on a device) · **[DECIDE]** a choice to make.

All prepared materials live in this `store/` folder.

---

## A. Materials already prepared

- **[DONE]** Signed App Bundle — `app/build/app/outputs/bundle/release/app-release.aab`
  (versionName 1.0.0, versionCode 1).
- **[DONE]** Store listing copy, EN + SR — `store/play-store-listing.md`.
- **[DONE]** Hi-res app icon, 512×512 — `store/assets/hi-res-icon-512.png`.
- **[DONE]** Feature graphic, 1024×500 — `store/assets/feature-graphic-1024x500.png`.
- **[DONE]** Data Safety form answers — `store/data-safety-form.md`.
- **[DONE]** Content rating answers — `store/content-rating.md`.
- **[DONE]** Privacy policy file — `docs/privacy-policy.html` (needs hosting, see B5).
- **[DONE]** Screenshot shot list — `store/screenshots-shot-list.md`.

---

## B. Play Console — App content & declarations

1. **Create the app.** Console → Create app. App name "Stickers Master", default
   language **[DECIDE]** (Serbian if you want the SR listing as primary), type **App**,
   **Free**. Accept the declarations.

2. **[YOU]** **App access.** Core album tracking works in guest mode; swap and chat
   need Google sign-in (any Google account works — no special test credentials needed).
   Declare that all functionality is accessible, and optionally add a note: "Swap and
   chat features require signing in with any Google account."

3. **Ads.** Declare **No, the app does not contain ads**.

4. **Content rating.** Run the questionnaire using `store/content-rating.md`.

5. **[YOU]** **Privacy policy.** Host `docs/privacy-policy.html` first — follow
   `store/privacy-policy-hosting.md` — then paste the resulting URL
   (`https://ljmax.github.io/stickers-master/privacy-policy.html`) into App content →
   Privacy policy.

6. **Target audience and content.** Select **13+** age groups only — **not** under-13.
   Reason: the app has open user-to-user chat (see `store/content-rating.md`).

7. **Data safety.** Fill in using `store/data-safety-form.md`.

8. **News app** — No. **Government app** — No. **Financial features** — No.
   **Health apps / COVID-19** — No.

---

## C. Play Console — Store listing

9. **App details.** Paste app name, short description, and full description from
   `store/play-store-listing.md` (set up the EN and SR locales).

10. **Graphics.**
    - App icon → upload `store/assets/hi-res-icon-512.png`.
    - Feature graphic → upload `store/assets/feature-graphic-1024x500.png`.
    - Phone screenshots → **[YOU]** capture 6 per `store/screenshots-shot-list.md`
      (minimum 2 required).

11. **[DECIDE]** **App category.** Suggested: **Entertainment** or **Tools**. (The app
    is a collector's utility; "Sports" is also arguable given the football theme.)
    Pick one — it can be changed later.

12. **Contact details.** Email `stickers.master26@gmail.com` (required). Website and
    phone are optional — the GitHub Pages site URL can serve as the website if you want.

13. **[DECIDE]** **Tags.** Pick from the Console's preset list (e.g. "collection",
    "hobbies") — free text isn't allowed here.

---

## D. Play Console — Production release

14. **[YOU]** **App signing.** On your first upload, accept **Play App Signing** (the
    default). Google manages the app signing key; your keystore stays the upload key.
    Keep `C:\Users\ljuba\keys\stickers-master-release.jks` backed up safely — losing it
    means you can't push updates.

15. **Create a production release.** Production track → Create new release → upload
    `app-release.aab`.

16. **Release notes.** Short "what's new" text for v1.0.0 (EN + SR). Tell me when you
    reach this step and I'll draft them.

17. **[DECIDE]** **Countries / regions.** Your stated launch market is Serbia, Bosnia
    and Herzegovina, Montenegro, North Macedonia, and Croatia. Select those, or go
    wider if you prefer.

18. **Pricing.** Free (set at app creation; confirm here).

19. **Review and roll out.** Submit. First-app review typically takes a few days.

---

## E. Open decisions to settle (collected from above)

- **[DECIDE]** Default Console language — Serbian or English (B1).
- **[DECIDE]** App category — Entertainment / Tools / Sports (C11).
- **[DECIDE]** Store tags (C13).
- **[DECIDE]** Launch countries — regional five or wider (D17).
- **[DECIDE]** Data Safety judgment calls — profile photo, city-as-location,
  required/optional (see `store/data-safety-form.md`, Section 3).
- **[DECIDE]** Content rating — "shares location" answer wording (see
  `store/content-rating.md`, Notes).

---

## F. Pre-submit sanity checks

- Privacy policy URL loads and matches the data described in the Data Safety form.
- The AAB's versionCode is 1; every future upload must increase it.
- The app installs and runs from the release AAB (you've already tested the release
  APK on real devices).
- Repo is public **before** enabling GitHub Pages, if you go that route.
