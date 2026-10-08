import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seabound/core/app_theme.dart';
import 'package:seabound/core/gradient_background.dart';
import 'package:seabound/features/auth/auth_providers.dart';
import 'package:seabound/features/spots/spot_detail_screen.dart';
import 'package:seabound/features/spots/spot_model.dart';
import 'package:seabound/features/spots/spots_providers.dart';

import '../../helpers/fake_tile_provider.dart';

class MockUser {
  final String uid = 'test_user_id';
  final String? displayName = 'Test Captain';
}

void main() {
  testWidgets('SpotDetailScreen contains GradientBackground and Close button; tapping Close pops screen',
      (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 3.0;

    final testSpot = Spot(
      id: 'spot_1',
      userId: 'test_user_id',
      authorName: 'Captain Jack',
      name: 'Pelican Point Reef',
      description: 'Lively reef with snook and snapper.',
      latitude: 25.76,
      longitude: -80.19,
      species: ['Snook', 'Snapper'],
      createdAt: DateTime.now(),
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (c, s) => const Scaffold(body: Text('Spots List')),
        ),
        GoRoute(
          path: '/spots/:id',
          builder: (c, s) => SpotDetailScreen(
            spotId: 'spot_1',
            tileProvider: FakeTileProvider(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(MockUser() as dynamic)),
          spotDetailStreamProvider('spot_1').overrideWith((ref) => Stream.value(testSpot)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Push /spots/spot_1 on top of /
    router.push('/spots/spot_1');
    await tester.pumpAndSettle();

    // Verify GradientBackground exists
    expect(find.byType(GradientBackground), findsWidgets);

    // Verify spot name is displayed extra bold
    expect(find.text('Pelican Point Reef'), findsOneWidget);

    // Verify "Shared by Captain Jack" text is displayed
    expect(find.text('Shared by Captain Jack'), findsOneWidget);

    // Verify description card is displayed
    expect(find.text('Lively reef with snook and snapper.'), findsOneWidget);

    // Verify Close button exists
    final closeButtonFinder = find.byTooltip('Close');
    expect(closeButtonFinder, findsOneWidget);

    // Tap Close button
    await tester.tap(closeButtonFinder);
    await tester.pumpAndSettle();

    // Verify screen popped to '/'
    expect(find.text('Spots List'), findsOneWidget);
  });
}
