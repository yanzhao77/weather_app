import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus_weather/features/home/data/datasources/weather_local_datasource.dart';
import 'package:nexus_weather/features/home/domain/weather_data.dart';

void main() {
  late Directory tempDir;
  late WeatherLocalDataSource ds;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    ds = WeatherLocalDataSource();
    await ds.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  CurrentWeather sampleCurrent() => CurrentWeather(
        timestamp: DateTime(2026, 7, 27, 12),
        temperature: 28,
        feelsLike: 31,
        humidity: 68,
        windSpeed: 3.2,
        windDeg: 120,
        pressure: 1008,
        uvi: 0,
        clouds: 35,
        visibility: 10000,
        dewPoint: 21,
        sunrise: DateTime(2026, 7, 27, 5, 8),
        sunset: DateTime(2026, 7, 27, 18, 53),
        weatherMain: 'Clear',
        weatherDescription: 'clear sky',
        weatherIcon: '01d',
      );

  WeatherData sampleData() => WeatherData(
        current: sampleCurrent(),
        hourly: const [],
        daily: const [],
      );

  test('写入后可读取，字段完整', () async {
    await ds.cacheWeatherData(sampleData(), 'beijing');
    final cached = ds.getCachedWeather('beijing');
    expect(cached, isNotNull);
    expect(cached!.current.temperature, 28);
    expect(cached.current.weatherMain, 'Clear');
    expect(cached.hourly, isEmpty);
  });

  test('不同地区缓存相互独立', () async {
    await ds.cacheWeatherData(sampleData(), 'beijing');
    expect(ds.getCachedWeather('shanghai'), isNull);
    expect(ds.getCachedWeather('beijing'), isNotNull);
  });

  test('缓存时效判断', () async {
    expect(ds.isCacheValid('beijing', const Duration(minutes: 30)), isFalse);
    await ds.cacheWeatherData(sampleData(), 'beijing');
    expect(ds.isCacheValid('beijing', const Duration(minutes: 30)), isTrue);
    expect(ds.isCacheValid('beijing', const Duration(seconds: 0)), isFalse);
  });

  test('损坏数据返回 null 而不是抛异常', () async {
    final box = Hive.box('weather_cache');
    await box.put('weather_broken', {'broken': true});
    expect(ds.getCachedWeather('broken'), isNull);
  });
}
