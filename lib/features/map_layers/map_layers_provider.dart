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
    id: MapLayerConfig.wavesId,
    displayName: 'Waves (Open-Meteo)',
    icon: Icons.tsunami,
    defaultOn: false,
  ),
  const MapLayerItem(
    id: MapLayerConfig.depthBathymetryId,
    displayName: 'Depth & Bathymetry',
    icon: Icons.water,
    defaultOn: false,
  ),
  const MapLayerItem(
    id: MapLayerConfig.depthNumbersId,
    displayName: 'Depth Numbers (NOAA Soundings)',
    icon: Icons.pin_drop_outlined,
    defaultOn: false,
  ),
  const MapLayerItem(
    id: MapLayerConfig.weatherRadarId,
    displayName: 'Weather Radar',
    icon: Icons.radar,
    defaultOn: false,
  ),
];

class ActiveMapLayersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return availableLayers
        .where((layer) => layer.defaultOn)
        .map((layer) => layer.id)
        .toSet();
  }

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
    NotifierProvider<ActiveMapLayersNotifier, Set<String>>(() {
  return ActiveMapLayersNotifier();
});
