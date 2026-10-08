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

class MockUser {
  final String uid = 'test_user_id';
  final String? displayName = 'Test Captain';
}

void main() {
  testWidgets('TripDetailScreen contains GradientBackground and Close button; tapping Close pops screen',
      (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 3.0;

    final testTrip = Trip(
      id: 'trip_1',
      userId: 'test_user_id',
      title: 'Deep Sea Catch',
      date: DateTime.now(),
      locationName: 'Key West',
      species: ['Mahi Mahi'],
      notes: 'Great weather and smooth waters.',
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
          authStateProvider.overrideWith((ref) => Stream.value(MockUser() as dynamic)),
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

    // Verify GradientBackground exists
    expect(find.byType(GradientBackground), findsWidgets);

    // Verify trip title is displayed extra bold
    expect(find.text('Deep Sea Catch'), findsOneWidget);

    // Verify notes card is displayed
    expect(find.text('Great weather and smooth waters.'), findsOneWidget);

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
