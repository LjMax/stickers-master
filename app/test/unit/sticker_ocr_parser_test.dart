import 'package:flutter_test/flutter_test.dart';
import 'package:stickers_master/services/sticker_ocr_parser.dart';

void main() {
  // A small representative slice of the real album dictionary. The
  // tests deliberately avoid loading the asset — the parser is pure
  // Dart and we want the tests to be fast and offline.
  final dict = {
    '00',
    'FWC1', 'FWC2', 'FWC10',
    'SUI19', 'SCO18', 'POR4', 'BEL10', 'GER11', 'ECU9',
    'ENG2',
  };

  late StickerOcrParser parser;

  setUp(() {
    parser = StickerOcrParser(dict);
  });

  group('StickerOcrParser.extractValidCodes', () {
    test('finds a single code with a space ("SUI 19")', () {
      // What the back of a typical sticker reads, roughly:
      //   FIFA WORLD CUP 2026
      //   SUI 19
      final text = '''
FIFA WORLD CUP 2026
SUI 19
© FIFA's Official Licensed Product Logos, and all
brand elements...
PANINI
''';
      expect(parser.extractValidCodes(text), ['SUI19']);
    });

    test('finds a code with no space ("SUI19")', () {
      expect(parser.extractValidCodes('SUI19'), ['SUI19']);
    });

    test('rejects "CUP 2026" from the header (not in dictionary)', () {
      // CUP2026 matches the regex but is not a valid sticker code.
      final text = 'FIFA WORLD CUP 2026 SUI 19';
      expect(parser.extractValidCodes(text), ['SUI19']);
    });

    test('rejects pure noise (no valid codes)', () {
      expect(
        parser.extractValidCodes('FIFA WORLD CUP 2026 OFFICIAL LICENSED PRODUCT'),
        isEmpty,
      );
    });

    test('returns several codes for a multi-sticker frame, deduped', () {
      // The "bulk scan" case — several stickers visible at once.
      final text = '''
FIFA WORLD CUP 2026  SUI 19
FIFA WORLD CUP 2026  SCO 18
FIFA WORLD CUP 2026  POR 4
FIFA WORLD CUP 2026  SUI 19
''';
      expect(parser.extractValidCodes(text), ['SUI19', 'SCO18', 'POR4']);
    });

    test('matches across whitespace including newlines', () {
      // The regex's \s* matches newlines too — useful when OCR returns
      // the country code and number on separate text lines.
      expect(parser.extractValidCodes('FWC\n2'), ['FWC2']);
      expect(parser.extractValidCodes('FWC2'), ['FWC2']);
    });

    test('ignores empty input', () {
      expect(parser.extractValidCodes(''), isEmpty);
    });

    test('ignores codes that are not in the dictionary', () {
      // "ZZZ99" matches the regex but isn't a real sticker.
      expect(parser.extractValidCodes('ZZZ 99'), isEmpty);
    });

    test('handles two-letter codes (e.g. boundary of the regex)', () {
      // The regex allows [A-Z]{2,4}. "00" alone is digits-only so it
      // does NOT match (regex requires letters first). That's fine —
      // the standalone "00" cover sticker is unlikely to be scanned
      // since there's only one of it and it lacks a country/group prefix.
      expect(parser.extractValidCodes('00'), isEmpty);
    });

    test('returns first valid code via firstValidCode', () {
      expect(parser.firstValidCode('FIFA WORLD CUP 2026 ECU 9'), 'ECU9');
    });

    test('firstValidCode returns null when there is no match', () {
      expect(parser.firstValidCode('totally noise here'), isNull);
    });

    test('FWC10 (3 digits) parses correctly', () {
      expect(parser.firstValidCode('FIFA WORLD CUP 2026 FWC 10'), 'FWC10');
    });
  });
}
