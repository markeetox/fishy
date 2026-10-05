import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'badge_pin.dart';
import 'catalog.dart';
import 'profile_providers.dart';

class PublicProfileScreen extends ConsumerWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final userDocAsync = ref.watch(publicProfileDocProvider(userId));
    final earnedBadgesAsync = ref.watch(publicProfileBadgesProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Captain Profile'),
      ),
      body: userDocAsync.when(
        data: (userDoc) {
          if (userDoc == null) {
            return const Center(child: Text('User profile not found.'));
          }

          final username = userDoc['username'] as String? ?? 'Captain';
          final avatarId = userDoc['avatarId'] as String?;
          final earnedMap = earnedBadgesAsync.asData?.value ?? {};

          // Calculate total XP & level from earned badges
          int totalXp = 0;
          for (final badgeId in earnedMap.keys) {
            final b = Catalog.getBadgeById(badgeId);
            if (b != null) totalXp += b.xp;
          }

          final level = Catalog.getLevelFromXp(totalXp);
          final title = Catalog.getTitleFromLevel(level);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: avatarId != null && avatarId.isNotEmpty
                          ? Image.asset(
                              'assets/avatars/$avatarId.png',
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 56,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                );
                              },
                            )
                          : Icon(
                              Icons.person,
                              size: 56,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
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
                    const Divider(height: 40),
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
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
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
                          onTap: () =>
                              _showPinDetailDialog(context, badge, earnedAt),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: isEarned
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isEarned
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                          : Theme.of(context)
                                              .colorScheme
                                              .outline,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading profile: $e')),
      ),
    );
  }
}
