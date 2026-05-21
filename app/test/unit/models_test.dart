import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickers_master/models/album.dart';
import 'package:stickers_master/models/public_profile.dart';
import 'package:stickers_master/models/sticker.dart';
import 'package:stickers_master/providers/locale_provider.dart';

void main() {
  group('Sticker.fromJson', () {
    test('parses a full sticker', () {
      final s = Sticker.fromJson({
        'code': 'ENG2',
        'group_code': 'ENG',
        'group_name_sr_latn': 'Engleska',
        'group_name_en': 'England',
        'number_in_group': 2,
        'is_special': false,
        'sort_order': 312,
        'subcategory_sr_latn': 'Igrač',
        'subcategory_en': 'Player',
        'wc_group': 'D',
      });
      expect(s.code, 'ENG2');
      expect(s.groupCode, 'ENG');
      expect(s.isSpecial, isFalse);
      expect(s.wcGroup, 'D');
    });

    test('tolerates missing optional subcategory and wc_group fields', () {
      final s = Sticker.fromJson({
        'code': '00',
        'group_code': 'FWC',
        'group_name_sr_latn': '',
        'group_name_en': '',
        'number_in_group': 0,
        'is_special': true,
        'sort_order': 0,
      });
      expect(s.subcategoryEn, '');
      expect(s.subcategorySrLatn, '');
      expect(s.wcGroup, isNull);
      expect(s.isSpecial, isTrue);
    });
  });

  group('Album.fromJson', () {
    Map<String, dynamic> albumJson() => {
          'album': {
            'id': 'panini-fifa-world-cup-2026',
            'name_sr_latn': 'Panini SP 2026',
            'name_en': 'Panini WC 2026',
            'publisher': 'Panini',
            'year': 2026,
            'total_stickers': 3,
            'foil_count': 1,
            'team_count': 1,
            'wc_groups': [
              {
                'letter': 'A',
                'team_codes': ['MEX', 'RSA'],
              },
            ],
          },
          'stickers': [
            {
              'code': 'ENG2',
              'group_code': 'ENG',
              'group_name_sr_latn': 'Engleska',
              'group_name_en': 'England',
              'number_in_group': 2,
              'is_special': false,
              'sort_order': 30,
            },
            {
              'code': '00',
              'group_code': 'FWC',
              'group_name_sr_latn': '',
              'group_name_en': '',
              'number_in_group': 0,
              'is_special': true,
              'sort_order': 1,
            },
            {
              'code': 'ENG1',
              'group_code': 'ENG',
              'group_name_sr_latn': 'Engleska',
              'group_name_en': 'England',
              'number_in_group': 1,
              'is_special': true,
              'sort_order': 29,
            },
          ],
        };

    test('parses album metadata and WC groups', () {
      final album = Album.fromJson(albumJson());
      expect(album.id, 'panini-fifa-world-cup-2026');
      expect(album.year, 2026);
      expect(album.totalStickers, 3);
      expect(album.wcGroups.single.letter, 'A');
      expect(album.wcGroups.single.teamCodes, ['MEX', 'RSA']);
    });

    test('stickers are sorted by sortOrder', () {
      final album = Album.fromJson(albumJson());
      expect(
        album.stickers.map((s) => s.code).toList(),
        ['00', 'ENG1', 'ENG2'],
      );
    });

    test('stickersByGroup buckets by groupCode preserving sort order', () {
      final groups = Album.fromJson(albumJson()).stickersByGroup;
      expect(groups.keys, containsAll(<String>['FWC', 'ENG']));
      expect(groups['FWC']!.map((s) => s.code).toList(), ['00']);
      expect(groups['ENG']!.map((s) => s.code).toList(), ['ENG1', 'ENG2']);
    });
  });

  group('PublicProfile.fromJson', () {
    test('parses all fields', () {
      final p = PublicProfile.fromJson('uid1', {
        'display_name': 'Lj',
        'city': 'Požarevac',
        'country': 'Srbija',
        'photo_url': 'http://x/p.png',
      });
      expect(p.uid, 'uid1');
      expect(p.displayName, 'Lj');
      expect(p.city, 'Požarevac');
      expect(p.country, 'Srbija');
      expect(p.photoUrl, 'http://x/p.png');
    });

    test('defaults missing fields to empty strings / null', () {
      final p = PublicProfile.fromJson('uid2', {});
      expect(p.displayName, '');
      expect(p.city, '');
      expect(p.country, '');
      expect(p.photoUrl, isNull);
    });
  });

  group('pickLocalized', () {
    test('returns the English value for an English locale', () {
      expect(
        pickLocalized(const Locale('en'), 'srpski', 'english'),
        'english',
      );
    });

    test('returns the Serbian value for the sr-Latn locale', () {
      const sr = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');
      expect(pickLocalized(sr, 'srpski', 'english'), 'srpski');
    });
  });
}
