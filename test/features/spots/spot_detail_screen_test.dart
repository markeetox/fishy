import 'package:firebase_auth/firebase_auth.dart';
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

class MockFirebaseUser implements User {
  @override
  String get uid => 'test_user_id';

  @override
  String? get displayName => 'Test Captain';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SpotDetailScreen renders long sample strings without overflow and pops when Close is tapped',
      (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 3.0;

    final longTitle = 'A' * 80;
    final longAuthor = 'Captain ${'B' * 40}';

    final testSpot = Spot(
      id: 'spot_1',
      userId: 'test_user_id',
      authorName: longAuthor,
      name: longTitle,
      description: 'Lively reef with snook and snapper.' * 3,
      latitude: 25.76,
      longitude: -80.19,
      species: ['Snook', 'Red Drum', 'Mahi Mahi', 'Yellowtail Snapper'],
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
          authStateProvider.overrideWith((ref) => Stream.value(MockFirebaseUser())),
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
    expect(find.text('Spots List'), findsOneWidget);
  });
}
