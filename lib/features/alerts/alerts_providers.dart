import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../map/location_providers.dart';
import 'alerts_repository.dart';
import 'weather_alert_model.dart';

class AlertsState {
  final List<WeatherAlert> alerts;
  final DateTime? lastChecked;
  final bool isLoading;
  final String? errorMessage;
  final bool isOutOfCoverage;

  const AlertsState({
    this.alerts = const [],
    this.lastChecked,
    this.isLoading = false,
    this.errorMessage,
    this.isOutOfCoverage = false,
  });

  AlertsState copyWith({
    List<WeatherAlert>? alerts,
    DateTime? lastChecked,
    bool? isLoading,
    String? errorMessage,
    bool? isOutOfCoverage,
  }) {
    return AlertsState(
      alerts: alerts ?? this.alerts,
      lastChecked: lastChecked ?? this.lastChecked,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isOutOfCoverage: isOutOfCoverage ?? this.isOutOfCoverage,
    );
  }
}

class AlertsNotifier extends Notifier<AlertsState> {
  Timer? _periodicTimer;
  AppLifecycleListener? _lifecycleListener;
  LatLng? _lastQueryPoint;

  @override
  AlertsState build() {
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      refreshAlerts();
    });

    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        refreshAlerts();
      },
    );

    ref.onDispose(() {
      _periodicTimer?.cancel();
      _lifecycleListener?.dispose();
    });

    Future.microtask(() => refreshAlerts());

    return const AlertsState();
  }

  Future<void> refreshAlerts() async {
    LatLng queryPoint = const LatLng(25.7617, -80.1918);

    try {
      final userPosAsync = ref.read(userPositionStreamProvider);
      final Position? pos = userPosAsync.asData?.value;
      if (pos != null) {
        queryPoint = LatLng(pos.latitude, pos.longitude);
      } else {
        final locationService = ref.read(locationServiceProvider);
        final permission = await locationService.checkPermission();
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await locationService.getCurrentPosition();
          queryPoint = LatLng(position.latitude, position.longitude);
        }
      }
    } catch (_) {
      // Fallback to default query point
    }

    _lastQueryPoint = queryPoint;
    await fetchAlertsForPoint(queryPoint.latitude, queryPoint.longitude);
  }

  void onPositionUpdate(Position position) {
    final currentPoint = LatLng(position.latitude, position.longitude);
    if (_lastQueryPoint != null) {
      final distanceInMeters = const Distance().as(
        LengthUnit.Meter,
        _lastQueryPoint!,
        currentPoint,
      );
      if (distanceInMeters >= 5000) {
        refreshAlerts();
      }
    } else {
      refreshAlerts();
    }
  }

  Future<void> fetchAlertsForPoint(double lat, double lon) async {
    state = state.copyWith(isLoading: true);

    final repository = ref.read(alertsRepositoryProvider);

    try {
      final alerts = await repository.fetchActiveAlerts(lat, lon);
      state = AlertsState(
        alerts: alerts,
        lastChecked: DateTime.now(),
        isLoading: false,
        errorMessage: null,
        isOutOfCoverage: false,
      );
    } catch (e) {
      if (e is OutOfCoverageException) {
        state = AlertsState(
          alerts: const [],
          lastChecked: DateTime.now(),
          isLoading: false,
          errorMessage: null,
          isOutOfCoverage: true,
        );
      } else {
        // Honest error state: do NOT wipe alerts or say "no alerts"
        state = state.copyWith(
          isLoading: false,
          errorMessage: "Couldn't check alerts. Do not assume the area is clear.",
          isOutOfCoverage: false,
        );
      }
    }
  }
}

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository();
});

final alertsNotifierProvider =
    NotifierProvider<AlertsNotifier, AlertsState>(AlertsNotifier.new);
