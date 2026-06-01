import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages the lifecycle of the device's FCM token and renders notifications
/// when they arrive while the app is in the foreground.
///
/// Wiring (see main.dart):
///   1. `FcmService.instance.init()` is called once at app start (after
///      Firebase is initialized).
///   2. On every auth state change to a non-anonymous user, we call
///      `syncTokenForUser(uid)` so the active device's token lands at
///      `users/{uid}/private/fcm`.
///   3. Cloud Functions read that token to deliver pushes when chat
///      requests / messages arrive.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _local = FlutterLocalNotificationsPlugin();
  final _channel = const AndroidNotificationChannel(
    'stickers_master_chat',
    'Razmena i poruke',
    description: 'Obaveštenja o zahtevima i porukama',
    importance: Importance.high,
  );

  /// Holds the latest token we successfully wrote, and the uid we wrote it
  /// for, so we don't churn on every Firestore listen tick. The uid must be
  /// part of the guard: after an account switch on one device the device
  /// token is unchanged, so a token-only check would skip writing the new
  /// user's token doc and they'd receive no pushes.
  String? _lastWrittenToken;
  String? _lastWrittenUid;
  StreamSubscription<String>? _refreshSub;

  Future<void> init() async {
    // Local notifications init (foreground display + tap routing).
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalTap,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Permission (Android 13+ shows a system dialog; older Android grants
    // by default; iOS will be handled when we activate that platform).
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages → show a local notification ourselves (Android
    // doesn't show FCM data-payload pushes in the tray when the app is
    // foregrounded).
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Tap on a system notification that opened the app from background or
    // terminated state. The deep-link data lives in `message.data`.
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // If the app was launched from a notification while terminated, deliver
    // the deep-link once UI is ready (handled by NotificationRoute below).
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      NotificationRoute.set(initial.data);
    }
  }

  /// Make sure the current device's FCM token is saved to Firestore for
  /// [uid]. Call this on sign-in and whenever the token rotates.
  Future<void> syncTokenForUser(String uid) async {
    // Anonymous users won't receive pushes — skip.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      _lastWrittenToken = null;
      _lastWrittenUid = null;
      return;
    }

    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      if (kDebugMode) debugPrint('FCM getToken failed: $e');
      return;
    }
    if (token == null || token.isEmpty) return;
    if (token == _lastWrittenToken && uid == _lastWrittenUid) {
      return; // already written for this user
    }

    try {
      await FirebaseFirestore.instance.doc('users/$uid/private/fcm').set({
        'token': token,
        'platform': Platform.isAndroid
            ? 'android'
            : Platform.isIOS
                ? 'ios'
                : 'other',
        'updated_at': FieldValue.serverTimestamp(),
      });
      _lastWrittenToken = token;
      _lastWrittenUid = uid;
    } catch (e) {
      if (kDebugMode) debugPrint('FCM token write failed: $e');
    }

    // Subscribe to refresh events once.
    _refreshSub ??=
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null || current.isAnonymous) return;
      if (newToken == _lastWrittenToken) return;
      try {
        await FirebaseFirestore.instance
            .doc('users/${current.uid}/private/fcm')
            .set({
          'token': newToken,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'updated_at': FieldValue.serverTimestamp(),
        });
        _lastWrittenToken = newToken;
        _lastWrittenUid = current.uid;
      } catch (e) {
        if (kDebugMode) debugPrint('FCM token refresh write failed: $e');
      }
    });
  }

  /// Clear the device token for [uid] (called on sign-out, before signing
  /// back in as a different account).
  Future<void> clearTokenForUser(String uid) async {
    try {
      await FirebaseFirestore.instance.doc('users/$uid/private/fcm').delete();
    } catch (_) {/* ignore */}
    _lastWrittenToken = null;
    _lastWrittenUid = null;
  }

  /// Called by Firebase when a push arrives **while the app is foreground**
  /// (background / terminated pushes are rendered by the OS via the FCM
  /// notification payload — this handler never runs in those cases).
  ///
  /// Behaviour: do nothing. The user is already in the app, so a system
  /// tray banner would be redundant and intrusive (especially when they
  /// are inside the very chat that the notification is about). The same
  /// data has already been delivered via the live Firestore listeners:
  /// the inbox tab badge will increment, and an open chat thread will
  /// receive the new message in its message stream within milliseconds.
  ///
  /// We deliberately do **not** call `_local.show(...)` here — that was
  /// what produced the heads-up notification while the app was open.
  Future<void> _onForegroundMessage(RemoteMessage msg) async {
    // No-op: in-app indicators (badge, message stream) cover this case.
  }

  void _onMessageOpenedApp(RemoteMessage msg) {
    NotificationRoute.set(msg.data);
  }

  void _onLocalTap(NotificationResponse resp) {
    final data = _decodePayload(resp.payload);
    if (data != null) NotificationRoute.set(data);
  }

  Map<String, String>? _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final out = <String, String>{};
    for (final pair in payload.split('|')) {
      final i = pair.indexOf('=');
      if (i <= 0) continue;
      out[pair.substring(0, i)] = pair.substring(i + 1);
    }
    return out;
  }
}

/// Buffer for the most recent pending notification deep-link.
///
/// When a notification is tapped, [FcmService] stores the data payload
/// into [pending]. The app's UI shell adds a listener to [pending] and
/// consumes the data (via [consume]) to navigate to the right screen.
///
/// [pending] is a [ValueNotifier] so the shell is notified the moment a
/// tap happens while the app is already running (background → foreground,
/// or a foreground local-notification tap). For the terminated-launch
/// case, the value is set before the shell mounts, so the shell also
/// checks [hasPending] in its `initState`.
class NotificationRoute {
  static final ValueNotifier<Map<String, String>?> pending =
      ValueNotifier<Map<String, String>?>(null);

  static void set(Map<String, dynamic> data) {
    pending.value = data.map((k, v) => MapEntry(k, '$v'));
  }

  static Map<String, String>? consume() {
    final out = pending.value;
    pending.value = null;
    return out;
  }

  static bool get hasPending => pending.value != null;
}
