import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seabound/core/app_theme.dart';
import 'package:seabound/core/gradient_background.dart';
import 'package:seabound/features/auth/auth_providers.dart';
import 'package:seabound/features/trips/trip_detail_screen.dart';
import 'package:seabound/features/trips/trip_model.dart';
import 'package:seabound/features/trips/trips_providers.dart';

class MockFirebaseUser implements User {
  @override
  String get uid => 'test_user_id';

  @override
  String? get displayName => 'Test Captain';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('TripDetailScreen renders long sample strings without overflow and pops when Close is tapped',
      (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 3.0;

    final longTitle = 'A' * 80;
    final longLocation = 'Cape Marina Dock B ${'C' * 50}';

    final testTrip = Trip(
      id: 'trip_1',
      userId: 'test_user_id',
      title: longTitle,
      date: DateTime.now(),
      locationName: longLocation,
      species: ['Mahi Mahi', 'Bluefin Tuna', 'Yellowtail Snapper', 'Kingfish'],
      notes: 'Great weather and smooth waters.' * 4,
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (c, s) => const Scaffold(body: Text('Trips List')),
        ),
        GoRoute(
          path: '/trips/:id',
          builder: (c, s) => const TripDetailScreen(tripId: 'trip_1'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(MockFirebaseUser())),
          tripDetailStreamProvider('trip_1').overrideWith((ref) => Stream.value(testTrip)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Push /trips/trip_1 on top of /
    router.push('/trips/trip_1');
    await tester.pumpAndSettle();

    // Assert no overflow or layout exception occurred
    expect(tester.takeException(), isNull);

    // Verify GradientBackground exists
    expect(find.byType(GradientBackground), findsWidgets);

    // Verify Close button exists
    final closeButtonFinder = find.byTooltip('Close');
    expect(closeButtonFinder, findsOneWidget);

    // Tap Close button
    await tester.tap(closeButtonFinder);
    await tester.pumpAndSettle();

    // Verify screen popped to '/'
    expect(find.text('Trips List'), findsOneWidget);
  });
}
