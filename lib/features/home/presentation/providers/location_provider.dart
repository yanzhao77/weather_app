import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/location_data.dart';

class LocationState {
  final LocationData? location;
  final bool isLoading;
  final String? error;
  final bool permissionDenied;

  const LocationState({
    this.location,
    this.isLoading = false,
    this.error,
    this.permissionDenied = false,
  });

  LocationState copyWith({
    LocationData? location,
    bool? isLoading,
    String? error,
    bool? permissionDenied,
  }) {
    return LocationState(
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState());

  Future<void> requestLocation() async {
    state = state.copyWith(isLoading: true, error: null);
    debugPrint('[NEXUS][location] request started');

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[NEXUS][location] serviceEnabled=$serviceEnabled');
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          error: '定位服务未开启',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[NEXUS][location] current permission=$permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[NEXUS][location] requested permission=$permission');
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            isLoading: false,
            permissionDenied: true,
            error: '定位权限被拒绝',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false,
          permissionDenied: true,
          error: '定位权限被永久拒绝，请在系统设置中开启',
        );
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        debugPrint(
          '[NEXUS][location] lastKnown=${position.latitude},${position.longitude} accuracy=${position.accuracy}',
        );
      }

      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          forceAndroidLocationManager: true,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (e) {
        debugPrint('[NEXUS][location] android location manager failed: $e');
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 8),
          );
        } catch (fallbackError) {
          debugPrint('[NEXUS][location] fused provider failed: $fallbackError');
          if (position == null) rethrow;
        }
      }

      debugPrint(
        '[NEXUS][location] position=${position.latitude},${position.longitude} accuracy=${position.accuracy}',
      );

      state = state.copyWith(
        location: LocationData(
          name: '',
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[NEXUS][location] failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: '获取位置失败: $e',
      );
    }
  }

  void setLocation(LocationData loc) {
    state = state.copyWith(location: loc, error: null);
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
