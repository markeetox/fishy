import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'spot_model.dart';
import 'spots_providers.dart';

enum ViewMode { map, list }

class SpotsScreen extends ConsumerStatefulWidget {
  const SpotsScreen({super.key});

  @override
  ConsumerState<SpotsScreen> createState() => _SpotsScreenState();
}

class _SpotsScreenState extends ConsumerState<SpotsScreen> {
  ViewMode _selectedView = ViewMode.map;

  @override
  Widget build(BuildContext context) {
    final spotsAsync = ref.watch(allSpotsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fishing Spots'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SegmentedButton<ViewMode>(
              segments: const [
                ButtonSegment<ViewMode>(
                  value: ViewMode.map,
                  icon: Icon(Icons.map_outlined),
                  label: Text('Map'),
                ),
                ButtonSegment<ViewMode>(
                  value: ViewMode.list,
                  icon: Icon(Icons.list_outlined),
                  label: Text('List'),
                ),
              ],
              selected: {_selectedView},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedView = newSelection.first;
                });
              },
            ),
          ),
        ],
      ),
      body: spotsAsync.when(
        data: (spots) {
          if (_selectedView == ViewMode.map) {
            return _SpotsMapView(spots: spots);
          } else {
            return _SpotsListView(spots: spots);
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading spots: $error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/spots/add');
        },
        tooltip: 'Add Spot',
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }
}

class _SpotsMapView extends StatelessWidget {
  final List<Spot> spots;

  const _SpotsMapView({required this.spots});

  @override
  Widget build(BuildContext context) {
    // Default center to Miami, FL or first spot position
    final initialCenter = spots.isNotEmpty
        ? LatLng(spots.first.latitude, spots.first.longitude)
        : const LatLng(25.7617, -80.1918);

    return FlutterMap(
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: spots.isNotEmpty ? 10.0 : 9.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.onerevamp.seabound',
        ),
        MarkerLayer(
          markers: spots.map((spot) {
            return Marker(
              point: LatLng(spot.latitude, spot.longitude),
              width: 44.0,
              height: 44.0,
              child: GestureDetector(
                onTap: () {
                  context.push('/spots/${spot.id}');
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.place,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            );
          }).toList(),
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
    );
  }
}

class _SpotsListView extends StatelessWidget {
  final List<Spot> spots;

  const _SpotsListView({required this.spots});

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.place_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Fishing Spots Shared Yet',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to share a favorite fishing spot with the community!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/spots/add');
                },
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Add First Spot'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: spots.length,
      itemBuilder: (context, index) {
        final spot = spots[index];
        final formattedDate = spot.createdAt != null
            ? DateFormat.yMMMd().format(spot.createdAt!)
            : 'Recent';

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              context.push('/spots/${spot.id}');
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          spot.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'By ${spot.authorName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                  if (spot.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      spot.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (spot.species.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: spot.species.map((s) {
                        return Chip(
                          label: Text(
                            s,
                            style: const TextStyle(fontSize: 12),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
