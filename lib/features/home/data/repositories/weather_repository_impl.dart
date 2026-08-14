import 'package:dio/dio.dart';
import '../../../../core/network/weather_api_service.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/constants/app_constants.dart';
import '../datasources/weather_local_datasource.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../domain/weather_data.dart';
import '../../domain/location_data.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherApiService _apiService;
  final WeatherLocalDataSource _localDataSource;

  WeatherRepositoryImpl(this._apiService, this._localDataSource);

  @override
  Future<WeatherData> getWeather(double lat, double lng, {String cacheKey = 'default'}) async {
    try {
      final data = await _apiService.getWeather(lat, lng);
      await _localDataSource.cacheWeatherData(data, cacheKey);
      return data;
    } on DioException catch (e) {
      final cached = _localDataSource.getCachedWeather(cacheKey);
      if (cached != null) return cached;
      throw handleDioException(e);
    } catch (e) {
      final cached = _localDataSource.getCachedWeather(cacheKey);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  WeatherData? getCachedWeather(String cacheKey) {
    return _localDataSource.getCachedWeather(cacheKey);
  }

  @override
  bool isCacheValid(String cacheKey) {
    return _localDataSource.isCacheValid(cacheKey, AppConstants.cacheDuration);
  }

  @override
  Future<List<LocationData>> searchCity(String query, {CancelToken? cancelToken}) async {
    try {
      return await _apiService.searchCity(query, cancelToken: cancelToken);
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }

  @override
  Future<LocationData> reverseGeocode(double lat, double lng) async {
    try {
      return await _apiService.reverseGeocode(lat, lng);
    } on DioException catch (e) {
      throw handleDioException(e);
    }
  }
}
