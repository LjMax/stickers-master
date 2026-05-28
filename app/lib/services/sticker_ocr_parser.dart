/// Parses raw OCR text from the back of a Panini-style sticker and returns
/// the validated sticker code(s) that match the album's known dictionary.
///
/// The back of every Panini WC 2026 sticker has a header reading
///   `FIFA WORLD CUP 2026`
/// followed by a pill with `<COUNTRY CODE> <NUMBER>` (e.g. `SUI 19`,
/// `POR 4`, `FWC 1`). Codes in the album JSON have no whitespace
/// (`SUI19`, `POR4`, `FWC1`), so we normalise before lookup.
///
/// The dictionary cross-check is the crucial false-positive filter. Without
/// it the regex would also match `CUP 2026` from the header — but
/// `CUP2026` is not a real sticker code, so it's silently dropped.
///
/// Pure Dart, no Flutter imports — fully unit-testable.
class StickerOcrParser {
  /// [validCodes] is the set of every sticker code present in the loaded
  /// album (e.g. `{"00", "FWC1", "ENG2", "SUI19", ...}`). Build it once
  /// from the album asset and reuse across scans.
  StickerOcrParser(this.validCodes);

  final Set<String> validCodes;

  /// `[A-Z]{2,4}` = 2 to 4 uppercase letters (FIFA country codes are 3 but
  /// `FWC` and others also fit). `\s*` allows the optional space between
  /// the letters and digits ("SUI 19" or "SUI19"). `\d+` is the sticker
  /// number — usually 1-3 digits.
  static final RegExp _codeRegex = RegExp(r'([A-Z]{2,4})\s*(\d+)');

  /// Extract all candidate codes from [text] and return only those that
  /// exist in [validCodes]. The result is deduplicated and preserves the
  /// regex's left-to-right discovery order.
  ///
  /// For single-sticker scans the list typically has exactly one entry.
  /// Multiple entries are possible when the camera frame contains several
  /// stickers (the future bulk-scan case).
  List<String> extractValidCodes(String text) {
    if (text.isEmpty) return const [];
    final found = <String>{};
    final ordered = <String>[];
    for (final m in _codeRegex.allMatches(text)) {
      final candidate = '${m.group(1)}${m.group(2)}';
      if (validCodes.contains(candidate) && found.add(candidate)) {
        ordered.add(candidate);
      }
    }
    return ordered;
  }

  /// Convenience: the most likely single match in [text], or null if none
  /// of the candidates were in the dictionary. When the OCR sees more
  /// than one valid code, the first (by regex order) wins.
  String? firstValidCode(String text) {
    final codes = extractValidCodes(text);
    return codes.isEmpty ? null : codes.first;
  }
}
