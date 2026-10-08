import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seabound/features/map_layers/wind_service.dart';

void main() {
  group('NdbcStationObs Model & Conversion Tests', () {
    test('mpsToKnots converts meters/sec to knots correctly', () {
      expect(NdbcStationObs.mpsToKnots(1.0), closeTo(1.94384, 0.001));
      expect(NdbcStationObs.mpsToKnots(5.1), closeTo(9.91358, 0.01));
    });

    test('degreesToCompass returns correct compass direction', () {
      expect(NdbcStationObs.degreesToCompass(0), equals('N'));
      expect(NdbcStationObs.degreesToCompass(90), equals('E'));
      expect(NdbcStationObs.degreesToCompass(180), equals('S'));
      expect(NdbcStationObs.degreesToCompass(270), equals('W'));
      expect(NdbcStationObs.degreesToCompass(null), equals('N/A'));
    });
  });

  group('WindService NDBC Parsing Tests', () {
    test('parses NDBC latest_obs text response correctly', () async {
      const mockResponseBody = '''
#STN       LAT      LON  YYYY MM DD hh mm WDIR WSPD   GST WVHT  DPD APD MWD   PRES  PTDY  ATMP  WTMP  DEWP  VIS   TIDE
#text      deg      deg   yr mo day hr mn degT  m/s   m/s   m   sec sec degT   hPa   hPa  degC  degC  degC  nmi     ft
41009    28.51   -80.18  2026 10 08 21 00 180   5.0   7.0  1.2  MM   MM  MM 1014.8    MM  25.9  26.6    MM   MM     MM
LONF1    24.84   -80.60  2026 10 08 21 00  MM    MM    MM   MM  MM   MM  MM 1015.0    MM  26.0  27.0    MM   MM     MM
''';

      final mockClient = MockClient((request) async {
        return http.Response(mockResponseBody, 200);
      });

      final service = WindService(client: mockClient);
      final stations = await service.fetchNdbcStations();

      expect(stations.length, equals(2));

      final buoy = stations.firstWhere((s) => s.stationId == '41009');
      expect(buoy.latitude, equals(28.51));
      expect(buoy.longitude, equals(-80.18));
      expect(buoy.windDirectionDeg, equals(180.0));
      expect(buoy.windSpeedKnots, closeTo(9.719, 0.01));
      expect(buoy.windGustKnots, closeTo(13.606, 0.01));
      expect(buoy.waveHeightFt, closeTo(3.937, 0.01));

      final lonf1 = stations.firstWhere((s) => s.stationId == 'LONF1');
      expect(lonf1.windDirectionDeg, isNull);
      expect(lonf1.windSpeedKnots, isNull);
      expect(lonf1.windGustKnots, isNull);
    });
  });
}
