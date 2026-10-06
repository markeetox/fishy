import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/core/home_shell_screen.dart';
import 'package:seabound/core/app_theme.dart';

void main() {
  testWidgets('HomeShellScreen renders bottom navigation strip and 5 item buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeShellScreen(initialTab: 2),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    expect(find.byIcon(Icons.place_outlined), findsOneWidget);
    expect(find.byIcon(Icons.anchor_rounded), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('HomeShellScreen switches active tab when bottom nav button is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeShellScreen(initialTab: 2),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially Home tab (tab index 2)
    expect(find.text('Seabound'), findsOneWidget);

    // Tap Trips tab (tab index 0)
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    // Verify Trips Screen title is shown
    expect(find.text('My Trips'), findsOneWidget);
  });
}
