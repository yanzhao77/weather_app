import '../weather_data.dart';
import '../location_data.dart';

import 'package:dio/dio.dart';

abstract class WeatherRepository {
  Future<WeatherData> getWeather(double lat, double lng);
  Future<List<LocationData>> searchCity(String query, {CancelToken? cancelToken});
  Future<LocationData> reverseGeocode(double lat, double lng);
  WeatherData? getCachedWeather();
  bool isCacheValid();
}
