import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../auth/auth_providers.dart';
import '../spots/spots_providers.dart';
import '../trips/trips_providers.dart';
import 'badge_pin.dart';
import 'badge_service.dart';
import 'catalog.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProfileOnOpen();
    });
  }

  Future<void> _initProfileOnOpen() async {
    final authState = ref.read(authStateProvider);
    final user = authState.asData?.value;
    if (user != null) {
      final repository = ref.read(profileRepositoryProvider);
      // Clean up legacy email field from user doc on open
      await repository.removeEmailFromUserDoc(user.uid);

      // Check badge qualifications
      final badgeService = ref.read(badgeServiceProvider);
      final result = await badgeService.checkAllBadges();

      if (mounted) {
        showBadgeUnlocks(context, result);
      }
    }
  }

  void _showPinDetailDialog(BuildContext context, AchievementBadge badge, DateTime? earnedAt) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isEarned = earnedAt != null;
        final formattedDate =
            isEarned ? DateFormat.yMMMMd().format(earnedAt) : null;

        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BadgePin(badge: badge, isEarned: isEarned, size: 80),
              const SizedBox(height: 12),
              Text(
                badge.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isEarned ? badge.description : badge.hint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Chip(
                label: Text('+${badge.xp} XP'),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              if (isEarned && formattedDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Earned on $formattedDate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userDocState = ref.watch(userDocStreamProvider);
    final earnedBadgesState = ref.watch(userEarnedBadgesProvider);
    final tripsAsync = ref.watch(userTripsStreamProvider);
    final spotsAsync = ref.watch(allSpotsStreamProvider);

    final currentUser = authState.asData?.value;
    final userDoc = userDocState.asData?.value;
    final earnedMap = earnedBadgesState.asData?.value ?? {};

    final username = userDoc?['username'] as String? ??
        currentUser?.displayName ??
        'Captain';
    final avatarId = userDoc?['avatarId'] as String?;

    // Calculate total XP from earned badges catalog
    int totalXp = 0;
    for (final badgeId in earnedMap.keys) {
      final b = Catalog.getBadgeById(badgeId);
      if (b != null) totalXp += b.xp;
    }

    final level = Catalog.getLevelFromXp(totalXp);
    final title = Catalog.getTitleFromLevel(level);

    final currentLevelXp = Catalog.xpForLevel(level);
    final nextLevelXp = Catalog.xpForLevel(level + 1);
    final levelXpProgress = totalXp - currentLevelXp;
    final levelXpNeeded = nextLevelXp - currentLevelXp;
    final progressFraction =
        levelXpNeeded > 0 ? (levelXpProgress / levelXpNeeded).clamp(0.0, 1.0) : 1.0;

    final tripCount = tripsAsync.asData?.value.length ?? 0;
    final spotCount = spotsAsync.asData?.value
            .where((s) => s.userId == currentUser?.uid)
            .length ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Captain Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () {
              context.push('/profile/edit');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Header Profile Info
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: avatarId != null && avatarId.isNotEmpty
                      ? Image.asset(
                          'assets/avatars/$avatarId.png',
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 56,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            );
                          },
                        )
                      : Icon(
                          Icons.person,
                          size: 56,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  username,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$title • Level $level',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),

                // XP Progress Bar
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level $level Progress',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '$totalXp / $nextLevelXp XP',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressFraction,
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatTile(label: 'Trips', value: '$tripCount'),
                    _StatTile(label: 'Spots', value: '$spotCount'),
                    _StatTile(label: 'Pins', value: '${earnedMap.length}'),
                  ],
                ),
                const Divider(height: 40),

                // Pins Grid Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Earned Pins & Badges',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 100,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: Catalog.starterBadges.length,
                  itemBuilder: (context, index) {
                    final badge = Catalog.starterBadges[index];
                    final earnedAt = earnedMap[badge.id];
                    final isEarned = earnedAt != null;

                    return GestureDetector(
                      onTap: () => _showPinDetailDialog(context, badge, earnedAt),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BadgePin(
                            badge: badge,
                            isEarned: isEarned,
                            size: 56,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            badge.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: isEarned
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isEarned
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Action Links
                OutlinedButton.icon(
                  onPressed: () {
                    context.push('/about');
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('About & Data Sources'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final authRepo = ref.read(authRepositoryProvider);
                    await authRepo.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}
