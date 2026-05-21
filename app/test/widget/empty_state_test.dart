import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickers_master/widgets/empty_state.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows the icon and title', (tester) async {
    await tester.pumpWidget(wrap(
      const EmptyState(icon: Icons.inbox, title: 'Nothing here yet'),
    ));
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.byIcon(Icons.inbox), findsOneWidget);
  });

  testWidgets('shows the optional message when provided', (tester) async {
    await tester.pumpWidget(wrap(
      const EmptyState(
        icon: Icons.inbox,
        title: 'Title',
        message: 'A helpful hint',
      ),
    ));
    expect(find.text('A helpful hint'), findsOneWidget);
  });

  testWidgets('renders the optional action widget', (tester) async {
    await tester.pumpWidget(wrap(
      EmptyState(
        icon: Icons.inbox,
        title: 'Title',
        action: FilledButton(
          onPressed: () {},
          child: const Text('Do something'),
        ),
      ),
    ));
    expect(find.text('Do something'), findsOneWidget);
  });
}
