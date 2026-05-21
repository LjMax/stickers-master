import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/preferences_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/fcm_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Try to initialize Firebase. Until `flutterfire configure` has been run,
  // `DefaultFirebaseOptions.currentPlatform` throws and we fall back to
  // local-only mode. The auth-aware UI handles a null user gracefully.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Enable Firestore offline persistence (default on mobile, but set
    // explicitly to be safe; allows the collection to load instantly from
    // local cache and queue writes when offline).
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    firebaseReady = true;
    // Ensure every session has a uid (anonymous if no real account exists).
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    // FCM: initialise local notification channel + foreground handlers.
    await FcmService.instance.init();

    // Keep the FCM token in sync with whoever is currently signed in.
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user == null) return;
      if (user.isAnonymous) {
        // No push delivery for guests.
        return;
      }
      // Fire-and-forget: token writes shouldn't block app rendering.
      unawaited(FcmService.instance.syncTokenForUser(user.uid));
    });
  } catch (e, st) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Firebase init skipped: $e\n$st');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseReadyProvider.overrideWithValue(firebaseReady),
      ],
      child: const StickersMasterApp(),
    ),
  );
}

/// `true` once `Firebase.initializeApp` has succeeded. Sign-in UI checks
/// this and shows a "Firebase not configured" hint if it's `false`.
final firebaseReadyProvider = Provider<bool>((ref) {
  throw UnimplementedError('Overridden in main()');
});

class StickersMasterApp extends ConsumerWidget {
  const StickersMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Stickers Master',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      locale: locale,
      supportedLocales: const [
        Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
