import 'package:flutter/material.dart';

import 'catalog.dart';

class BadgePin extends StatelessWidget {
  final AchievementBadge badge;
  final bool isEarned;
  final double size;

  const BadgePin({
    super.key,
    required this.badge,
    required this.isEarned,
    this.size = 56.0,
  });

  IconData _getFallbackIcon(String id) {
    switch (id) {
      case 'welcome_aboard':
        return Icons.sailing;
      case 'colors_raised':
        return Icons.flag;
      case 'first_log':
        return Icons.directions_boat;
      case 'regular':
        return Icons.anchor;
      case 'salty_dog':
        return Icons.phishing;
      case 'spot_finder':
        return Icons.place;
      case 'chart_reader':
        return Icons.map;
      case 'weather_eye':
        return Icons.visibility;
      case 'navigator':
        return Icons.explore;
      case 'founding_crew':
        return Icons.stars;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEarned
                ? primaryColor.withValues(alpha: 0.15)
                : Colors.grey.shade300,
            border: Border.all(
              color: isEarned ? primaryColor : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              badge.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback colored circle with icon when asset PNG is not present
                return Center(
                  child: Icon(
                    _getFallbackIcon(badge.id),
                    size: size * 0.5,
                    color: isEarned ? primaryColor : Colors.grey.shade600,
                  ),
                );
              },
            ),
          ),
        ),
        if (!isEarned)
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black38,
            ),
            child: Icon(
              Icons.lock,
              size: size * 0.35,
              color: Colors.white,
            ),
          ),
      ],
    );
  }
}
