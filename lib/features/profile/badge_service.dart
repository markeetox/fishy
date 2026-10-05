import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'badge_pin.dart';
import 'catalog.dart';

class BadgeService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BadgeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  User? get _user => _auth.currentUser;

  Future<void> checkAllBadges(BuildContext? context) async {
    if (_user == null) return;
    final uid = _user!.uid;

    // Check account creation date for welcome_aboard and founding_crew
    await _checkWelcomeAndFoundingCrew(context, uid);

    // Check trip badges (first_log, regular, salty_dog)
    await _checkTripBadges(context, uid);

    // Check spot badges (spot_finder)
    await _checkSpotBadges(context, uid);

    // Check profile colors_raised
    await _checkProfileColorsRaised(context, uid);
  }

  Future<void> onTripLogged(BuildContext? context, String uid, int tripCount) async {
    if (tripCount >= 1) {
      await _awardBadge(context, uid, 'first_log');
    }
    if (tripCount >= 5) {
      await _awardBadge(context, uid, 'regular');
    }
    if (tripCount >= 25) {
      await _awardBadge(context, uid, 'salty_dog');
    }
  }

  Future<void> onSpotShared(BuildContext? context, String uid, int spotCount) async {
    if (spotCount >= 1) {
      await _awardBadge(context, uid, 'spot_finder');
    }
  }

  Future<void> onDepthLayerToggled(BuildContext? context) async {
    if (_user == null) return;
    await _awardBadge(context, _user!.uid, 'chart_reader');
  }

  Future<void> onAlertsOpened(BuildContext? context) async {
    if (_user == null) return;
    await _awardBadge(context, _user!.uid, 'weather_eye');
  }

  Future<void> onMyLocationTapped(BuildContext? context) async {
    if (_user == null) return;
    await _awardBadge(context, _user!.uid, 'navigator');
  }

  Future<void> onProfileUpdated(BuildContext? context) async {
    if (_user == null) return;
    await _checkProfileColorsRaised(context, _user!.uid);
  }

  Future<void> _checkWelcomeAndFoundingCrew(
      BuildContext? context, String uid) async {
    await _awardBadge(context, uid, 'welcome_aboard');

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final createdAtTS = userDoc.data()?['createdAt'] as Timestamp?;
    final createdAt = createdAtTS?.toDate() ?? DateTime.now();

    if (createdAt.isBefore(Catalog.foundingCrewCutoff)) {
      await _awardBadge(context, uid, 'founding_crew');
    }
  }

  Future<void> _checkTripBadges(BuildContext? context, String uid) async {
    final countQuery = await _firestore
        .collection('trips')
        .where('userId', isEqualTo: uid)
        .count()
        .get();

    final tripCount = countQuery.count ?? 0;
    await onTripLogged(context, uid, tripCount);
  }

  Future<void> _checkSpotBadges(BuildContext? context, String uid) async {
    final countQuery = await _firestore
        .collection('spots')
        .where('userId', isEqualTo: uid)
        .count()
        .get();

    final spotCount = countQuery.count ?? 0;
    await onSpotShared(context, uid, spotCount);
  }

  Future<void> _checkProfileColorsRaised(
      BuildContext? context, String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final data = userDoc.data();
    final username = data?['username'] as String?;
    final avatarId = data?['avatarId'] as String?;

    if (username != null &&
        username.isNotEmpty &&
        avatarId != null &&
        avatarId.isNotEmpty) {
      await _awardBadge(context, uid, 'colors_raised');
    }
  }

  Future<void> _awardBadge(
      BuildContext? context, String uid, String badgeId) async {
    final badge = Catalog.getBadgeById(badgeId);
    if (badge == null) return;

    final badgeDocRef =
        _firestore.collection('users').doc(uid).collection('badges').doc(badgeId);

    final badgeDoc = await badgeDocRef.get();
    if (badgeDoc.exists) return; // Already awarded

    // Get current total XP before awarding
    final existingBadgesSnap =
        await _firestore.collection('users').doc(uid).collection('badges').get();

    int oldTotalXp = 0;
    for (final doc in existingBadgesSnap.docs) {
      final b = Catalog.getBadgeById(doc.id);
      if (b != null) oldTotalXp += b.xp;
    }

    final oldLevel = Catalog.getLevelFromXp(oldTotalXp);
    final newTotalXp = oldTotalXp + badge.xp;
    final newLevel = Catalog.getLevelFromXp(newTotalXp);
    final isLevelUp = newLevel > oldLevel;

    // Atomically set badge document
    await badgeDocRef.set({
      'earnedAt': FieldValue.serverTimestamp(),
    });

    if (context != null && context.mounted) {
      _showUnlockDialog(context, badge, isLevelUp, newLevel);
    }
  }

  void _showUnlockDialog(
    BuildContext context,
    AchievementBadge badge,
    bool isLevelUp,
    int newLevel,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('🎉 Badge Unlocked!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BadgePin(badge: badge, isEarned: true, size: 80),
              const SizedBox(height: 12),
              Text(
                badge.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text('+${badge.xp} XP'),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              if (isLevelUp) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '⭐ Level Up! You reached Level $newLevel (${Catalog.getTitleFromLevel(newLevel)})!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Awesome!'),
            ),
          ],
        );
      },
    );
  }
}

final badgeServiceProvider = Provider<BadgeService>((ref) {
  return BadgeService();
});
