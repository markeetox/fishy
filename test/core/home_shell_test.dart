import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seabound/core/app_bottom_nav.dart';
import 'package:seabound/core/home_shell_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  group('AppBottomNav Widget Tests', () {
    testWidgets('renders five items in order: Trips, Spots, Home, Alerts, Profile',
        (WidgetTester tester) async {
      await pumpApp(
        tester,
        AppBottomNav(
          currentIndex: 2,
          onSelect: (_) {},
        ),
      );

      final texts = find.byType(Text);
      final labels = texts
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .where((data) => data != null)
          .toList();

      expect(labels, containsAllInOrder(['Trips', 'Spots', 'Home', 'Alerts', 'Profile']));
    });

    testWidgets('Home item is larger than other navigation items',
        (WidgetTester tester) async {
      await pumpApp(
        tester,
        AppBottomNav(
          currentIndex: 2,
          onSelect: (_) {},
        ),
      );

      final homeFinder = find.ancestor(
        of: find.text('Home'),
        matching: find.byType(Container),
      ).first;

      final tripsFinder = find.ancestor(
        of: find.text('Trips'),
        matching: find.byType(Container),
      ).first;

      final Size homeSize = tester.getSize(homeFinder);
      final Size tripsSize = tester.getSize(tripsFinder);

      expect(homeSize.width, equals(76.0));
      expect(homeSize.height, equals(76.0));
      expect(tripsSize.width, equals(64.0));
      expect(tripsSize.height, equals(64.0));
      expect(homeSize.width, greaterThan(tripsSize.width));
    });

    testWidgets('tapping an item calls onSelect with correct index',
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

      await tester.tap(find.text('Spots'));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(1));

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(4));
    });

    testWidgets('selected item is highlighted with cyan background/text color',
        (WidgetTester tester) async {
      await pumpApp(
        tester,
        AppBottomNav(
          currentIndex: 0, // Trips selected
          onSelect: (_) {},
        ),
      );

      final tripsText = tester.widget<Text>(find.text('Trips'));
      final spotsText = tester.widget<Text>(find.text('Spots'));

      // Selected item text color should be onCyan (0xFF001018), non-selected is translucent white
      expect(tripsText.style?.color, equals(const Color(0xFF001018)));
      expect(spotsText.style?.color, isNot(equals(const Color(0xFF001018))));
    });
  });

  group('HomeShellScreen StatefulShellRoute Integration Tests', () {
    testWidgets('a signed-in user starts on Home when initialLocation is /home',
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

      // Tap Trips tab
      await tester.tap(find.text('Trips'));
      await tester.pumpAndSettle();

      expect(find.text('Trips Screen'), findsOneWidget);
    });
  });
}
