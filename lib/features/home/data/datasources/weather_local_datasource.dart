import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/weather_data.dart';
import '../../../settings/domain/settings_data.dart';

class WeatherLocalDataSource {
  static const String _weatherBox = 'weather_cache';
  static const String _settingsBox = 'user_settings';
  static const String _weatherKey = 'current_weather';
  static const String _lastUpdateKey = 'last_update';
  static const String _settingsKey = 'settings';

  Future<void> init() async {
    await Hive.openBox(_weatherBox);
    await Hive.openBox(_settingsBox);
  }

  Future<void> cacheWeatherData(WeatherData data) async {
    final box = Hive.box(_weatherBox);
    await box.put(_weatherKey, data.toJson());
    await box.put(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  WeatherData? getCachedWeather() {
    final box = Hive.box(_weatherBox);
    final data = box.get(_weatherKey);
    if (data == null) return null;
    try {
      return WeatherData.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (_) {
      return null;
    }
  }

  DateTime? getLastUpdateTime() {
    final box = Hive.box(_weatherBox);
    final time = box.get(_lastUpdateKey) as String?;
    if (time == null) return null;
    return DateTime.tryParse(time);
  }

  bool isCacheValid(Duration maxAge) {
    final lastUpdate = getLastUpdateTime();
    if (lastUpdate == null) return false;
    return DateTime.now().difference(lastUpdate) < maxAge;
  }

  Future<void> saveSettings(SettingsData settings) async {
    final box = Hive.box(_settingsBox);
    await box.put(_settingsKey, settings.toJson());
  }

  SettingsData getSettings() {
    final box = Hive.box(_settingsBox);
    final data = box.get(_settingsKey);
    if (data == null) return const SettingsData();
    try {
      return SettingsData.fromJson(
          Map<String, dynamic>.from(data as Map));
    } catch (_) {
      return const SettingsData();
    }
  }
}
