import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/map_layer_config.dart';

class GibsDateService {
  final http.Client _client;
  static final Map<String, String> _dateCache = {};

  GibsDateService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> getLatestAvailableDate({
    required String layerIdentifier,
    required String tileMatrixSet,
  }) async {
    if (_dateCache.containsKey(layerIdentifier)) {
      return _dateCache[layerIdentifier]!;
    }

    final today = DateTime.now().toUtc();

    for (int daysBack = 1; daysBack <= 3; daysBack++) {
      final probeDate = today.subtract(Duration(days: daysBack));
      final dateStr = DateFormat('yyyy-MM-dd').format(probeDate);

      // Probe test tile for Florida region at zoom level 6
      final url =
          'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/$layerIdentifier/default/$dateStr/$tileMatrixSet/6/26/34.png';

      try {
        final response = await _client.head(Uri.parse(url));
        if (response.statusCode == 200) {
          _dateCache[layerIdentifier] = dateStr;
          return dateStr;
        }
      } catch (_) {}
    }

    // Fallback to T-1 if probe fails
    final fallbackDate = DateFormat('yyyy-MM-dd')
        .format(today.subtract(const Duration(days: 1)));
    _dateCache[layerIdentifier] = fallbackDate;
    return fallbackDate;
  }

  static String formatDisplayDate(String isoDateStr) {
    try {
      final parsed = DateTime.parse(isoDateStr);
      return DateFormat('MMM d').format(parsed);
    } catch (_) {
      return isoDateStr;
    }
  }
}

final gibsDateServiceProvider = Provider<GibsDateService>((ref) {
  return GibsDateService();
});

final sstDateProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(gibsDateServiceProvider);
  return service.getLatestAvailableDate(
    layerIdentifier: MapLayerConfig.gibsSstLayerIdentifier,
    tileMatrixSet: MapLayerConfig.gibsSstTileMatrixSet,
  );
});

final chlorophyllDateProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(gibsDateServiceProvider);
  return service.getLatestAvailableDate(
    layerIdentifier: MapLayerConfig.gibsChlorophyllLayerIdentifier,
    tileMatrixSet: MapLayerConfig.gibsChlorophyllTileMatrixSet,
  );
});
