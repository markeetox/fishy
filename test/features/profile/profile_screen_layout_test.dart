import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/core/app_theme.dart';
import 'package:seabound/features/auth/auth_providers.dart';
import 'package:seabound/features/profile/badge_service.dart';
import 'package:seabound/features/profile/profile_providers.dart';
import 'package:seabound/features/profile/profile_repository.dart';
import 'package:seabound/features/profile/profile_screen.dart';
import 'package:seabound/features/spots/spots_providers.dart';
import 'package:seabound/features/trips/trips_providers.dart';

class MockProfileRepository implements ProfileRepository {
  @override
  Future<void> removeEmailFromUserDoc(String uid) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockBadgeService implements BadgeService {
  @override
  Future<BadgeResult> checkAllBadges() async {
    return const BadgeResult(newlyUnlocked: []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ProfileScreen renders username with 36px font, stats container, and top bar buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          userDocStreamProvider.overrideWith((ref) => Stream.value({'username': 'CaptainJack'})),
          userEarnedBadgesProvider.overrideWith((ref) => Stream.value({'badge_1': DateTime.now()})),
          userTripsStreamProvider.overrideWith((ref) => Stream.value([])),
          allSpotsStreamProvider.overrideWith((ref) => Stream.value([])),
          profileRepositoryProvider.overrideWithValue(MockProfileRepository()),
          badgeServiceProvider.overrideWithValue(MockBadgeService()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify username is displayed
    final usernameFinder = find.text('CaptainJack');
    expect(usernameFinder, findsOneWidget);

    // Verify username font size is 36
    final Text textWidget = tester.widget(usernameFinder);
    expect(textWidget.style?.fontSize, 36);

    // Verify stat circular tiles (Trips, Spots, Pins)
    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('Spots'), findsOneWidget);
    expect(find.text('Pins'), findsOneWidget);

    // Verify top bar buttons
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}
