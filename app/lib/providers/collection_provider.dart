import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_provider.dart';
import 'preferences_provider.dart';

/// Per-sticker owned count: 0 = missing/asking, 1 = have, 2+ = have + duplicates.
///
/// Storage strategy (Phase 2 milestone 2.2):
///
/// * `shared_preferences` is a **fast bootstrap cache** — the constructor
///   loads from it synchronously so the album view paints instantly with the
///   last known state.
/// * When a user is signed in (anonymous or real), `Cloud Firestore` is the
///   **source of truth**. The notifier subscribes to the user's collection
///   document, and any change (local or from another device) propagates back
///   into state.
/// * On mutations, we update local state immediately (optimistic UI) and
///   write through to both the local cache and Firestore. Firestore's
///   offline persistence queues writes when there's no network and replays
///   them when connectivity returns.
/// * If Firebase isn't ready (config issue) or no user is signed in,
///   everything still works against shared_preferences only — the current
///   v0.1 behavior. This is the local-only fallback.
///
/// **Data layout in Firestore:**
/// ```
/// users/{uid}/collections/{albumId}
///   - last_updated: Timestamp
///   - counts: Map<String stickerCode, int ownedCount>
/// ```
/// One document per (user, album). Stickers stored as a map field rather
/// than a subcollection — keeps reads cheap (1 doc read vs 980) and the
/// document is well under Firestore's 1MB cap.
class CollectionNotifier extends StateNotifier<Map<String, int>> {
  CollectionNotifier({
    required SharedPreferences prefs,
    required String albumId,
    required String? uid,
  })  : _prefs = prefs,
        _albumId = albumId,
        _uid = uid,
        super(_loadFromCache(prefs, albumId)) {
    if (_uid != null) {
      _subscribeToFirestore();
    }
  }

  final SharedPreferences _prefs;
  final String _albumId;
  final String? _uid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  String get _cacheKey => 'collection.$_albumId';

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.doc('users/$_uid/collections/$_albumId');

  static Map<String, int> _loadFromCache(SharedPreferences prefs, String albumId) {
    final raw = prefs.getString('collection.$albumId');
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _persistLocal() async {
    await _prefs.setString(_cacheKey, jsonEncode(state));
  }

  /// Tracks whether we've already processed the first subscription emission.
  /// The first one is special — see [_subscribeToFirestore].
  bool _firstEmission = true;

  /// Listens to Firestore.
  ///
  /// **First emission:** merge local + remote with max-wins per sticker, and
  /// push the merged result back if it differs from remote. This is critical
  /// because the local cache may have substantial guest-mode data (e.g. 700
  /// stickers marked before sign-in) that isn't in Firestore yet — replacing
  /// state with a smaller remote would be data loss.
  ///
  /// **Subsequent emissions:** Firestore is the source of truth. They're
  /// either real-time updates from another device or our own write echoing
  /// back; either way, we mirror remote into state.
  void _subscribeToFirestore() {
    _sub = _doc.snapshots(includeMetadataChanges: false).listen((snap) {
      // Parse remote (empty map if doc doesn't exist yet or malformed).
      final remote = <String, int>{};
      if (snap.exists) {
        final rawCounts = snap.data()?['counts'];
        if (rawCounts is Map) {
          rawCounts.forEach((k, v) {
            if (k is String && v is num) remote[k] = v.toInt();
          });
        }
      }

      if (_firstEmission) {
        _firstEmission = false;
        _mergeAndMaybeUpload(remote);
      } else {
        if (!_mapEquals(remote, state)) {
          state = remote;
          unawaited(_persistLocal());
        }
      }
    }, onError: (Object e, StackTrace st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Firestore collection subscription error: $e');
      }
    });
  }

  /// Merge local state with [remote] using max-wins per sticker. Apply the
  /// merged map to state + local cache, and if it differs from remote, push
  /// the merged map to Firestore so the cloud catches up.
  void _mergeAndMaybeUpload(Map<String, int> remote) {
    final merged = <String, int>{...state};
    for (final entry in remote.entries) {
      if ((merged[entry.key] ?? 0) < entry.value) {
        merged[entry.key] = entry.value;
      }
    }
    state = merged;
    unawaited(_persistLocal());
    if (!_mapEquals(merged, remote)) {
      unawaited(_uploadFullState(merged));
    }
  }

