import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seabound/core/app_bottom_nav.dart';
import 'package:seabound/core/home_shell_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  group('AppBottomNav Widget Tests', () {
    testWidgets('default state shows only single centered Home button',
        (WidgetTester tester) async {
      await pumpApp(
        tester,
        AppBottomNav(
          currentIndex: 2,
          onSelect: (_) {},
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Trips'), findsNothing);
      expect(find.text('Spots'), findsNothing);
      expect(find.text('Alerts'), findsNothing);
      expect(find.text('Profile'), findsNothing);
    });

    testWidgets('short tap on Home calls onSelect with Home index (2)',
        (WidgetTester tester) async {
      int? selectedIndex;

      await pumpApp(
        tester,
        AppBottomNav(
          currentIndex: 0,
          onSelect: (index) {
            selectedIndex = index;
          },
        ),
      );

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(2));
    });

    testWidgets('long press on Home button opens radial fan menu',
        (WidgetTester tester) async {
      await pumpApp(
        tester,
        AppBottomNav(
          currentIndex: 2,
          onSelect: (_) {},
        ),
      );

      expect(find.text('Trips'), findsNothing);

      // Trigger long press gesture on Home button
      final homeFinder = find.text('Home');
      final TestGesture gesture = await tester.startGesture(tester.getCenter(homeFinder));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Fan menu should now be open, displaying destination labels
      expect(find.text('Trips'), findsOneWidget);
      expect(find.text('Spots'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Release gesture
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('long press and drag to destination selects item on release',
        (WidgetTester tester) async {
      int? selectedIndex;

      await pumpApp(
        tester,
        AppBottomNav(
          currentIndex: 2,
          onSelect: (index) {
            selectedIndex = index;
          },
        ),
      );

      final homeCenter = tester.getCenter(find.text('Home'));
      final TestGesture gesture = await tester.startGesture(homeCenter);

      // Hold down to trigger long press
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Drag upward toward Trips destination (dx=0, dy=-135)
      await gesture.moveTo(Offset(homeCenter.dx, homeCenter.dy - 135));
      await tester.pumpAndSettle();

      // Release gesture
      await gesture.up();
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(0)); // Trips index
    });

    testWidgets('releasing in center / cancel zone closes fan without navigating',
        (WidgetTester tester) async {
      int? selectedIndex;

      await pumpApp(
        tester,
        AppBottomNav(
          currentIndex: 2,
          onSelect: (index) {
            selectedIndex = index;
          },
        ),
      );

      final homeCenter = tester.getCenter(find.text('Home'));
      final TestGesture gesture = await tester.startGesture(homeCenter);

      // Hold down to open fan
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Trips'), findsOneWidget);

      // Release near center (not over any fan item target)
      await gesture.up();
      await tester.pumpAndSettle();

      expect(selectedIndex, isNull);
      expect(find.text('Trips'), findsNothing);
    });
  });

  group('HomeShellScreen StatefulShellRoute Integration Tests', () {
    testWidgets('a signed-in user starts on Home and can navigate using fan menu',
        (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                HomeShellScreen(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(path: '/trips', builder: (c, s) => const Scaffold(body: Text('Trips Screen'))),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/spots', builder: (c, s) => const Scaffold(body: Text('Spots Screen'))),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/home', builder: (c, s) => const Scaffold(body: Text('Home Screen'))),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/alerts', builder: (c, s) => const Scaffold(body: Text('Alerts Screen'))),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(path: '/profile', builder: (c, s) => const Scaffold(body: Text('Profile Screen'))),
              ]),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);

      // Long press Home button to open fan
      final homeCenter = tester.getCenter(find.text('Home'));
      final TestGesture gesture = await tester.startGesture(homeCenter);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Drag to Spots (dx=-95, dy=-55)
      await gesture.moveTo(Offset(homeCenter.dx - 95, homeCenter.dy - 55));
      await tester.pumpAndSettle();

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Spots Screen'), findsOneWidget);
    });
  });
}
