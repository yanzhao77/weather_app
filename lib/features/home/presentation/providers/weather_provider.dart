import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/app_exception.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/weather_data.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/weather_local_datasource.dart';
import '../../../../core/network/weather_api_service.dart';

/// 生成地区缓存/状态 key（经纬度取 4 位小数，稳定且唯一）
String locationKey(double lat, double lng) =>
    '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

// Service & Repository providers
final apiClientProvider = Provider<ApiClient>((ref) {
  // 每次请求动态解析 key：支持应用内运行时配置，无需重新打包
  return ApiClient(
    apiKeyResolver: () => ref.read(apiKeyProvider) ?? '',
  );
});

final weatherApiServiceProvider =
    Provider<WeatherApiService>((ref) {
  return WeatherApiService(ref.watch(apiClientProvider));
});

final localDataSourceProvider =
    Provider<WeatherLocalDataSource>((ref) => WeatherLocalDataSource());

final weatherRepositoryProvider =
    Provider<WeatherRepository>((ref) {
  return WeatherRepositoryImpl(
    ref.watch(weatherApiServiceProvider),
    ref.watch(localDataSourceProvider),
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
  final String _locationKey;

  WeatherNotifier(this._repository, this._locationKey)
      : super(const WeatherState()) {
    _loadCachedData();
  }

  void _loadCachedData() {
    final cached = _repository.getCachedWeather(_locationKey);
    if (cached != null) {
      state = state.copyWith(data: cached, isFromCache: true);
    }
  }

  Future<void> fetchWeather(double lat, double lng, {bool force = false}) async {
    // 缓存未过期时直接展示缓存，避免滑动切换重复请求
    if (!force && state.data != null && _repository.isCacheValid(_locationKey)) {
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    debugPrint('[NEXUS][weather] fetch started lat=$lat lng=$lng key=$_locationKey');
    try {
      final data =
          await _repository.getWeather(lat, lng, cacheKey: _locationKey);
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
    StateNotifierProvider.family<WeatherNotifier, WeatherState, String>(
        (ref, locationKey) {
  final repo = ref.watch(weatherRepositoryProvider);
  return WeatherNotifier(repo, locationKey);
});
