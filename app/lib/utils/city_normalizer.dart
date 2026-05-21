/// Canonicalises a free-form city string so that variants typed by
/// different users still match each other.
///
/// Three pipeline steps:
///   1. Cyrillic Serbian → Latin Serbian (`Пожаревац` → `Požarevac`).
///   2. Latin diacritics stripped to ASCII (`Požarevac` → `Pozarevac`).
///   3. Lowercase + whitespace collapsed.
///
/// Result: `"Požarevac"`, `"Pozarevac"`, and `"Пожаревац"` all map to
/// `"pozarevac"`. Same for `"Beograd"` / `"Београд"` → `"beograd"`,
/// `"Niš"` / `"Ниш"` / `"Nis"` → `"nis"`, etc.
///
/// Used by [SwapRepository] when writing `public_profiles/{uid}.city_normalized`
/// and when querying for swap partners by city.
class CityNormalizer {
  CityNormalizer._();

  /// Serbian Cyrillic → Serbian Latin. Both Vuk (vowel-following) and the
  /// digraph letters (Lj, Nj, Dž) are covered. Diacritics survive this step
  /// — they're stripped in the next.
  static const Map<String, String> _cyrillicToLatin = {
    'А': 'A', 'а': 'a',
    'Б': 'B', 'б': 'b',
    'В': 'V', 'в': 'v',
    'Г': 'G', 'г': 'g',
    'Д': 'D', 'д': 'd',
    'Ђ': 'Đ', 'ђ': 'đ',
    'Е': 'E', 'е': 'e',
    'Ж': 'Ž', 'ж': 'ž',
    'З': 'Z', 'з': 'z',
    'И': 'I', 'и': 'i',
    'Ј': 'J', 'ј': 'j',
    'К': 'K', 'к': 'k',
    'Л': 'L', 'л': 'l',
    'Љ': 'Lj', 'љ': 'lj',
    'М': 'M', 'м': 'm',
    'Н': 'N', 'н': 'n',
    'Њ': 'Nj', 'њ': 'nj',
    'О': 'O', 'о': 'o',
    'П': 'P', 'п': 'p',
    'Р': 'R', 'р': 'r',
    'С': 'S', 'с': 's',
    'Т': 'T', 'т': 't',
    'Ћ': 'Ć', 'ћ': 'ć',
    'У': 'U', 'у': 'u',
    'Ф': 'F', 'ф': 'f',
    'Х': 'H', 'х': 'h',
    'Ц': 'C', 'ц': 'c',
    'Ч': 'Č', 'ч': 'č',
    'Џ': 'Dž', 'џ': 'dž',
    'Ш': 'Š', 'ш': 'š',
  };

  /// Diacritic → plain ASCII. Covers Serbian Latin first (the main use
  /// case) plus a few common Western European diacritics so foreign city
  /// names also normalise sensibly.
  static const Map<String, String> _diacriticToAscii = {
    'č': 'c', 'Č': 'C',
    'ć': 'c', 'Ć': 'C',
    'đ': 'd', 'Đ': 'D',
    'š': 's', 'Š': 'S',
    'ž': 'z', 'Ž': 'Z',
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
    'ñ': 'n', 'Ñ': 'N',
    'ç': 'c', 'Ç': 'C',
    'ß': 'ss',
  };

  /// Returns the canonical lowercase ASCII form of [input], suitable for
  /// indexing in Firestore. Empty input → empty string.
  static String normalize(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    final cyrToLat = StringBuffer();
    for (final ch in trimmed.split('')) {
      cyrToLat.write(_cyrillicToLatin[ch] ?? ch);
    }

    final stripped = StringBuffer();
    for (final ch in cyrToLat.toString().split('')) {
      stripped.write(_diacriticToAscii[ch] ?? ch);
    }

    return stripped
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
