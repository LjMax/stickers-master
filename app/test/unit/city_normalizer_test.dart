import 'package:flutter_test/flutter_test.dart';
import 'package:stickers_master/utils/city_normalizer.dart';

void main() {
  group('CityNormalizer.normalize', () {
    test('empty or whitespace-only input returns an empty string', () {
      expect(CityNormalizer.normalize(''), '');
      expect(CityNormalizer.normalize('   '), '');
    });

    test('trims and lowercases', () {
      expect(CityNormalizer.normalize('  Beograd  '), 'beograd');
    });

    test('collapses internal whitespace runs to a single space', () {
      expect(CityNormalizer.normalize('Novi   Sad'), 'novi sad');
    });

    test('strips Serbian Latin diacritics', () {
      expect(CityNormalizer.normalize('Niš'), 'nis');
      expect(CityNormalizer.normalize('Požarevac'), 'pozarevac');
      expect(CityNormalizer.normalize('Čačak'), 'cacak');
    });

    test('converts Serbian Cyrillic to Latin', () {
      expect(CityNormalizer.normalize('Београд'), 'beograd');
      expect(CityNormalizer.normalize('Пожаревац'), 'pozarevac');
      expect(CityNormalizer.normalize('Ниш'), 'nis');
    });

    test('Latin, ASCII and Cyrillic spellings of a city all converge', () {
      final n = CityNormalizer.normalize('Požarevac');
      expect(n, 'pozarevac');
      expect(CityNormalizer.normalize('Pozarevac'), n);
      expect(CityNormalizer.normalize('Пожаревац'), n);
    });

    test('handles Cyrillic digraph letters (Lj, Nj, Dž)', () {
      expect(CityNormalizer.normalize('Љубовија'), 'ljubovija');
    });

    test('strips common Western European diacritics', () {
      expect(CityNormalizer.normalize('Málaga'), 'malaga');
      expect(CityNormalizer.normalize('Zürich'), 'zurich');
    });
  });
}
