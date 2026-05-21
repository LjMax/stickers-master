import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/album.dart';
import '../repositories/album_repository.dart';

final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  return AlbumRepository();
});

/// The active album. Phase 1 hard-codes the FIFA WC 2026 album.
final albumProvider = FutureProvider<Album>((ref) async {
  final repo = ref.watch(albumRepositoryProvider);
  return repo.loadFifa2026();
});
