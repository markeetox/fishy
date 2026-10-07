import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seabound/core/app_theme.dart';
import 'package:seabound/core/gradient_background.dart';
import 'package:seabound/features/auth/auth_providers.dart';
import 'package:seabound/features/profile/badge_service.dart';
import 'package:seabound/features/spots/spot_form_screen.dart';

class TestTileProvider extends TileProvider {
  static final Uint8List _transparentBytes = Uint8List.fromList(const <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  const TestTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_transparentBytes);
  }
}

class MockUser {
  final String uid = 'test_user_id';
  final String? displayName = 'Test Captain';
}

class MockBadgeService implements BadgeService {
  @override
  Future<BadgeResult> onSpotShared(String uid, int spotCount) async {
    return const BadgeResult();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SpotFormScreen contains GradientBackground and Close button; pops without dialog when empty',
      (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 3.0;

    final router = GoRouter(
      initialLocation: '/add',
      routes: [
        GoRoute(
          path: '/',
          builder: (c, s) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/add',
          builder: (c, s) => const SpotFormScreen(tileProvider: TestTileProvider()),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(MockUser() as dynamic)),
          userProfileProvider.overrideWith((ref) => Stream.value({})),
          badgeServiceProvider.overrideWithValue(MockBadgeService()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify GradientBackground exists
    expect(find.byType(GradientBackground), findsWidgets);

    // Verify Close button exists
    final closeButtonFinder = find.byTooltip('Close');
    expect(closeButtonFinder, findsOneWidget);

    // Tap Close button when form is empty
    await tester.tap(closeButtonFinder);
    await tester.pumpAndSettle();

    // Verify no discard dialog was shown and screen popped to '/'
    expect(find.text('Discard this pin?'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('SpotFormScreen shows discard dialog when Close is tapped and field has text',
      (WidgetTester tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 3.0;

    final router = GoRouter(
      initialLocation: '/add',
      routes: [
        GoRoute(
          path: '/',
          builder: (c, s) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/add',
          builder: (c, s) => const SpotFormScreen(tileProvider: TestTileProvider()),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(MockUser() as dynamic)),
          userProfileProvider.overrideWith((ref) => Stream.value({})),
          badgeServiceProvider.overrideWithValue(MockBadgeService()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Type text into Spot Name field
    await tester.enterText(find.widgetWithText(TextFormField, 'Spot Name *'), 'Secret Reef');
    await tester.pump();

    // Tap Close button
    await tester.tap(find.byTooltip('Close'));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify dark-themed discard dialog appears
    expect(find.text('Discard this pin?'), findsOneWidget);
    expect(find.text('Keep editing'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);

    // Tap Discard button
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    // Verify navigated back to '/'
    expect(find.text('Home'), findsOneWidget);
  });
}
