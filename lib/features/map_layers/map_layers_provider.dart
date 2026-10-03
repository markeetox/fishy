import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/map_layer_config.dart';
import 'map_layer_model.dart';

final availableLayers = [
  const MapLayerItem(
    id: MapLayerConfig.tideStationsId,
    displayName: 'Tide Stations',
    icon: Icons.waves,
    defaultOn: true,
  ),
  const MapLayerItem(
    id: MapLayerConfig.depthBathymetryId,
    displayName: 'Depth & Nautical Chart',
    icon: Icons.sailing,
    defaultOn: false,
  ),
  const MapLayerItem(
    id: MapLayerConfig.weatherRadarId,
    displayName: 'Weather Radar',
    icon: Icons.radar,
    defaultOn: false,
  ),
];

class ActiveMapLayersNotifier extends StateNotifier<Set<String>> {
  ActiveMapLayersNotifier()
      : super(
          availableLayers
              .where((layer) => layer.defaultOn)
              .map((layer) => layer.id)
              .toSet(),
        );

  void toggleLayer(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }

  bool isEnabled(String id) => state.contains(id);
}

final activeMapLayersProvider =
    StateNotifierProvider<ActiveMapLayersNotifier, Set<String>>((ref) {
  return ActiveMapLayersNotifier();
});
