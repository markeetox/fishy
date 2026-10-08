import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_scaffold.dart';
import '../../core/app_theme.dart';
import '../../core/floating_top_bar.dart';
import '../auth/auth_providers.dart';
import 'trips_providers.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B2250),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF00E5FF), width: 2),
          ),
          title: const Text(
            'Delete Trip?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$title"? This action cannot be undone.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD1142A),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final repository = ref.read(tripsRepositoryProvider);
      await repository.deleteTrip(tripId);
      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.asData?.value;
    final tripDetailAsync = ref.watch(tripDetailStreamProvider(tripId));

    final tokens = Theme.of(context).extension<OceanThemeExtension>() ??
        OceanThemeExtension.defaultTokens;

    return tripDetailAsync.when(
      data: (trip) {
        if (trip == null) {
          return AppScaffold(
            topBar: FloatingTopBar(
              leading: FloatingTopBarButton(
                icon: Icons.close,
                tooltip: 'Close',
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(child: Text('Trip not found.')),
          );
        }

        final isAuthor = currentUser != null && currentUser.uid == trip.userId;
        final formattedDate = DateFormat.yMMMMd().format(trip.date);

        return AppScaffold(
          topBar: FloatingTopBar(
            leading: FloatingTopBarButton(
              icon: Icons.close,
              tooltip: 'Close',
              onPressed: () => context.pop(),
            ),
            actions: isAuthor
                ? [
                    FloatingTopBarButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit',
                      onPressed: () => context.push('/trips/$tripId/edit'),
                    ),
                    FloatingTopBarButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(context, ref, trip.title),
                    ),
                  ]
                : [],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 88, left: 24, right: 24, bottom: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.title,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: tokens.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formattedDate,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: tokens.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.locationName,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, color: Colors.white24),
                    if (trip.species.isNotEmpty) ...[
                      const Text(
                        'Species Targeted / Caught',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: trip.species.map((species) {
                          return Chip(
                            label: Text(
                              species,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (trip.notes.isNotEmpty) ...[
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B2250),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00E5FF),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          trip.notes,
                          softWrap: true,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => AppScaffold(
        topBar: FloatingTopBar(
          leading: FloatingTopBarButton(
            icon: Icons.close,
            tooltip: 'Close',
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => AppScaffold(
        topBar: FloatingTopBar(
          leading: FloatingTopBarButton(
            icon: Icons.close,
            tooltip: 'Close',
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text('Error loading trip: $e')),
      ),
    );
  }
}
