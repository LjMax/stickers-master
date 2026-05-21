import 'sticker.dart';

/// Static album definition, loaded once at startup from a bundled asset.
class Album {
  const Album({
    required this.id,
    required this.nameSrLatn,
    required this.nameEn,
    required this.publisher,
    required this.year,
    required this.totalStickers,
    required this.foilCount,
    required this.teamCount,
    required this.stickers,
    required this.wcGroups,
  });

  final String id;
  final String nameSrLatn;
  final String nameEn;
  final String publisher;
  final int year;
  final int totalStickers;
  final int foilCount;
  final int teamCount;

  /// All stickers in sorted [Sticker.sortOrder] order.
  final List<Sticker> stickers;

  /// WC group definitions in album order (A → L). Empty for albums that
  /// aren't tournament-themed.
  final List<WcGroup> wcGroups;

  factory Album.fromJson(Map<String, dynamic> json) {
    final albumMeta = json['album'] as Map<String, dynamic>;
    final stickerList = (json['stickers'] as List)
        .map((e) => Sticker.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final wcGroupsRaw = albumMeta['wc_groups'] as List? ?? const [];
    final wcGroups = wcGroupsRaw
        .map((g) => WcGroup.fromJson(g as Map<String, dynamic>))
        .toList();

    return Album(
      id: albumMeta['id'] as String,
      nameSrLatn: albumMeta['name_sr_latn'] as String,
      nameEn: albumMeta['name_en'] as String,
      publisher: albumMeta['publisher'] as String,
      year: albumMeta['year'] as int,
      totalStickers: albumMeta['total_stickers'] as int,
      foilCount: albumMeta['foil_count'] as int,
      teamCount: albumMeta['team_count'] as int,
      stickers: stickerList,
      wcGroups: wcGroups,
    );
  }

  /// Groups stickers by [Sticker.groupCode] preserving sort order.
  Map<String, List<Sticker>> get stickersByGroup {
    final map = <String, List<Sticker>>{};
    for (final s in stickers) {
      map.putIfAbsent(s.groupCode, () => []).add(s);
    }
    return map;
  }
}

/// One World Cup group (e.g. Group A with 4 team codes).
class WcGroup {
  const WcGroup({required this.letter, required this.teamCodes});

  /// `A`, `B`, …, `L`.
  final String letter;

  /// 4 FIFA 3-letter team codes, in the drawn order.
  final List<String> teamCodes;

  factory WcGroup.fromJson(Map<String, dynamic> json) {
    return WcGroup(
      letter: json['letter'] as String,
      teamCodes: (json['team_codes'] as List).cast<String>(),
    );
  }
}
