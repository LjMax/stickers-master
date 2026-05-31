import 'package:flutter_test/flutter_test.dart';
import 'package:stickers_master/models/album.dart';
import 'package:stickers_master/models/sticker.dart';
import 'package:stickers_master/services/missing_list_builder.dart';

void main() {
  // Helpers — build a fixed-shape Sticker without writing out every
  // field on every call.
  Sticker mk({
    required String code,
    required String group,
    required String groupNameSr,
    required String groupNameEn,
    required int number,
    required int order,
    bool isSpecial = false,
  }) =>
      Sticker(
        code: code,
        groupCode: group,
        groupNameSrLatn: groupNameSr,
        groupNameEn: groupNameEn,
        numberInGroup: number,
        isSpecial: isSpecial,
        sortOrder: order,
        subcategorySrLatn: '',
        subcategoryEn: '',
        wcGroup: isSpecial ? null : 'A',
      );

  Album mkAlbum(List<Sticker> stickers) => Album(
        id: 'panini-fifa-world-cup-2026',
        nameSrLatn: 'Panini',
        nameEn: 'Panini',
        publisher: 'Panini',
        year: 2026,
        totalStickers: stickers.length,
        foilCount: 0,
        teamCount: 0,
        stickers: stickers,
        wcGroups: const [],
      );

  // A tiny fake album: two teams + one specials group.
  final album = mkAlbum([
    mk(code: '00', group: 'FWC', groupNameSr: 'Specijalne',
       groupNameEn: 'Specials', number: 0, order: 0, isSpecial: true),
    mk(code: 'FWC1', group: 'FWC', groupNameSr: 'Specijalne',
       groupNameEn: 'Specials', number: 1, order: 1, isSpecial: true),
    mk(code: 'FWC2', group: 'FWC', groupNameSr: 'Specijalne',
       groupNameEn: 'Specials', number: 2, order: 2, isSpecial: true),
    mk(code: 'ENG1', group: 'ENG', groupNameSr: 'Engleska',
       groupNameEn: 'England', number: 1, order: 10),
    mk(code: 'ENG2', group: 'ENG', groupNameSr: 'Engleska',
       groupNameEn: 'England', number: 2, order: 11),
    mk(code: 'ENG13', group: 'ENG', groupNameSr: 'Engleska',
       groupNameEn: 'England', number: 13, order: 12),
    mk(code: 'SUI1', group: 'SUI', groupNameSr: 'Švajcarska',
       groupNameEn: 'Switzerland', number: 1, order: 20),
    mk(code: 'SUI19', group: 'SUI', groupNameSr: 'Švajcarska',
       groupNameEn: 'Switzerland', number: 19, order: 21),
  ]);

  group('buildMissingGroups', () {
    test('empty counts → every sticker missing, all groups appear', () {
      final groups = buildMissingGroups(album, const {});
      expect(groups.map((g) => g.groupCode).toList(),
          ['FWC', 'ENG', 'SUI']);
      expect(groups[0].missingCodes, ['00', 'FWC1', 'FWC2']);
      expect(groups[1].missingCodes, ['ENG1', 'ENG2', 'ENG13']);
      expect(groups[2].missingCodes, ['SUI1', 'SUI19']);
    });

    test('only some missing → only those codes show up', () {
      final counts = {
        '00': 1, 'FWC1': 1, 'FWC2': 2,           // specials all owned
        'ENG1': 1,                                 // ENG1 owned
        // ENG2, ENG13 still missing
        'SUI1': 2, 'SUI19': 1,                    // SUI all owned
      };
      final groups = buildMissingGroups(album, counts);
      expect(groups.length, 1);
      expect(groups.first.groupCode, 'ENG');
      expect(groups.first.missingCodes, ['ENG2', 'ENG13']);
    });

    test('groups with everything owned are dropped from the list', () {
      // Own every special and every Switzerland sticker; only ENG
      // missing entirely.
      final counts = {
        '00': 1, 'FWC1': 1, 'FWC2': 1,
        'SUI1': 1, 'SUI19': 1,
      };
      final groups = buildMissingGroups(album, counts);
      expect(groups.map((g) => g.groupCode).toList(), ['ENG']);
      expect(groups.first.missingCodes, ['ENG1', 'ENG2', 'ENG13']);
    });

    test('group order follows album sortOrder (specials → teams)', () {
      final counts = {'ENG1': 1};
      final groups = buildMissingGroups(album, counts);
      expect(groups.map((g) => g.groupCode).toList(),
          ['FWC', 'ENG', 'SUI']);
    });

    test('per-group codes preserve album order', () {
      // ENG1 is at sortOrder 10, ENG13 at 12 — must appear in that order,
      // not sorted alphabetically (which would put ENG13 before ENG2).
      final groups = buildMissingGroups(album, const {});
      final eng = groups.firstWhere((g) => g.groupCode == 'ENG');
      expect(eng.missingCodes, ['ENG1', 'ENG2', 'ENG13']);
    });

    test('complete album → no groups', () {
      final counts = {
        for (final s in album.stickers) s.code: 1,
      };
      expect(buildMissingGroups(album, counts), isEmpty);
    });

    test('isSpecial flag is preserved from the underlying stickers', () {
      final groups = buildMissingGroups(album, const {});
      final fwc = groups.firstWhere((g) => g.groupCode == 'FWC');
      final eng = groups.firstWhere((g) => g.groupCode == 'ENG');
      expect(fwc.isSpecial, isTrue);
      expect(eng.isSpecial, isFalse);
    });
  });

  group('formatMissingAsText', () {
    test('formats groups into team: code, code, code lines (English)', () {
      final groups = buildMissingGroups(album, const {'ENG1': 1, 'SUI1': 1});
      final text = formatMissingAsText(groups, useSerbian: false);
      expect(text, contains('Specials: 00, FWC1, FWC2'));
      expect(text, contains('England: ENG2, ENG13'));
      expect(text, contains('Switzerland: SUI19'));
    });

    test('uses Serbian labels when useSerbian: true', () {
      final groups = buildMissingGroups(album, const {});
      final text = formatMissingAsText(groups, useSerbian: true);
      expect(text, contains('Engleska: ENG1, ENG2, ENG13'));
      expect(text, contains('Švajcarska: SUI1, SUI19'));
    });

    test('empty group list yields empty string', () {
      expect(formatMissingAsText(const [], useSerbian: false), '');
    });
  });
}
