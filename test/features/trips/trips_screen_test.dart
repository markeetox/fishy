import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/trips/trip_model.dart';
import 'package:seabound/features/trips/trips_providers.dart';
import 'package:seabound/features/trips/trips_screen.dart';

void main() {
  testWidgets('TripsScreen renders empty state when no trips exist',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userTripsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: TripsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('No Trips Logged Yet'), findsOneWidget);
    expect(
      find.text('Start tracking your fishing & boating adventures by logging your first trip!'),
      findsOneWidget,
    );
    expect(find.text('Log First Trip'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('TripsScreen renders list of trips when data is available',
      (WidgetTester tester) async {
    final sampleTrip = Trip(
      id: 'trip1',
      userId: 'user1',
      title: 'Ocean Voyage',
      date: DateTime(2025, 4, 15),
      locationName: 'Key West',
      species: const ['Mahi Mahi', 'Sailfish'],
      notes: 'Bait used: squid.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userTripsStreamProvider.overrideWith((ref) => Stream.value([sampleTrip])),
        ],
        child: const MaterialApp(
          home: TripsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ocean Voyage'), findsOneWidget);
    expect(find.text('Key West'), findsOneWidget);
    expect(find.text('Mahi Mahi'), findsOneWidget);
    expect(find.text('Sailfish'), findsOneWidget);
  });
}
