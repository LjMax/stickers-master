import 'package:flutter_test/flutter_test.dart';
import 'package:stickers_master/providers/filter_provider.dart';

void main() {
  group('AlbumFilter.matches', () {
    test('all matches every sticker', () {
      expect(AlbumFilter.all.matches(isSpecial: false, ownedCount: 0), isTrue);
      expect(AlbumFilter.all.matches(isSpecial: true, ownedCount: 5), isTrue);
    });

    test('missing matches only owned_count == 0', () {
      expect(
          AlbumFilter.missing.matches(isSpecial: false, ownedCount: 0), isTrue);
      expect(
          AlbumFilter.missing.matches(isSpecial: false, ownedCount: 1), isFalse);
      expect(
          AlbumFilter.missing.matches(isSpecial: true, ownedCount: 2), isFalse);
    });

    test('have matches owned_count >= 1', () {
      expect(AlbumFilter.have.matches(isSpecial: false, ownedCount: 0), isFalse);
      expect(AlbumFilter.have.matches(isSpecial: false, ownedCount: 1), isTrue);
      expect(AlbumFilter.have.matches(isSpecial: false, ownedCount: 3), isTrue);
    });

    test('duplicates matches owned_count >= 2', () {
      expect(
          AlbumFilter.duplicates.matches(isSpecial: false, ownedCount: 1),
          isFalse);
      expect(
          AlbumFilter.duplicates.matches(isSpecial: false, ownedCount: 2),
          isTrue);
    });

    test('foils matches special stickers regardless of owned count', () {
      expect(AlbumFilter.foils.matches(isSpecial: true, ownedCount: 0), isTrue);
      expect(
          AlbumFilter.foils.matches(isSpecial: false, ownedCount: 9), isFalse);
    });
  });
}
