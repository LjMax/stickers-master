/// A single sticker in an album. No images — identified by [code] only.
///
/// Group label is bilingual; the UI picks the right one based on the user's
/// language preference at display time.
class Sticker {
  const Sticker({
    required this.code,
    required this.groupCode,
    required this.groupNameSrLatn,
    required this.groupNameEn,
    required this.numberInGroup,
    required this.isSpecial,
    required this.sortOrder,
    required this.subcategorySrLatn,
    required this.subcategoryEn,
    required this.wcGroup,
  });

  /// Visible identifier, e.g. `ENG2`, `FWC1`, `00`.
  final String code;

  /// Group bucket, e.g. `ENG`, `FWC`. Stickers with the same [groupCode] are
  /// rendered together.
  final String groupCode;

  /// Human-readable group label, Serbian Latin.
  final String groupNameSrLatn;

  /// Human-readable group label, English.
  final String groupNameEn;

  /// Position within the group (1-based; specials start at 0 for the Panini logo).
  final int numberInGroup;

  /// Foil/special flag. Team crests (#1 of each team) and all `FWC*` + `00` are special.
  final bool isSpecial;

  /// Global sort position across the whole album.
  final int sortOrder;

  /// Subcategory label (e.g. "Player", "Team crest", "Emblems & host cities").
  final String subcategorySrLatn;
  final String subcategoryEn;

  /// World Cup group letter (`A`–`L`) for team stickers; `null` for specials.
  final String? wcGroup;

  factory Sticker.fromJson(Map<String, dynamic> json) {
    return Sticker(
      code: json['code'] as String,
      groupCode: json['group_code'] as String,
      groupNameSrLatn: json['group_name_sr_latn'] as String,
      groupNameEn: json['group_name_en'] as String,
      numberInGroup: json['number_in_group'] as int,
      isSpecial: json['is_special'] as bool,
      sortOrder: json['sort_order'] as int,
      subcategorySrLatn: json['subcategory_sr_latn'] as String? ?? '',
      subcategoryEn: json['subcategory_en'] as String? ?? '',
      wcGroup: json['wc_group'] as String?,
    );
  }
}
