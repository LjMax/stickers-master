import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter mode for the album view.
enum AlbumFilter {
  /// Show every sticker (default).
  all,

  /// Only stickers with owned_count == 0.
  missing,

  /// Only stickers with owned_count >= 1.
  have,

  /// Only stickers with owned_count >= 2 (have plus extras).
  duplicates,

  /// Only foil/special stickers, regardless of owned_count.
  foils,
}

extension AlbumFilterMatch on AlbumFilter {
  bool matches({required bool isSpecial, required int ownedCount}) {
    switch (this) {
      case AlbumFilter.all:
        return true;
      case AlbumFilter.missing:
        return ownedCount == 0;
      case AlbumFilter.have:
        return ownedCount >= 1;
      case AlbumFilter.duplicates:
        return ownedCount >= 2;
      case AlbumFilter.foils:
        return isSpecial;
    }
  }
}

final albumFilterProvider =
    StateProvider<AlbumFilter>((ref) => AlbumFilter.all);
