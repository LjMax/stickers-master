import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickers_master/l10n/app_localizations.dart';
import 'package:stickers_master/providers/filter_provider.dart';
import 'package:stickers_master/widgets/filter_chip_row.dart';

void main() {
  // The chip order in FilterChipRow: all, missing, have, duplicates, foils.
  MaterialApp app(Widget home) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      );

  testWidgets('renders all five filter chips', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: app(const Scaffold(body: FilterChipRow())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNWidgets(5));
  });

  testWidgets('tapping a chip sets the filter, tapping it again clears it',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: app(const Scaffold(body: FilterChipRow())),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(albumFilterProvider), AlbumFilter.all);

    // Index 1 is the "missing" chip.
    await tester.tap(find.byType(ChoiceChip).at(1));
    await tester.pumpAndSettle();
    expect(container.read(albumFilterProvider), AlbumFilter.missing);

    // Tapping the already-selected chip resets to "all".
    await tester.tap(find.byType(ChoiceChip).at(1));
    await tester.pumpAndSettle();
    expect(container.read(albumFilterProvider), AlbumFilter.all);
  });
}
