import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/map_layer_config.dart';

class NdbcStationObs {
  final String stationId;
  final double latitude;
  final double longitude;
  final DateTime observationTime;
  final double? windDirectionDeg;
  final double? windSpeedKnots;
  final double? windGustKnots;
  final double? waveHeightFt;

  const NdbcStationObs({
    required this.stationId,
    required this.latitude,
    required this.longitude,
    required this.observationTime,
    this.windDirectionDeg,
    this.windSpeedKnots,
    this.windGustKnots,
    this.waveHeightFt,
  });

  static double mpsToKnots(double mps) => mps * 1.94384;
  static double metersToFeet(double meters) => meters * 3.28084;

  static String degreesToCompass(double? degrees) {
    if (degrees == null) return 'N/A';
    const directions = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'
    ];
    final index = ((degrees + 11.25) % 360 / 22.5).floor();
    return directions[index];
  }
}

class NdbcCacheEntry {
  final List<NdbcStationObs> stations;
  final DateTime fetchedAt;

  NdbcCacheEntry({
    required this.stations,
    required this.fetchedAt,
  });

  bool get isValid => DateTime.now().difference(fetchedAt).inMinutes < 15;
}

class WindService {
  final http.Client _client;
  static NdbcCacheEntry? _ndbcCache;

  WindService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<NdbcStationObs>> fetchNdbcStations() async {
    if (_ndbcCache != null && _ndbcCache!.isValid) {
      return _ndbcCache!.stations;
    }

    final response = await _client.get(
      Uri.parse(MapLayerConfig.noaaNdbcLatestObsUrl),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load NOAA NDBC buoy observations (code: ${response.statusCode})',
      );
    }

    final lines = const LineSplitter().convert(response.body);
    final stations = <NdbcStationObs>[];

    for (final line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;

      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 11) continue;

      final stnId = parts[0];
      final lat = double.tryParse(parts[1]);
      final lon = double.tryParse(parts[2]);

      if (lat == null || lon == null) continue;

      final year = int.tryParse(parts[3]) ?? DateTime.now().year;
      final month = int.tryParse(parts[4]) ?? DateTime.now().month;
      final day = int.tryParse(parts[5]) ?? DateTime.now().day;
      final hour = int.tryParse(parts[6]) ?? 0;
      final minute = int.tryParse(parts[7]) ?? 0;

      final time = DateTime.utc(year, month, day, hour, minute);

      final rawWdir = parts[8] != 'MM' ? double.tryParse(parts[8]) : null;
      final rawWspd = parts[9] != 'MM' ? double.tryParse(parts[9]) : null;
      final rawGst = parts[10] != 'MM' ? double.tryParse(parts[10]) : null;
      final rawWvht = parts.length > 11 && parts[11] != 'MM'
          ? double.tryParse(parts[11])
          : null;

      stations.add(
        NdbcStationObs(
          stationId: stnId,
          latitude: lat,
          longitude: lon,
          observationTime: time,
          windDirectionDeg: rawWdir,
          windSpeedKnots: rawWspd != null ? NdbcStationObs.mpsToKnots(rawWspd) : null,
          windGustKnots: rawGst != null ? NdbcStationObs.mpsToKnots(rawGst) : null,
          waveHeightFt: rawWvht != null ? NdbcStationObs.metersToFeet(rawWvht) : null,
        ),
      );
    }

    _ndbcCache = NdbcCacheEntry(
      stations: stations,
      fetchedAt: DateTime.now(),
    );

    return stations;
  }
}
