import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/core/app_router.dart';
import 'package:seabound/main.dart';

void main() {
  testWidgets('App launches and displays Login screen initial state',
      (WidgetTester tester) async {
    appRouter.go('/login');
    await tester.pumpWidget(const ProviderScope(child: SeaboundApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Seabound'), findsOneWidget);
    expect(find.text('Log In (Demo)'), findsOneWidget);
    expect(find.text("Don't have an account? Sign Up"), findsOneWidget);
  });

  testWidgets('Navigates from Login to Sign Up screen',
      (WidgetTester tester) async {
    appRouter.go('/login');
    await tester.pumpWidget(const ProviderScope(child: SeaboundApp()));
    await tester.pumpAndSettle();

    final signupButton = find.text("Don't have an account? Sign Up");
    expect(signupButton, findsOneWidget);
    await tester.tap(signupButton);
    await tester.pumpAndSettle();

    expect(find.text('Join Seabound Community'), findsOneWidget);
  });

  testWidgets('Navigates from Login to Home shell with navigation bar',
      (WidgetTester tester) async {
    appRouter.go('/login');
    await tester.pumpWidget(const ProviderScope(child: SeaboundApp()));
    await tester.pumpAndSettle();

    final loginButton = find.text('Log In (Demo)');
    expect(loginButton, findsOneWidget);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Trips & Voyages'), findsOneWidget);

    // Switch to Spots tab
    await tester.tap(find.text('Spots').last);
    await tester.pumpAndSettle();
    expect(find.text('Fishing & Boating Spots'), findsOneWidget);

    // Switch to Alerts tab
    await tester.tap(find.text('Alerts').last);
    await tester.pumpAndSettle();
    expect(find.text('Weather & Safety Alerts'), findsOneWidget);

    // Switch to Profile tab
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Captain Profile'), findsOneWidget);
  });
}
