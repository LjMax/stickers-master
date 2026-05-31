import '../models/album.dart';
import '../models/sticker.dart';

/// One team's (or the specials group's) missing stickers, ready for the
/// missing-list screen.
class MissingTeamGroup {
  const MissingTeamGroup({
    required this.groupCode,
    required this.teamNameSrLatn,
    required this.teamNameEn,
    required this.missingCodes,
    required this.isSpecial,
  });

  /// FIFA team code (`ENG`, `SUI`, …) or `FWC` for the specials section.
  final String groupCode;
  final String teamNameSrLatn;
  final String teamNameEn;

  /// Sticker codes the user is missing in this group, in album order.
  final List<String> missingCodes;

  /// True for the FWC specials block and the lone "00" cover sticker.
  /// The UI puts these at the bottom and the flag widget renders a
  /// neutral pill rather than a country flag.
  final bool isSpecial;
}

/// Compute the missing-stickers list grouped by team for the
/// "Prikaži šta mi fali / Show what I'm missing" screen.
///
/// The grouping follows the album's own [Sticker.sortOrder], so groups
/// are returned in the same order as they appear in the album browse
/// view (specials first per the data, then teams in WC group order).
/// Within each group the codes are listed in album order too.
///
/// Groups whose every sticker is owned are dropped entirely — the
/// screen should look short and focused once you're 90% complete,
/// not a sea of empty headers.
List<MissingTeamGroup> buildMissingGroups(
  Album album,
  Map<String, int> counts,
) {
  // Preserve discovery order: stickers come pre-sorted by sortOrder
  // (Album.fromJson sorts on load), and we iterate them once.
  final groups = <String, _GroupBuilder>{};
  final order = <String>[]; // groupCode discovery order

  for (final s in album.stickers) {
    final owned = (counts[s.code] ?? 0) >= 1;
    if (owned) continue;
    final b = groups.putIfAbsent(s.groupCode, () {
      order.add(s.groupCode);
      return _GroupBuilder(
        groupCode: s.groupCode,
        teamNameSrLatn: s.groupNameSrLatn,
        teamNameEn: s.groupNameEn,
        isSpecial: s.isSpecial,
      );
    });
    b.missingCodes.add(s.code);
  }

  return order
      .map((code) => groups[code]!.build())
      .toList(growable: false);
}

class _GroupBuilder {
  _GroupBuilder({
    required this.groupCode,
    required this.teamNameSrLatn,
    required this.teamNameEn,
    required this.isSpecial,
  });

  final String groupCode;
  final String teamNameSrLatn;
  final String teamNameEn;
  final bool isSpecial;
  final List<String> missingCodes = [];

  MissingTeamGroup build() => MissingTeamGroup(
        groupCode: groupCode,
        teamNameSrLatn: teamNameSrLatn,
        teamNameEn: teamNameEn,
        missingCodes: List.unmodifiable(missingCodes),
        isSpecial: isSpecial,
      );
}

/// Render the missing groups as plain text suitable for copying or
/// sharing — one team per line, codes comma-separated:
///
/// ```
/// England: ENG2, ENG7, ENG13
/// Brazil: BRA4, BRA9
/// Special stickers: FWC1, FWC3
/// ```
///
/// [useSerbian] picks which group label to use; the codes themselves
/// are language-neutral.
String formatMissingAsText(
  List<MissingTeamGroup> groups, {
  required bool useSerbian,
}) {
  if (groups.isEmpty) return '';
  final buf = StringBuffer();
  for (final g in groups) {
    final label = useSerbian ? g.teamNameSrLatn : g.teamNameEn;
    final header = label.isEmpty ? g.groupCode : label;
    buf.writeln('$header: ${g.missingCodes.join(', ')}');
  }
  return buf.toString().trimRight();
}
