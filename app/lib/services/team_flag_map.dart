/// Maps FIFA 3-letter team codes (as used in `stickers.json`) to the
/// country code expected by the `country_flags` package.
///
/// `country_flags` uses ISO 3166-1 alpha-2 (lowercase). For the four UK
/// home nations — which aren't ISO countries — it accepts the special
/// hyphenated codes `gb-eng`, `gb-sct`, `gb-wls`, `gb-nir`.
///
/// Returns `null` for codes not in the album (e.g. the FWC specials
/// group code, or anything misspelled). Callers should fall back to a
/// neutral pill rather than crashing.
String? fifaToFlagCode(String fifaCode) {
  return _fifaToIso[fifaCode.toUpperCase()];
}

const Map<String, String> _fifaToIso = {
  // Africa
  'ALG': 'dz',       // Algeria
  'CIV': 'ci',       // Côte d'Ivoire
  'COD': 'cd',       // DR Congo
  'CPV': 'cv',       // Cape Verde
  'EGY': 'eg',       // Egypt
  'GHA': 'gh',       // Ghana
  'MAR': 'ma',       // Morocco
  'RSA': 'za',       // South Africa
  'SEN': 'sn',       // Senegal
  'TUN': 'tn',       // Tunisia

  // Asia
  'AUS': 'au',       // Australia (AFC member)
  'IRN': 'ir',       // Iran
  'IRQ': 'iq',       // Iraq
  'JOR': 'jo',       // Jordan
  'JPN': 'jp',       // Japan
  'KOR': 'kr',       // South Korea
  'KSA': 'sa',       // Saudi Arabia
  'QAT': 'qa',       // Qatar
  'UZB': 'uz',       // Uzbekistan

  // Concacaf
  'CAN': 'ca',       // Canada
  'CUW': 'cw',       // Curaçao
  'HAI': 'ht',       // Haiti
  'MEX': 'mx',       // Mexico
  'PAN': 'pa',       // Panama
  'USA': 'us',       // USA

  // Conmebol
  'ARG': 'ar',       // Argentina
  'BRA': 'br',       // Brazil
  'COL': 'co',       // Colombia
  'ECU': 'ec',       // Ecuador
  'PAR': 'py',       // Paraguay
  'URU': 'uy',       // Uruguay

  // Oceania
  'NZL': 'nz',       // New Zealand

  // Europe (UEFA)
  'AUT': 'at',       // Austria
  'BEL': 'be',       // Belgium
  'BIH': 'ba',       // Bosnia and Herzegovina
  'CRO': 'hr',       // Croatia
  'CZE': 'cz',       // Czech Republic
  'ENG': 'gb-eng',   // England (home nation)
  'ESP': 'es',       // Spain
  'FRA': 'fr',       // France
  'GER': 'de',       // Germany
  'NED': 'nl',       // Netherlands
  'NOR': 'no',       // Norway
  'POR': 'pt',       // Portugal
  'SCO': 'gb-sct',   // Scotland (home nation)
  'SUI': 'ch',       // Switzerland
  'SWE': 'se',       // Sweden
  'TUR': 'tr',       // Turkey
};
