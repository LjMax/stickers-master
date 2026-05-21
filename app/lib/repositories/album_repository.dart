import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/album.dart';

/// Loads the bundled album definition from `assets/data/stickers.json`.
///
/// In Phase 1 there's only one album. Phase 2+ will fetch a list of albums
/// from Firestore and stream collection state, but the bundled asset stays as
/// the offline-first fallback for the FIFA WC 2026 album.
class AlbumRepository {
  static const String _assetPath = 'assets/data/stickers.json';

  Future<Album> loadFifa2026() async {
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return Album.fromJson(json);
  }
}
