import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/public_profile.dart';
import '../utils/city_normalizer.dart';

/// All Firestore reads/writes for the swap area.
class SwapRepository {
  SwapRepository(this._db);

  final FirebaseFirestore _db;

  // ----- Public profile CRUD ------------------------------------------------

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) =>
      _db.doc('public_profiles/$uid');

  /// Watch my own public profile (or null if not yet created).
  ///
  /// Side effects, all non-blocking:
  ///
  /// 1. **`city_normalized` + `country_normalized` migration** — older docs
  ///    may lack the diacritic-stripped/Cyrillic-folded fields. If stored
  ///    value differs from `CityNormalizer.normalize(...)`, we write it back.
  /// 2. **Auth → profile sync** — keep `photo_url` and `display_name` in
  ///    line with what Firebase Auth knows about the user, so the swap
  ///    area and chat avatars reflect the user's current Google avatar
  ///    without an explicit "save" step.
  ///    - `photo_url` is always synced from `auth.user.photoURL` when it
  ///      differs (Google profile picture changed → it propagates).
  ///    - `display_name` is only filled IF the existing one is empty.
  ///      We never override a custom name the user typed in the editor.
  Stream<PublicProfile?> watchMyProfile(String uid) {
    return _profileDoc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data() ?? const <String, dynamic>{};
      final profile = PublicProfile.fromJson(uid, data);

      final updates = <String, dynamic>{};

      // 1a. city_normalized migration
      final storedCity = data['city_normalized'] as String?;
      final desiredCity = CityNormalizer.normalize(profile.city);
      if (profile.city.isNotEmpty && storedCity != desiredCity) {
        updates['city_normalized'] = desiredCity;
      }

      // 1b. country_normalized migration
      final storedCountry = data['country_normalized'] as String?;
      final desiredCountry = CityNormalizer.normalize(profile.country);
      if (profile.country.isNotEmpty && storedCountry != desiredCountry) {
        updates['country_normalized'] = desiredCountry;
      }

      // 2. auth → profile sync
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null && authUser.uid == uid) {
        final authPhoto = authUser.photoURL;
        if (authPhoto != null &&
            authPhoto.isNotEmpty &&
            authPhoto != profile.photoUrl) {
          updates['photo_url'] = authPhoto;
        }
        final authName = authUser.displayName;
        if (profile.displayName.isEmpty &&
            authName != null &&
            authName.isNotEmpty) {
          updates['display_name'] = authName;
        }
      }

      if (updates.isNotEmpty) {
        // Fire-and-forget — keep the stream non-blocking.
        unawaited(_profileDoc(uid).set(updates, SetOptions(merge: true)));
      }
      return profile;
    });
  }

  /// Create or update my public profile. Writes the normalized form of
  /// the city and country alongside the user's original input.
  Future<void> upsertProfile(PublicProfile profile) async {
    await _profileDoc(profile.uid).set({
      ...profile.toJson(),
      'city_normalized': CityNormalizer.normalize(profile.city),
      'country_normalized': CityNormalizer.normalize(profile.country),
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ----- Swap index ---------------------------------------------------------

  DocumentReference<Map<String, dynamic>> _swapIndexDoc(
          String uid, String albumId) =>
      _db.doc('public_profiles/$uid/swap_indexes/$albumId');

  /// Write the user's current duplicates list for [albumId]. Overwrites the
  /// whole array — duplicates are recomputed from scratch each call.
  Future<void> updateMyDuplicates({
    required String uid,
    required String albumId,
    required List<String> duplicates,
  }) async {
    await _swapIndexDoc(uid, albumId).set({
      'duplicates': duplicates,
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  // ----- Match-finding ------------------------------------------------------

  /// Find swap partners who have duplicates I need.
  ///
  /// **Primary filter:** [country]. Always required — the swap area is
  /// scoped to a single country.
  ///
  /// **Optional narrow filter:** [city]. If non-null and non-empty,
  /// candidates are filtered client-side to only those whose normalized
  /// city matches mine. When null, the result spans the whole country.
  ///
  /// Matching is **diacritic- and script-tolerant**: country and city are
  /// normalised (Cyrillic → Latin, strip diacritics, lowercase) before
  /// comparing. So `"Srbija"`, `"Србија"` both match; `"Požarevac"`,
  /// `"Pozarevac"`, `"Пожаревац"` all match.
  ///
  /// Algorithm:
  ///   1. Query `public_profiles where country_normalized == myNormCountry`.
  ///      Also (fallback) `where country == myRawCountry` for un-migrated
  ///      profiles still missing `country_normalized`.
  ///   2. Merge the two result sets, deduped by uid, drop self.
  ///   3. If [city] is given, filter to candidates whose
  ///      `city_normalized` matches my city's normalized form (with a
  ///      raw-city fallback for un-migrated docs).
  ///   4. For each, fetch `swap_indexes/{albumId}`, intersect `duplicates`
  ///      with [myMissing] → overlap.
  ///   5. Drop matches with zero overlap; sort by overlap size desc.
  ///
  /// Trade-offs: O(N) reads where N = users in same country. Fine for
  /// tens to low-hundreds; we'd denormalize via Cloud Function later.
  Future<List<SwapMatch>> findMatches({
    required String myUid,
    required String country,
    String? city,
    required String albumId,
    required Set<String> myMissing,
    int limit = 200,
  }) async {
    if (country.trim().isEmpty || myMissing.isEmpty) return const [];

    final countryNorm = CityNormalizer.normalize(country);

    final byCountryNormFut = _db
        .collection('public_profiles')
        .where('country_normalized', isEqualTo: countryNorm)
        .limit(limit)
        .get();
    final byCountryRawFut = _db
        .collection('public_profiles')
        .where('country', isEqualTo: country)
        .limit(limit)
        .get();

    final results = await Future.wait([byCountryNormFut, byCountryRawFut]);
    final candidates =
        <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final query in results) {
      for (final doc in query.docs) {
        candidates.putIfAbsent(doc.id, () => doc);
      }
    }

    // Optional city narrowing.
    String? cityNorm;
    if (city != null && city.trim().isNotEmpty) {
      cityNorm = CityNormalizer.normalize(city);
    }

    final matches = <SwapMatch>[];
    for (final entry in candidates.entries) {
      final candidateUid = entry.key;
      final candidate = entry.value;
      if (candidateUid == myUid) continue; // skip self

      final data = candidate.data();

      // City narrow filter — fall back to normalising the raw `city`
      // field for un-migrated profiles.
      if (cityNorm != null) {
        final candidateCityNorm = (data['city_normalized'] as String?) ??
            CityNormalizer.normalize(data['city'] as String? ?? '');
        if (candidateCityNorm != cityNorm) continue;
      }

      final profile = PublicProfile.fromJson(candidateUid, data);

      final swapIndex = await _swapIndexDoc(candidateUid, albumId).get();
      if (!swapIndex.exists) continue;
      final raw = swapIndex.data()?['duplicates'];
      if (raw is! List) continue;

      final overlap = <String>[];
      for (final code in raw) {
        if (code is String && myMissing.contains(code)) {
          overlap.add(code);
        }
      }
      if (overlap.isEmpty) continue;

      overlap.sort();
      matches.add(SwapMatch(profile: profile, overlapCodes: overlap));
    }

    matches.sort((a, b) => b.overlapCount.compareTo(a.overlapCount));
    return matches;
  }
}
