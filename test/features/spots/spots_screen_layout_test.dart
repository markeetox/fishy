import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/core/app_theme.dart';
import 'package:seabound/features/spots/spots_providers.dart';
import 'package:seabound/features/spots/spots_screen.dart';

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
    expect(find.byIcon(Icons.layers), findsOneWidget);

    // Check Community Spots button exists
    expect(find.text('Community Spots'), findsOneWidget);

    // Check Extended FAB exists with Add Spot label and add icon
    expect(find.text('Add Spot'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