  /// Overwrites the user's collection doc with the given counts.
  /// Used on initial merge when local has data the cloud doesn't.
  Future<void> _uploadFullState(Map<String, int> counts) async {
    if (_uid == null) return;
    try {
      await _doc.set({
        'counts': counts,
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Firestore full-state upload failed: $e');
      }
    }
  }

  bool _mapEquals(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  /// Get the owned_count for a sticker. Defaults to 0.
  int countFor(String code) => state[code] ?? 0;

  /// Set the owned_count for a sticker. Setting 0 removes the entry.
  Future<void> setCount(String code, int count) async {
    final c = count < 0 ? 0 : count;
    final next = Map<String, int>.from(state);
    if (c == 0) {
      next.remove(code);
    } else {
      next[code] = c;
    }
    state = next;
    await _persistLocal();
    await _writeRemote(code, c);
  }

  /// Increment owned_count by 1 (used by single-tap interaction).
  Future<void> increment(String code) async {
    await setCount(code, countFor(code) + 1);
  }

  /// Decrement owned_count by 1 (floor 0).
  Future<void> decrement(String code) async {
    await setCount(code, countFor(code) - 1);
  }

  /// Resets all marks for this album.
  Future<void> reset() async {
    state = {};
    await _prefs.remove(_cacheKey);
    if (_uid != null) {
      try {
        await _doc.set({
          'counts': <String, int>{},
          'last_updated': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Firestore reset failed: $e');
        }
      }
    }
  }

  /// Additive bulk mark from a page-scan result.
  ///
  /// For each code in [codesToMarkOwned]:
  ///   * if `owned_count == 0` → flip to 1.
  ///   * if `owned_count >= 1` → leave untouched (so scans never decrease counts).
  ///
  /// Returns the number of stickers that actually changed (0 → 1 flips).
  Future<int> applyAdditiveOwnedMarks(Iterable<String> codesToMarkOwned) async {
    final next = Map<String, int>.from(state);
    final changedCodes = <String>[];
    for (final code in codesToMarkOwned) {
      final current = next[code] ?? 0;
      if (current == 0) {
        next[code] = 1;
        changedCodes.add(code);
      }
    }
    if (changedCodes.isEmpty) return 0;
    state = next;
    await _persistLocal();
    if (_uid != null && changedCodes.isNotEmpty) {
      // Single Firestore call: update all changed entries + last_updated.
      final updates = <String, Object>{
        for (final code in changedCodes) 'counts.$code': 1,
        'last_updated': FieldValue.serverTimestamp(),
      };
      try {
        await _doc.set({}, SetOptions(merge: true)); // ensure doc exists
        await _doc.update(updates);
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Firestore bulk apply failed: $e');
        }
      }
    }
    return changedCodes.length;
  }

  /// Write a single sticker count to Firestore. Uses `FieldValue.delete()`
  /// for count == 0 so the document doesn't grow with zeros over time.
  Future<void> _writeRemote(String code, int count) async {
    if (_uid == null) return;
    try {
      if (count == 0) {
        // Make sure the doc exists, then delete the field.
        await _doc.set({}, SetOptions(merge: true));
        await _doc.update({
          'counts.$code': FieldValue.delete(),
          'last_updated': FieldValue.serverTimestamp(),
        });
      } else {
        await _doc.set({
          'counts': {code: count},
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Firestore write failed for $code -> $count: $e');
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// One [CollectionNotifier] per (uid, albumId).
///
/// We watch `currentUserProvider` via `.select` on `uid` so the notifier is
/// only recreated when uid actually changes (sign-in, sign-out, switching
/// accounts) — not when the User object emits other updates like
/// `displayName` change or hourly token refresh.
final collectionProvider = StateNotifierProvider.family<CollectionNotifier,
    Map<String, int>, String>((ref, albumId) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final uid = ref.watch(currentUserProvider.select((user) => user?.uid));
  return CollectionNotifier(prefs: prefs, albumId: albumId, uid: uid);
});
