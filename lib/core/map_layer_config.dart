class MapLayerConfig {
  // Layer IDs
  static const String tideStationsId = 'tide_stations';
  static const String depthBathymetryId = 'depth_bathymetry';
  static const String depthNumbersId = 'depth_numbers';
  static const String weatherRadarId = 'weather_radar';
  static const String wavesId = 'waves';
  static const String seaTemperatureId = 'sea_temperature';
  static const String chlorophyllId = 'chlorophyll';
  static const String artificialReefsId = 'artificial_reefs';
  static const String reefHabitatId = 'reef_habitat';
  static const String windObsId = 'wind_obs';

  // URLs
  static const String openStreetMapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String openSeaMapTileUrl =
      'https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png';

  static const String gebcoWmsUrl =
      'https://wms.gebco.net/mapserv?';

  static const String gebcoLayerName = 'GEBCO_LATEST_2';

  static const String noaaChartDisplayWmsUrl =
      'https://gis.charttools.noaa.gov/arcgis/rest/services/MCS/NOAAChartDisplay/MapServer/exts/MaritimeChartService/WMSServer?';

  static const String noaaSoundingsLayerName = '0,1,2,3';

  static const String noaaNowCoastRadarWmsUrl =
      'https://nowcoast.noaa.gov/geoserver/observations/weather_radar/ows?';

  static const String noaaRadarLayerName =
      'conus_base_reflectivity_mosaic';

  static const String noaaTideStationsUrl =
      'https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json?type=tidepredictions';

  static const String noaaTideDataGetterUrl =
      'https://api.tidesandcurrents.noaa.gov/api/prod/datagetter';

  static const String noaaNdbcLatestObsUrl =
      'https://www.ndbc.noaa.gov/data/latest_obs/latest_obs.txt';

  // TODO: Open-Meteo is free for non-commercial use only. A paid API key / subscription plan is required if Seabound is commercialized or monetized.
  static const String openMeteoMarineUrl =
      'https://marine-api.open-meteo.com/v1/marine';

  // NASA GIBS WMTS EPSG:3857 Layer Identifiers
  static const String gibsSstLayerIdentifier =
      'GHRSST_L4_MUR_Sea_Surface_Temperature';
  static const String gibsChlorophyllLayerIdentifier =
      'VIIRS_SNPP_Chlorophyll_A';

  static const String gibsSstTileMatrixSet = '1km';
  static const String gibsChlorophyllTileMatrixSet = '1km';

  static const String gibsSstLegendUrl =
      'https://gibs.earthdata.nasa.gov/legends/GHRSST_MUR_SST_V.png';
  static const String gibsChlorophyllLegendUrl =
      'https://gibs.earthdata.nasa.gov/legends/VIIRS_SNPP_Chlorophyll_A_V.png';

  static String gibsWmtsTileUrl({
    required String layerIdentifier,
    required String dateStr,
    required String tileMatrixSet,
  }) {
    return 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/$layerIdentifier/default/$dateStr/$tileMatrixSet/{z}/{y}/{x}.png';
  }

  // FWC Structure Endpoints
  static const String fwcArtificialReefsQueryUrl =
      'https://gis.myfwc.com/mapping/rest/services/Open_Data/Artificial_Reef_Locations_in_Florida/MapServer/12/query';

  static const String fwcReefHabitatWmsUrl =
      'https://ocean.floridamarine.org/arcgis/rest/services/Projects_FWC/Unified_Florida_Reef_Tract_Map_FWC/MapServer/WMSServer?';

  static const String fwcStructureInfoText =
      'Structure where fish often gather. It does not show where fish are right now. Locations come from FWC and are not independently verified. Not for navigation. Coral and some reef areas have fishing and anchoring rules: check FWC and sanctuary regulations before you go.';
}
