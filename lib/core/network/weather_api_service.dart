import 'package:flutter/foundation.dart';
import 'package:nexus_weather/core/network/api_client.dart';
import 'package:nexus_weather/core/constants/api_endpoints.dart';
import 'package:nexus_weather/core/constants/app_constants.dart';
import 'package:nexus_weather/features/home/domain/weather_data.dart';
import 'package:nexus_weather/features/home/domain/location_data.dart';

class WeatherApiService {
  final ApiClient _client;

  WeatherApiService(this._client);

  /// Uses free v2.5 endpoints: /weather + /forecast
  /// Combines them into WeatherData matching the domain model
  Future<WeatherData> getWeather(double lat, double lng) async {
    debugPrint('[NEXUS][api] GET /weather lat=$lat lon=$lng');
    // Fetch current weather
    final currentResp = await _client.get(
      '/weather',
      queryParameters: {'lat': lat, 'lon': lng},
    );
    final currentJson = currentResp.data as Map<String, dynamic>;
    debugPrint('[NEXUS][api] /weather status=${currentResp.statusCode} city=${currentJson['name']}');
    final current = _parseCurrentWeather(currentJson);

    List<HourlyWeather> hourly;
    List<DailyWeather> daily;
    try {
      debugPrint('[NEXUS][api] GET /forecast lat=$lat lon=$lng');
      // Fetch 5-day forecast (3-hour intervals)
      final forecastResp = await _client.get(
        '/forecast',
        queryParameters: {'lat': lat, 'lon': lng},
      );
      final forecastJson = forecastResp.data as Map<String, dynamic>;
      final forecastList = forecastJson['list'] as List;
      debugPrint('[NEXUS][api] /forecast status=${forecastResp.statusCode} count=${forecastList.length}');

      hourly = forecastList.take(12).map((e) =>
          _parseHourlyWeather(e as Map<String, dynamic>)).toList();
      daily = _aggregateDailyForecast(forecastList);
    } catch (e) {
      debugPrint('[NEXUS][api] /forecast failed, using current-only fallback: $e');
      hourly = _fallbackHourly(current);
      daily = _fallbackDaily(current);
    }

    return WeatherData(current: current, hourly: hourly, daily: daily);
  }

  List<HourlyWeather> _fallbackHourly(CurrentWeather current) {
    return List.generate(12, (index) {
      return HourlyWeather(
        timestamp: current.timestamp.add(Duration(hours: index * 3)),
        temperature: current.temperature,
        feelsLike: current.feelsLike,
        humidity: current.humidity,
        pop: 0,
        weatherIcon: current.weatherIcon,
        weatherMain: current.weatherMain,
      );
    });
  }

  List<DailyWeather> _fallbackDaily(CurrentWeather current) {
    return List.generate(5, (index) {
      final date = DateTime.now().add(Duration(days: index));
      return DailyWeather(
        timestamp: DateTime(date.year, date.month, date.day),
        tempMax: current.temperature,
        tempMin: current.temperature,
        weatherIcon: current.weatherIcon,
        weatherMain: current.weatherMain,
        pop: 0,
        uvi: current.uvi,
        humidity: current.humidity,
        windSpeed: current.windSpeed,
      );
    });
  }

  CurrentWeather _parseCurrentWeather(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final sys = json['sys'] as Map<String, dynamic>? ?? {};
    return CurrentWeather(
      timestamp: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      humidity: json['main']['humidity'] as int? ?? 0,
      windSpeed: (json['wind']['speed'] as num?)?.toDouble() ?? 0,
      windDeg: (json['wind']['deg'] as int?) ?? 0,
      pressure: (json['main']['pressure'] as num?)?.toDouble() ?? 0,
      uvi: (json['uvi'] as num?)?.toDouble() ?? 0,
      clouds: json['clouds']['all'] as int? ?? 0,
      visibility: (json['visibility'] as num?)?.toDouble() ?? 10000,
      dewPoint: 0,
      sunrise: DateTime.fromMillisecondsSinceEpoch(
          ((sys['sunrise'] as int?) ?? (json['dt'] as int) - 21600) * 1000),
      sunset: DateTime.fromMillisecondsSinceEpoch(
          ((sys['sunset'] as int?) ?? (json['dt'] as int) + 21600) * 1000),
      weatherMain: weather['main']?.toString() ?? 'Clear',
      weatherDescription: weather['description']?.toString() ?? '',
      weatherIcon: weather['icon']?.toString() ?? '01d',
    );
  }

  HourlyWeather _parseHourlyWeather(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    return HourlyWeather(
      timestamp: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      humidity: json['main']['humidity'] as int? ?? 0,
      pop: (json['pop'] as num?)?.toDouble() ?? 0,
      weatherIcon: weather['icon']?.toString() ?? '01d',
      weatherMain: weather['main']?.toString() ?? 'Clear',
    );
  }

  List<DailyWeather> _aggregateDailyForecast(List forecastList) {
    // Group forecast entries by day
    final Map<String, List<Map<String, dynamic>>> dayGroups = {};
    for (final item in forecastList) {
      final itemMap = item as Map<String, dynamic>;
      final dt = DateTime.fromMillisecondsSinceEpoch((itemMap['dt'] as int) * 1000);
      final dayKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      dayGroups.putIfAbsent(dayKey, () => []);
      dayGroups[dayKey]!.add(itemMap);
    }

    return dayGroups.entries.map((entry) {
      final items = entry.value;
      double minTemp = double.infinity;
      double maxTemp = double.negativeInfinity;
      double pop = 0;
      double windSpeed = 0;
      int humidity = 0;
      String icon = items.first['weather'][0]['icon'] ?? '01d';
      String main = items.first['weather'][0]['main'] ?? 'Clear';

      for (final item in items) {
        final temp = item['main'] as Map<String, dynamic>;
        final tMin = (temp['temp_min'] as num).toDouble();
        final tMax = (temp['temp_max'] as num).toDouble();
        if (tMin < minTemp) minTemp = tMin;
        if (tMax > maxTemp) maxTemp = tMax;
        if (((item["pop"] as num?)?.toDouble() ?? 0) > pop) {
          pop = (item['pop'] as num).toDouble();
        }
        final ws = (item['wind']['speed'] as num?)?.toDouble() ?? 0;
        if (ws > windSpeed) windSpeed = ws;
        humidity = item['main']['humidity'] as int? ?? humidity;
      }

      final dt = DateTime.parse(entry.key);
      return DailyWeather(
        timestamp: dt,
        tempMax: maxTemp,
        tempMin: minTemp,
        weatherIcon: icon,
        weatherMain: main,
        pop: pop,
        uvi: 0,
        humidity: humidity,
        windSpeed: windSpeed,
      );
    }).toList();
  }

  Future<List<LocationData>> searchCity(String query) async {
    final response = await _client.get(
      AppConstants.geoUrl + ApiEndpoints.geoDirect,
      queryParameters: {'q': query, 'limit': 5},
    );
    return (response.data as List)
        .map((e) => LocationData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LocationData> reverseGeocode(double lat, double lng) async {
    debugPrint('[NEXUS][api] GET reverse geocode lat=$lat lon=$lng');
    final response = await _client.get(
      AppConstants.geoUrl + ApiEndpoints.geoReverse,
      queryParameters: {'lat': lat, 'lon': lng, 'limit': 1},
    );
    if ((response.data as List).isEmpty) {
      return LocationData(name: '未知位置', latitude: lat, longitude: lng);
    }
    final data = (response.data as List).first as Map<String, dynamic>;
    return LocationData.fromJson(data);
  }
}
