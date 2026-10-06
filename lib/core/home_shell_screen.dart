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

    // Index 4 corresponds to Profile tab
    final isProfileTab = navigationShell.currentIndex == 4;

    final navItems = [
      _NavItemData(
        label: 'Trips',
        icon: Icons.directions_boat_outlined,
        selectedIcon: Icons.directions_boat,
        isCenter: false,
      ),
      _NavItemData(
        label: 'Spots',
        icon: Icons.place_outlined,
        selectedIcon: Icons.place,
        isCenter: false,
      ),
      _NavItemData(
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        isCenter: true,
      ),
      _NavItemData(
        label: 'Alerts',
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications,
        isCenter: false,
        hasBadge: hasAlerts,
      ),
      _NavItemData(
        label: 'Profile',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        isCenter: false,
      ),
    ];

    return GradientBackground(
      variant: isProfileTab ? GradientVariant.red : GradientVariant.blue,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: navigationShell,
        bottomNavigationBar: SafeArea(
          bottom: true,
          top: false,
          child: SizedBox(
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Strip - Half height of regular circle (32dp)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B2250),
                      border: Border(
                        top: BorderSide(color: Color(0xFF00E5FF), width: 2),
                      ),
                    ),
                  ),
                ),

                // Row of 5 Circular Navigation Item Buttons
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(navItems.length, (index) {
                      final item = navItems[index];
                      final isSelected = navigationShell.currentIndex == index;
                      final size = item.isCenter ? 76.0 : 64.0;

                      return GestureDetector(
                        onTap: () => _onTap(index),
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? tokens.cyan
                                : const Color(0xFF0B2250),
                            border: Border.all(
                              color: tokens.cyan,
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    isSelected ? item.selectedIcon : item.icon,
                                    size: item.isCenter ? 26 : 22,
                                    color: isSelected
                                        ? tokens.onCyan
                                        : Colors.white.withValues(alpha: 0.8),
                                  ),
                                  if (item.hasBadge)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? tokens.onCyan
                                      : Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isCenter;
  final bool hasBadge;

  _NavItemData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isCenter,
    this.hasBadge = false,
  });
}
