import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/weather_data.dart';

class WeatherLocalDataSource {
  static const String _weatherBox = AppConstants.hiveBoxWeather;
  static const String _lastUpdateKeyPrefix = 'last_update_';

  Future<void> init() async {
    await Hive.openBox(_weatherBox);
  }

  static String _weatherKey(String locationKey) => 'weather_$locationKey';
  static String _lastUpdateKey(String locationKey) => '$_lastUpdateKeyPrefix$locationKey';

  Future<void> cacheWeatherData(WeatherData data, String locationKey) async {
    final box = Hive.box(_weatherBox);
    await box.putAll({
      _weatherKey(locationKey): data.toJson(),
      _lastUpdateKey(locationKey): DateTime.now().toIso8601String(),
    });
  }

  WeatherData? getCachedWeather(String locationKey) {
    final box = Hive.box(_weatherBox);
    final data = box.get(_weatherKey(locationKey));
    if (data == null) return null;
    try {
      return WeatherData.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (_) {
      return null;
    }
  }

  DateTime? getLastUpdateTime(String locationKey) {
    final box = Hive.box(_weatherBox);
    final time = box.get(_lastUpdateKey(locationKey)) as String?;
    if (time == null) return null;
    return DateTime.tryParse(time);
  }

  bool isCacheValid(String locationKey, Duration maxAge) {
    final lastUpdate = getLastUpdateTime(locationKey);
    if (lastUpdate == null) return false;
    return DateTime.now().difference(lastUpdate) < maxAge;
  }

}
