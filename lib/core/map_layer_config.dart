class MapLayerConfig {
  // Layer IDs
  static const String tideStationsId = 'tide_stations';
  static const String depthBathymetryId = 'depth_bathymetry';
  static const String weatherRadarId = 'weather_radar';

  // URLs
  static const String openStreetMapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String openSeaMapTileUrl =
      'https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png';

  static const String gebcoWmsUrl =
      'https://www.gebco.net/data_and_products/gebco_web_services/web_map_service/mapserv';

  static const String gebcoLayerName = 'GEBCO_LATEST';

  static const String noaaNowCoastRadarWmsUrl =
      'https://nowcoast.noaa.gov/geoserver/observations/weather_radar/ows';

  static const String noaaRadarLayerName =
      'conus_bref_qct';

  static const String noaaTideStationsUrl =
      'https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json?type=tidepredictions';

  static const String noaaTideDataGetterUrl =
      'https://api.tidesandcurrents.noaa.gov/api/prod/datagetter';
}
