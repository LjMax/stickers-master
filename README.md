# Stickers Master

A Flutter mobile app for sticker album collectors. Track your collection (have /
duplicates / asking), find swap partners in your city, and chat once both sides
agree.

**First album:** Panini FIFA World Cup 2026 (980 stickers, 48 teams, 68 foils).
**Initial platform:** Android. Built on Flutter so iOS is a later-phase port,
not a rewrite.
**Languages:** Serbian Latin (default), English.

## Repository layout

```
sticker-album-app/
├── README.md            This file
├── .gitignore
├── firebase.json        Firebase CLI config (Firestore rules + functions)
├── firestore.rules      Firestore security rules
├── firestore.indexes.json
├── data/
│   ├── stickers.json    Generated FIFA WC 2026 album data (980 stickers)
│   └── README.md        Data file documentation
├── tools/
│   └── generate_stickers_json.py   Generator script that produces stickers.json
├── functions/           Firebase Cloud Functions (Node + TypeScript)
└── app/                 Flutter project
```

## Tech stack

- **Flutter / Dart** with **Riverpod** for state management.
- **Firebase** — Auth (Google + anonymous guest), Cloud Firestore, Cloud
  Messaging, Cloud Functions.
- Localization via `flutter_localizations` + ARB files.

## Features

- Collection tracking with per-sticker owned count (missing / have / duplicates),
  grouped by team, with search and filters.
- Swap area that matches collectors in the same city by overlap between what you
  need and what they have spare.
- Request-gated 1:1 chat with push notifications, plus block and report tools.

## Building

This repository does not include the Firebase configuration files
(`firebase_options.dart`, `google-services.json`, `.firebaserc`,
`app/firebase.json`) — they are project-specific and generated locally. To build
your own instance you need a Firebase project of your own and the FlutterFire
CLI (`flutterfire configure`).

```
cd app
flutter pub get
flutter run
```

## Regenerating sticker data

```
cd tools
python generate_stickers_json.py
# then copy data/stickers.json to app/assets/data/stickers.json
```
