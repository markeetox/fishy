import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_scaffold.dart';
import '../../core/app_theme.dart';
import '../../core/floating_top_bar.dart';
import '../../core/map_layer_config.dart';
import '../auth/auth_providers.dart';
import 'spots_providers.dart';

class SpotDetailScreen extends ConsumerWidget {
  final String spotId;
  final TileProvider? tileProvider;

  const SpotDetailScreen({
    super.key,
    required this.spotId,
    this.tileProvider,
  });

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String spotName) async {
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
            'Delete Spot?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$spotName"? This action cannot be undone.',
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
      final repository = ref.read(spotsRepositoryProvider);
      await repository.deleteSpot(spotId);
      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.asData?.value;
    final spotDetailAsync = ref.watch(spotDetailStreamProvider(spotId));

    final tokens = Theme.of(context).extension<OceanThemeExtension>() ??
        OceanThemeExtension.defaultTokens;

    return spotDetailAsync.when(
      data: (spot) {
        if (spot == null) {
          return AppScaffold(
            topBar: FloatingTopBar(
              leading: FloatingTopBarButton(
                icon: Icons.close,
                tooltip: 'Close',
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(child: Text('Spot not found.')),
          );
        }

        final isAuthor = currentUser != null && currentUser.uid == spot.userId;
        final formattedDate = spot.createdAt != null
            ? DateFormat.yMMMMd().format(spot.createdAt!)
            : 'Recent';

        final spotLatLng = LatLng(spot.latitude, spot.longitude);

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
                      onPressed: () => context.push('/spots/$spotId/edit'),
                    ),
                    FloatingTopBarButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(context, ref, spot.name),
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
                      spot.name,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      cross: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 18,
                              color: tokens.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: InkWell(
                                onTap: spot.userId.isNotEmpty
                                    ? () => context.push('/profile/user/${spot.userId}')
                                    : null,
                                borderRadius: BorderRadius.circular(4),
                                child: Text(
                                  'Shared by ${spot.authorName}',
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: tokens.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 220,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: spotLatLng,
                            initialZoom: 12.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: MapLayerConfig.openStreetMapTileUrl,
                              userAgentPackageName: 'com.onerevamp.seabound',
                              tileProvider: tileProvider,
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: spotLatLng,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.place,
                                    size: 40,
                                    color: Color(0xFF00E5FF),
                                  ),
                                ),
                              ],
                            ),
                            RichAttributionWidget(
                              attributions: [
                                TextSourceAttribution(
                                  'OpenStreetMap contributors',
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (spot.description.isNotEmpty) ...[
                      const Text(
                        'Description',
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
                          spot.description,
                          softWrap: true,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (spot.species.isNotEmpty) ...[
                      const Text(
                        'Species Found Here',
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
                        children: spot.species.map((species) {
                          return Chip(
                            label: Text(
                              species,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
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
        body: Center(child: Text('Error loading spot: $e')),
      ),
    );
  }
}
