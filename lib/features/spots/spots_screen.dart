import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/map_layer_config.dart';
import '../../core/navigation_disclaimer.dart';
import '../alerts/alerts_providers.dart';
import '../map/location_providers.dart';
import '../map_layers/map_layers_provider.dart';
import '../map_layers/map_layers_sheet.dart';
import '../map_layers/tide_providers.dart';
import '../map_layers/tide_service.dart';
import '../map_layers/waves_provider.dart';
import '../map_layers/waves_service.dart';
import '../profile/badge_service.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationDisclaimer.showFirstLaunchDialogIfNeeded(context);
    });
  }

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
        error: (error, stackTrace) => Center(
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

class _SpotsMapView extends ConsumerStatefulWidget {
  final List<Spot> spots;

  const _SpotsMapView({required this.spots});

  @override
  ConsumerState<_SpotsMapView> createState() => _SpotsMapViewState();
}

class _SpotsMapViewState extends ConsumerState<_SpotsMapView> {
  final MapController _mapController = MapController();
  LatLngBounds? _currentBounds;
  double _currentZoom = 9.0;
  bool _isLocating = false;

  Timer? _wavesDebounceTimer;
  List<WavePointData>? _wavesData;
  String? _wavesError;

  @override
  void dispose() {
    _wavesDebounceTimer?.cancel();
    super.dispose();
  }

  void _openLayersSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const MapLayersSheet(),
    );
  }

  void _showTidePredictionDialog(TideStation station) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _TidePredictionDialog(station: station);
      },
    );
  }

  void _showWaveDetailSheet(WavePointData point, int hourOffset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _WaveDetailSheet(point: point, hourOffset: hourOffset),
    );
  }

  void _fetchWavesForBounds(LatLngBounds bounds) {
    _wavesDebounceTimer?.cancel();
    _wavesDebounceTimer = Timer(const Duration(milliseconds: 800), () async {
      if (!mounted) return;

      final activeLayers = ref.read(activeMapLayersProvider);
      if (!activeLayers.contains(MapLayerConfig.wavesId)) return;

      if (_currentZoom < 5.0) return;

      setState(() {
        _wavesError = null;
      });

      try {
        final wavesService = ref.read(wavesServiceProvider);
        final data = await wavesService.fetchGridWaves(
          minLat: bounds.south,
          maxLat: bounds.north,
          minLng: bounds.west,
          maxLng: bounds.east,
        );

        if (mounted) {
          setState(() {
            _wavesData = data;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _wavesError = e.toString().replaceAll('Exception: ', '');
          });
        }
      }
    });
  }

  Future<void> _centerOnMyLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      final userLatLng = LatLng(position.latitude, position.longitude);

      _mapController.move(userLatLng, 13.0);

      final result = await ref.read(badgeServiceProvider).onMyLocationTapped();
      if (mounted) {
        showBadgeUnlocks(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Color _getWaveColor(double waveHeightFt) {
    if (waveHeightFt < 2.0) {
      return Colors.green.shade600;
    } else if (waveHeightFt < 4.0) {
      return Colors.amber.shade700;
    } else if (waveHeightFt < 6.0) {
      return Colors.orange.shade800;
    } else {
      return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLayers = ref.watch(activeMapLayersProvider);
    final tideStationsAsync = ref.watch(tideStationsProvider);
    final userPositionAsync = ref.watch(userPositionStreamProvider);
    final alertsState = ref.watch(alertsNotifierProvider);
    final waveHourOffset = ref.watch(selectedWaveHourOffsetProvider);

    final showTides = activeLayers.contains(MapLayerConfig.tideStationsId);
    final showWaves = activeLayers.contains(MapLayerConfig.wavesId);
    final showDepth = activeLayers.contains(MapLayerConfig.depthBathymetryId);
    final showSoundings = activeLayers.contains(MapLayerConfig.depthNumbersId);
    final showRadar = activeLayers.contains(MapLayerConfig.weatherRadarId);

    final initialCenter = widget.spots.isNotEmpty
        ? LatLng(widget.spots.first.latitude, widget.spots.first.longitude)
        : const LatLng(25.7617, -80.1918);

    ref.listen<Set<String>>(activeMapLayersProvider, (prev, next) {
      if (next.contains(MapLayerConfig.wavesId) && _currentBounds != null) {
        _fetchWavesForBounds(_currentBounds!);
      }
    });

    ref.listen<AsyncValue<List<TideStation>>>(tideStationsProvider, (prev, next) {
      if (next.hasError && showTides) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load tide stations: ${next.error}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final Position? userPos = userPositionAsync.asData?.value;
    final LatLng? userLatLng =
        userPos != null ? LatLng(userPos.latitude, userPos.longitude) : null;

    final mostSevereAlert =
        alertsState.alerts.isNotEmpty ? alertsState.alerts.first : null;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: widget.spots.isNotEmpty ? 10.0 : 9.0,
            onMapReady: () {
              final bounds = _mapController.camera.visibleBounds;
              setState(() {
                _currentBounds = bounds;
                _currentZoom = _mapController.camera.zoom;
              });
              if (showWaves) {
                _fetchWavesForBounds(bounds);
              }
            },
            onPositionChanged: (position, hasGesture) {
              setState(() {
                _currentBounds = position.visibleBounds;
                _currentZoom = position.zoom;
              });
              if (showWaves) {
                _fetchWavesForBounds(position.visibleBounds);
              }
            },
          ),
          children: [
            // Base Tile Layer
            TileLayer(
              urlTemplate: MapLayerConfig.openStreetMapTileUrl,
              userAgentPackageName: 'com.onerevamp.seabound',
            ),

            // Depth & Bathymetry Layer (GEBCO colour-shaded WMS + OpenSeaMap seamarks)
            if (showDepth) ...[
              TileLayer(
                wmsOptions: WMSTileLayerOptions(
                  baseUrl: MapLayerConfig.gebcoWmsUrl,
                  layers: [MapLayerConfig.gebcoLayerName],
                ),
                tileProvider: NetworkTileProvider(),
                tileDisplay: const TileDisplay.instantaneous(opacity: 0.7),
              ),
              TileLayer(
                urlTemplate: MapLayerConfig.openSeaMapTileUrl,
                userAgentPackageName: 'com.onerevamp.seabound',
                tileDisplay: const TileDisplay.instantaneous(opacity: 0.8),
              ),
            ],

            // Depth Numbers (NOAA Soundings) WMS Layer
            if (showSoundings)
              TileLayer(
                wmsOptions: WMSTileLayerOptions(
                  baseUrl: MapLayerConfig.noaaChartDisplayWmsUrl,
                  layers: MapLayerConfig.noaaSoundingsLayerName.split(','),
                  transparent: true,
                  format: 'image/png',
                ),
                tileProvider: NetworkTileProvider(),
                tileDisplay: const TileDisplay.instantaneous(opacity: 0.85),
              ),

            // Weather Radar WMS Layer
            if (showRadar)
              TileLayer(
                wmsOptions: WMSTileLayerOptions(
                  baseUrl: MapLayerConfig.noaaNowCoastRadarWmsUrl,
                  layers: [MapLayerConfig.noaaRadarLayerName],
                  transparent: true,
                  format: 'image/png',
                ),
                tileProvider: NetworkTileProvider(),
                tileDisplay: const TileDisplay.instantaneous(opacity: 0.6),
              ),

            // Waves Grid Markers Layer
            if (showWaves && _wavesData != null && _currentZoom >= 5.0)
              MarkerLayer(
                markers: _wavesData!.map((point) {
                  final entry = point.getForOffset(waveHourOffset);
                  final waveColor = _getWaveColor(entry.waveHeightFt);
                  final directionRad = entry.waveDirectionDeg != null
                      ? (entry.waveDirectionDeg! * (3.1415926535 / 180.0))
                      : 0.0;

                  return Marker(
                    point: LatLng(point.latitude, point.longitude),
                    width: 50.0,
                    height: 50.0,
                    child: GestureDetector(
                      onTap: () => _showWaveDetailSheet(point, waveHourOffset),
                      child: Container(
                        decoration: BoxDecoration(
                          color: waveColor.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (entry.waveDirectionDeg != null)
                              Transform.rotate(
                                angle: directionRad,
                                child: const Icon(
                                  Icons.arrow_upward,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            Text(
                              '${entry.waveHeightFt.toStringAsFixed(1)}ft',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            // User Position Accuracy Circle & Marker Layer
            if (userLatLng != null) ...[
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: userLatLng,
                    radius: (userPos?.accuracy ?? 15.0).clamp(10.0, 100.0),
                    useRadiusInMeter: true,
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderColor: Colors.blue.withValues(alpha: 0.6),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: userLatLng,
                    width: 22.0,
                    height: 22.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Tide Stations Marker Layer
            if (showTides)
              tideStationsAsync.when(
                data: (stations) {
                  final visibleStations = stations.where((station) {
                    if (_currentBounds == null) return true;
                    final point = LatLng(station.lat, station.lng);
                    return _currentBounds!.contains(point);
                  }).toList();

                  return MarkerLayer(
                    markers: visibleStations.map((station) {
                      return Marker(
                        point: LatLng(station.lat, station.lng),
                        width: 32.0,
                        height: 32.0,
                        child: GestureDetector(
                          onTap: () => _showTidePredictionDialog(station),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.waves,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),

            // Spot Markers Layer
            MarkerLayer(
              markers: widget.spots.map((spot) {
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
                if (showWaves)
                  TextSourceAttribution(
                    'Wave data: Open-Meteo / DWD',
                    onTap: () {},
                  ),
                TextSourceAttribution(
                  'OpenStreetMap & NOAA contributors',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),

        // Slim Weather Alert Banner Overlay at top of map
        if (mostSevereAlert != null)
          Positioned(
            top: 12,
            left: 12,
            right: 68,
            child: GestureDetector(
              onTap: () {
                context.go('/alerts');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _alertSeverityColor(mostSevereAlert.severity),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${mostSevereAlert.event} (${mostSevereAlert.severity})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),

        // Waves Error Banner Overlay
        if (showWaves && _wavesError != null)
          Positioned(
            top: mostSevereAlert != null ? 58 : 16,
            left: 16,
            right: 68,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Couldn't load wave data",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      if (_currentBounds != null) {
                        _fetchWavesForBounds(_currentBounds!);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),

        // Wave Height Color Scale Legend Widget
        if (showWaves && _wavesError == null)
          Positioned(
            top: mostSevereAlert != null ? 58 : 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Wave Height (ft)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _LegendBox(color: Colors.green.shade600, label: '<2'),
                      const SizedBox(width: 4),
                      _LegendBox(color: Colors.amber.shade700, label: '2-4'),
                      const SizedBox(width: 4),
                      _LegendBox(color: Colors.orange.shade800, label: '4-6'),
                      const SizedBox(width: 4),
                      _LegendBox(color: Colors.red.shade700, label: '>6'),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Waves Time Control Widget Bar (Now, +3h, +6h, +12h, +24h)
        if (showWaves)
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _WaveTimeButton(label: 'Now', offset: 0),
                    _WaveTimeButton(label: '+3h', offset: 3),
                    _WaveTimeButton(label: '+6h', offset: 6),
                    _WaveTimeButton(label: '+12h', offset: 12),
                    _WaveTimeButton(label: '+24h', offset: 24),
                  ],
                ),
              ),
            ),
          ),

        // Map Control FABs: Layers & My Location
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'map_layers_fab',
                onPressed: _openLayersSheet,
                tooltip: 'Map Layers',
                child: const Icon(Icons.layers_outlined),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'map_my_location_fab',
                onPressed: _isLocating ? null : _centerOnMyLocation,
                tooltip: 'My Location',
                child: _isLocating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
            ],
          ),
        ),

        // Low-contrast Disclaimer Banner along bottom edge
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => NavigationDisclaimer.showFullDisclaimerDialog(context),
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: const Text(
                'Not for navigation. Tap for details.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _alertSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme':
        return Colors.red.shade900;
      case 'severe':
        return Colors.red.shade700;
      case 'moderate':
        return Colors.orange.shade900;
      case 'minor':
        return Colors.amber.shade900;
      default:
        return Colors.blueGrey.shade800;
    }
  }
}

class _LegendBox extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendBox({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 22,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 9),
        ),
      ],
    );
  }
}

class _WaveTimeButton extends ConsumerWidget {
  final String label;
  final int offset;

  const _WaveTimeButton({required this.label, required this.offset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOffset = ref.watch(selectedWaveHourOffsetProvider);
    final isSelected = currentOffset == offset;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (_) {
          ref.read(selectedWaveHourOffsetProvider.notifier).setHourOffset(offset);
        },
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _WaveDetailSheet extends StatelessWidget {
  final WavePointData point;
  final int hourOffset;

  const _WaveDetailSheet({required this.point, required this.hourOffset});

  @override
  Widget build(BuildContext context) {
    final currentEntry = point.getForOffset(hourOffset);
    final formattedTime = DateFormat.jm().format(currentEntry.time);

    final compassDir =
        HourlyWaveEntry.degreesToCompass(currentEntry.waveDirectionDeg);

    final next24Entries = point.hourlyEntries.where((e) {
      return e.time.isAfter(currentEntry.time) &&
          e.time.isBefore(currentEntry.time.add(const Duration(hours: 25)));
    }).take(24).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wave Conditions ($formattedTime)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Point: ${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailMetric(
                          label: 'Wave Height',
                          value:
                              '${currentEntry.waveHeightFt.toStringAsFixed(1)} ft',
                          icon: Icons.water,
                        ),
                        _DetailMetric(
                          label: 'Direction',
                          value: '$compassDir (${currentEntry.waveDirectionDeg?.toStringAsFixed(0)}°)',
                          icon: Icons.explore,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailMetric(
                          label: 'Wave Period',
                          value: currentEntry.wavePeriodSec != null
                              ? '${currentEntry.wavePeriodSec!.toStringAsFixed(1)} s'
                              : 'N/A',
                          icon: Icons.timer_outlined,
                        ),
                        _DetailMetric(
                          label: 'Swell Height',
                          value: currentEntry.swellHeightFt != null
                              ? '${currentEntry.swellHeightFt!.toStringAsFixed(1)} ft'
                              : 'N/A',
                          icon: Icons.waves,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Period: time between waves (longer periods = smooth swell, short = choppy waves).',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Next 24-Hour Forecast',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: next24Entries.length,
                itemBuilder: (context, index) {
                  final entry = next24Entries[index];
                  final timeLabel = DateFormat.j().format(entry.time);

                  return Card(
                    margin: const EdgeInsets.only(right: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            timeLabel,
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.waveHeightFt.toStringAsFixed(1)} ft',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (entry.wavePeriodSec != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${entry.wavePeriodSec!.toStringAsFixed(0)}s',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}

class _TidePredictionDialog extends ConsumerWidget {
  final TideStation station;

  const _TidePredictionDialog({required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionsAsync =
        ref.watch(stationPredictionsProvider(station.id));

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.waves,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  station.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          if (station.state.isNotEmpty)
            Text(
              'Station ID: ${station.id} (${station.state})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: predictionsAsync.when(
          data: (predictions) {
            if (predictions.isEmpty) {
              return const Text('No tide predictions available for today.');
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's High / Low Tides:",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                ...predictions.map((p) {
                  final isHigh = p.type.toUpperCase() == 'H';
                  final timeStr = DateFormat.jm().format(p.time);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isHigh
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                              color: isHigh ? Colors.blue : Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isHigh ? 'High Tide' : 'Low Tide',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text('$timeStr (${p.value.toStringAsFixed(1)} ft)'),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Text(
            'Unable to fetch tide predictions: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
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
                  InkWell(
                    onTap: spot.userId.isNotEmpty
                        ? () => context.push('/profile/user/${spot.userId}')
                        : null,
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
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
