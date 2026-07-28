import '../weather_data.dart';
import '../location_data.dart';

abstract class WeatherRepository {
  Future<WeatherData> getWeather(double lat, double lng);
  Future<List<LocationData>> searchCity(String query);
  Future<LocationData> reverseGeocode(double lat, double lng);
  WeatherData? getCachedWeather();
  bool isCacheValid();
}
