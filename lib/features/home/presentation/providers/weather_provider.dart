import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/weather_data.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/weather_local_datasource.dart';
import '../../../../core/network/weather_api_service.dart';

// Service & Repository providers
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final weatherApiServiceProvider =
    Provider<WeatherApiService>((ref) {
  return WeatherApiService(ref.read(apiClientProvider));
});

final localDataSourceProvider =
    Provider<WeatherLocalDataSource>((ref) => WeatherLocalDataSource());

final weatherRepositoryProvider =
    Provider<WeatherRepository>((ref) {
  return WeatherRepositoryImpl(
    ref.read(weatherApiServiceProvider),
    ref.read(localDataSourceProvider),
  );
});

// State
class WeatherState {
  final WeatherData? data;
  final bool isLoading;
  final String? error;
  final bool isFromCache;

  const WeatherState({
    this.data,
    this.isLoading = false,
    this.error,
    this.isFromCache = false,
  });

  WeatherState copyWith({
    WeatherData? data,
    bool? isLoading,
    String? error,
    bool? isFromCache,
  }) {
    return WeatherState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

class WeatherNotifier extends StateNotifier<WeatherState> {
  final WeatherRepository _repository;

  WeatherNotifier(this._repository) : super(const WeatherState()) {
    _loadCachedData();
  }

  void _loadCachedData() {
    final cached = _repository.getCachedWeather();
    if (cached != null) {
      state = state.copyWith(data: cached, isFromCache: true);
    }
  }

  Future<void> fetchWeather(double lat, double lng) async {
    state = state.copyWith(isLoading: true, error: null);
    debugPrint('[NEXUS][weather] fetch started lat=$lat lng=$lng');
    try {
      final data = await _repository.getWeather(lat, lng);
      debugPrint('[NEXUS][weather] fetch success temp=${data.current.temperature}');
      state = WeatherState(data: data, isLoading: false);
    } catch (e) {
      final message = e is AppException ? e.message : '未知错误';
      debugPrint('[NEXUS][weather] fetch failed: $message');
      // If we had cached data, keep showing it
      if (state.data != null) {
        state = state.copyWith(
          isLoading: false,
          error: '更新失败：$message，显示缓存数据',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '加载天气失败：$message',
        );
      }
    }
  }
}

final weatherProvider =
    StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  final repo = ref.read(weatherRepositoryProvider);
  return WeatherNotifier(repo);
});
