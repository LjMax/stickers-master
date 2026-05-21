import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickers_master/models/sticker.dart';
import 'package:stickers_master/widgets/sticker_tile.dart';

void main() {
  Sticker makeSticker({bool isSpecial = false, String code = 'ENG2'}) {
    return Sticker(
      code: code,
      groupCode: 'ENG',
      groupNameSrLatn: 'Engleska',
      groupNameEn: 'England',
      numberInGroup: 2,
      isSpecial: isSpecial,
      sortOrder: 1,
      subcategorySrLatn: '',
      subcategoryEn: '',
      wcGroup: 'D',
    );
  }

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders the sticker code', (tester) async {
    await tester.pumpWidget(wrap(
      StickerTile(sticker: makeSticker(), ownedCount: 0, onTap: () {}),
    ));
    expect(find.text('ENG2'), findsOneWidget);
  });

  testWidgets('shows a duplicates badge when ownedCount >= 2', (tester) async {
    await tester.pumpWidget(wrap(
      StickerTile(sticker: makeSticker(), ownedCount: 3, onTap: () {}),
    ));
    // ownedCount of 3 means two duplicates beyond the first copy.
    expect(find.text('x2'), findsOneWidget);
  });

  testWidgets('shows no duplicates badge when ownedCount is below 2',
      (tester) async {
    await tester.pumpWidget(wrap(
      StickerTile(sticker: makeSticker(), ownedCount: 1, onTap: () {}),
    ));
    expect(find.textContaining('x'), findsNothing);
  });

  testWidgets('invokes onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(
      StickerTile(
        sticker: makeSticker(),
        ownedCount: 0,
        onTap: () => tapped = true,
      ),
    ));
    await tester.tap(find.byType(StickerTile));
    expect(tapped, isTrue);
  });

  testWidgets('invokes onLongPress when long-pressed', (tester) async {
    var longPressed = false;
    await tester.pumpWidget(wrap(
      StickerTile(
        sticker: makeSticker(),
        ownedCount: 0,
        onTap: () {},
        onLongPress: () => longPressed = true,
      ),
    ));
    await tester.longPress(find.byType(StickerTile));
    expect(longPressed, isTrue);
  });
}
