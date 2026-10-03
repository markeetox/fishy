import 'package:flutter/material.dart';

class MapLayerItem {
  final String id;
  final String displayName;
  final IconData icon;
  final bool defaultOn;

  const MapLayerItem({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.defaultOn,
  });
}
