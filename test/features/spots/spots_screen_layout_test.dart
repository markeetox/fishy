import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/core/app_theme.dart';
import 'package:seabound/core/map_layer_config.dart';
import 'package:seabound/features/map_layers/artificial_reefs_service.dart';
import 'package:seabound/features/map_layers/map_layers_provider.dart';
import 'package:seabound/features/spots/spots_providers.dart';
import 'package:seabound/features/spots/spots_screen.dart';

class MockFailingReefsService implements ArtificialReefsService {
  bool shouldFail = true;

  @override
  Future<List<ArtificialReefPoint>> fetchReefsInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    if (shouldFail) {
      throw Exception('Network connection failed');
    }
    return [
      const ArtificialReefPoint(
        id: 'reef_1',
        reefName: 'Test Reef',
        latitude: 25.76,
        longitude: -80.19,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SpotsScreen renders map layers button, community spots button, and red FAB',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allSpotsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SpotsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check Map Layers button exists
    expect(find.text('Layers'), findsOneWidget);

    // Check Community Spots button exists
    expect(find.text('Community Spots'), findsOneWidget);

    // Check Extended FAB exists with Add pin label
    expect(find.text('Add pin'), findsOneWidget);
  });

  testWidgets('SpotsScreen displays error banner with Retry button when artificial reefs fails to load',
      (WidgetTester tester) async {
    final mockReefsService = MockFailingReefsService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allSpotsStreamProvider.overrideWith((ref) => Stream.value([])),
          activeMapLayersProvider.overrideWith(
            () => ActiveMapLayersNotifier()..state = {MapLayerConfig.artificialReefsId},
          ),
          artificialReefsServiceProvider.overrideWithValue(mockReefsService),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SpotsScreen(),
        ),
      ),
    );

    // Pump to trigger onMapReady and debounce timer (800ms)
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));

    // Verify error banner is shown
    expect(find.text("Couldn't load reef data"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Now make mock service succeed and tap Retry
    mockReefsService.shouldFail = false;
    await tester.tap(find.text('Retry'));

    // Pump to trigger retry fetch and debounce timer
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));

    // Verify error banner is cleared on success
    expect(find.text("Couldn't load reef data"), findsNothing);
  });
}
