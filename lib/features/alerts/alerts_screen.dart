import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../map/location_providers.dart';
import '../profile/badge_service.dart';
import 'alerts_providers.dart';
import 'weather_alert_model.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(badgeServiceProvider).onAlertsOpened(context);
    });
  }

  void _showAlertDetail(BuildContext context, WeatherAlert alert) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                alert.event,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              _SeverityChip(severity: alert.severity),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (alert.areaDesc.isNotEmpty) ...[
                  Text(
                    'Affected Area:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(alert.areaDesc),
                  const SizedBox(height: 12),
                ],
                if (alert.headline.isNotEmpty) ...[
                  Text(
                    alert.headline,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (alert.description.isNotEmpty) ...[
                  Text(
                    'Description:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(alert.description),
                  const SizedBox(height: 12),
                ],
                if (alert.instruction.isNotEmpty) ...[
                  Text(
                    'Instructions:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(alert.instruction),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Sender: ${alert.senderName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertsState = ref.watch(alertsNotifierProvider);
    final alertsNotifier = ref.read(alertsNotifierProvider.notifier);

    // Listen to user movement > 5km
    ref.listen<AsyncValue<Position>>(userPositionStreamProvider, (prev, next) {
      if (next.hasValue) {
        alertsNotifier.onPositionUpdate(next.value!);
      }
    });

    final lastCheckedStr = alertsState.lastChecked != null
        ? DateFormat.jm().format(alertsState.lastChecked!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather & Marine Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Alerts',
            onPressed: alertsState.isLoading
                ? null
                : () => alertsNotifier.refreshAlerts(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // Header status / timestamp bar
              if (lastCheckedStr != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Last checked $lastCheckedStr',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (alertsState.isLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),

              // Main body area
              Expanded(
                child: _buildBodyContent(context, alertsState, lastCheckedStr),
              ),

              // Mandatory Footer Disclaimer
              Container(
                padding: const EdgeInsets.all(12.0),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                width: double.infinity,
                child: Text(
                  'Alerts are checked only while Seabound is open and may be delayed. Always check weather.gov and VHF marine radio for official warnings.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 11,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent(
    BuildContext context,
    AlertsState state,
    String? lastCheckedStr,
  ) {
    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isOutOfCoverage) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.public_off,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Active weather alerts are unavailable for this point.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'National Weather Service active alert coverage is limited to US coastal and inland areas.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                lastCheckedStr != null
                    ? 'No active alerts for this location as of $lastCheckedStr.'
                    : 'No active weather alerts for this location.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: state.alerts.length,
      itemBuilder: (context, index) {
        final alert = state.alerts[index];
        final effectiveStr = alert.effective != null
            ? DateFormat.jm().format(alert.effective!)
            : null;
        final expiresStr = alert.expires != null
            ? DateFormat.jm().format(alert.expires!)
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showAlertDetail(context, alert),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (alert.isMarineRelated) ...[
                              Icon(
                                Icons.phishing,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                alert.event,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SeverityChip(severity: alert.severity),
                    ],
                  ),
                  if (alert.areaDesc.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            alert.areaDesc,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (effectiveStr != null || expiresStr != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Valid: ${effectiveStr ?? 'Now'} – ${expiresStr ?? 'Until further notice'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
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

class _SeverityChip extends StatelessWidget {
  final String severity;

  const _SeverityChip({required this.severity});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (severity.toLowerCase()) {
      case 'extreme':
        backgroundColor = Colors.red.shade900;
        break;
      case 'severe':
        backgroundColor = Colors.red.shade600;
        break;
      case 'moderate':
        backgroundColor = Colors.orange.shade800;
        break;
      case 'minor':
        backgroundColor = Colors.amber.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
