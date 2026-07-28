import 'package:dio/dio.dart';
import '../../../../core/network/weather_api_service.dart';
import '../../../../core/error/app_exception.dart';
import '../datasources/weather_local_datasource.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../domain/weather_data.dart';
import '../../domain/location_data.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherApiService _apiService;
  final WeatherLocalDataSource _localDataSource;

  WeatherRepositoryImpl(this._apiService, this._localDataSource);

  @override
  Future<WeatherData> getWeather(double lat, double lng) async {
    try {
      final data = await _apiService.getWeather(lat, lng);
      await _localDataSource.cacheWeatherData(data);
      return data;
    } on DioException catch (e) {
      final cached = _localDataSource.getCachedWeather();
      if (cached != null) return cached;
      throw handleDioException(e);
    } catch (e) {
      final cached = _localDataSource.getCachedWeather();
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  WeatherData? getCachedWeather() {
    return _localDataSource.getCachedWeather();
  }

  @override
  bool isCacheValid() {
    return _localDataSource.isCacheValid(const Duration(minutes: 30));
  }

  @override
  Future<List<LocationData>> searchCity(String query) async {
    try {
      return await _apiService.searchCity(query);
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
