import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scaffold.dart';
import '../../core/floating_top_bar.dart';
import '../../core/navigation_disclaimer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: FloatingTopBar(
        leading: FloatingTopBarButton(
          icon: Icons.close,
          tooltip: 'Close',
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 88, left: 24, right: 24, bottom: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About & Data Sources',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Data Sources',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.anchor),
                          title: Text('Florida Fish & Wildlife Conservation Commission (FWC)'),
                          subtitle: Text(
                              'Artificial Reef Locations & Unified Florida Reef Tract Habitat Map'),
                        ),
                        Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.public),
                          title: Text('NASA GIBS / Worldview'),
                          subtitle: Text(
                              'Sea Surface Temperature (GHRSST MUR) & Chlorophyll-A (VIIRS) Satellite Imagery'),
                        ),
                        Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.tsunami),
                          title: Text('Open-Meteo / DWD'),
                          subtitle: Text(
                              'Global Marine Waves & Swell Forecast API (wave height, period, direction)'),
                        ),
                        Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.water_outlined),
                          title: Text('GEBCO'),
                          subtitle: Text(
                              'General Bathymetric Chart of the Oceans - Elevation & Bathymetry WMS'),
                        ),
                        Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.radar),
                          title: Text('NOAA nowCOAST'),
                          subtitle: Text('CONUS Base Reflectivity Weather Radar Mosaic WMS'),
                        ),
                        Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.pin_drop_outlined),
                          title: Text('NOAA Chart Display Service'),
                          subtitle: Text('Maritime Chart Service WMS Soundings & Depth Numbers'),
                        ),
                        Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.waves),
                          title: Text('NOAA CO-OPS'),
                          subtitle: Text('Tide Prediction Stations & Daily High/Low Predictions API'),
                        ),
                        Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.map_outlined),
                          title: Text('OpenStreetMap & OpenSeaMap'),
                          subtitle: Text('Base Map Tiles & OpenSeaMap Seamarks Overlay'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Disclaimer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .errorContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    NavigationDisclaimer.disclaimerText,
                    style: TextStyle(height: 1.4),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Terms of Service',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Terms of Service: coming soon',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
