import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/alerts/alerts_providers.dart';
import 'app_theme.dart';
import 'gradient_background.dart';

class HomeShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsNotifierProvider);
    final hasAlerts = alertsState.alerts.isNotEmpty;
    final tokens = Theme.of(context).extension<OceanThemeExtension>() ??
        OceanThemeExtension.defaultTokens;

    final isProfileTab = navigationShell.currentIndex == 3;

    return GradientBackground(
      variant: isProfileTab ? GradientVariant.red : GradientVariant.blue,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: navigationShell,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0B2250),
            border: Border(
              top: BorderSide(color: Color(0xFF00E5FF), width: 2),
            ),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              indicatorColor: tokens.cyan,
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return IconThemeData(size: 30, color: tokens.onCyan);
                }
                return const IconThemeData(size: 30, color: Colors.white70);
              }),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00E5FF),
                  );
                }
                return const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.directions_boat_outlined),
                  selectedIcon: Icon(Icons.directions_boat),
                  label: 'Trips',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.place_outlined),
                  selectedIcon: Icon(Icons.place),
                  label: 'Spots',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: hasAlerts,
                    smallSize: 8,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: hasAlerts,
                    smallSize: 8,
                    child: const Icon(Icons.notifications),
                  ),
                  label: 'Alerts',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
