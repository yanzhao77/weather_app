import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nexus_weather/core/constants/app_constants.dart';
import 'package:nexus_weather/features/home/domain/location_data.dart';
import 'package:nexus_weather/features/home/domain/repositories/weather_repository.dart';
import 'package:nexus_weather/features/home/domain/weather_data.dart';
import 'package:nexus_weather/features/home/presentation/providers/location_provider.dart';
import 'package:nexus_weather/features/home/presentation/providers/weather_provider.dart';
import 'package:nexus_weather/features/settings/presentation/providers/settings_provider.dart';
import 'package:nexus_weather/main.dart';

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('hive_widget');
    Hive.init(dir.path);
    await Hive.openBox(AppConstants.hiveBoxWeather);
    await Hive.openBox(AppConstants.hiveBoxSettings);
    await Hive.openBox(AppConstants.hiveBoxLocations);
  });

  testWidgets('App should build', (WidgetTester tester) async {
    await initializeDateFormatting('zh_CN');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationProvider.overrideWith((ref) => _FakeLocationNotifier()),
          weatherRepositoryProvider
              .overrideWith((ref) => _FakeWeatherRepository()),
          // 提供 key，确保进入主应用而非 API Key 引导页
          apiKeyProvider.overrideWith((ref) => 'test-key'),
        ],
        child: const NexusWeatherApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(NexusWeatherApp), findsOneWidget);
  });
}

class _FakeLocationNotifier extends LocationNotifier {
  _FakeLocationNotifier() : super() {
    state = const LocationState(
      location:
          LocationData(name: 'Shanghai', latitude: 31.23, longitude: 121.47),
    );
  }

  @override
  Future<void> requestLocation() async {}
}

class _FakeWeatherRepository implements WeatherRepository {
  final WeatherData _weather = _sampleWeather();

  @override
  Future<WeatherData> getWeather(double lat, double lng,
          {String cacheKey = 'default'}) async =>
      _weather;

  @override
  Future<LocationData> reverseGeocode(double lat, double lng) async {
    return const LocationData(
        name: 'Shanghai', latitude: 31.23, longitude: 121.47);
  }

  @override
  Future<List<LocationData>> searchCity(String query,
          {CancelToken? cancelToken}) async =>
      const [
        LocationData(name: 'Shanghai', latitude: 31.23, longitude: 121.47),
      ];

  @override
  WeatherData? getCachedWeather(String cacheKey) => _weather;

  @override
  bool isCacheValid(String cacheKey) => true;
}

WeatherData _sampleWeather() {
  final now = DateTime(2026, 7, 27, 12);
  final current = CurrentWeather(
    timestamp: now,
    temperature: 28,
    feelsLike: 31,
    humidity: 68,
    windSpeed: 3.2,
    windDeg: 120,
    pressure: 1008,
    uvi: 5.4,
    clouds: 35,
    visibility: 10000,
    dewPoint: 21,
    sunrise: DateTime(2026, 7, 27, 5, 8),
    sunset: DateTime(2026, 7, 27, 18, 53),
    weatherMain: 'Clear',
    weatherDescription: 'clear sky',
    weatherIcon: '01d',
  );

  return WeatherData(
    current: current,
    hourly: List.generate(
      12,
      (index) => HourlyWeather(
        timestamp: now.add(Duration(hours: index)),
        temperature: 28 + index * 0.2,
        feelsLike: 31,
        humidity: 68,
        pop: 0,
        weatherIcon: '01d',
        weatherMain: 'Clear',
      ),
    ),
    daily: List.generate(
      7,
      (index) => DailyWeather(
        timestamp: now.add(Duration(days: index)),
        tempMax: 31,
        tempMin: 24,
        weatherIcon: '01d',
        weatherMain: 'Clear',
        pop: 0,
        uvi: 5,
        humidity: 65,
        windSpeed: 3,
      ),
    ),
  );
}
