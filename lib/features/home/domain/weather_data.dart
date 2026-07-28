import 'package:equatable/equatable.dart';

class WeatherData extends Equatable {
  final CurrentWeather current;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;

  const WeatherData({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  @override
  List<Object?> get props => [current, hourly, daily];

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      current: CurrentWeather.fromJson(json['current'] as Map<String, dynamic>),
      hourly: (json['hourly'] as List)
          .map((e) => HourlyWeather.fromJson(e as Map<String, dynamic>))
          .toList(),
      daily: (json['daily'] as List)
          .map((e) => DailyWeather.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'current': current.toJson(),
        'hourly': hourly.map((e) => e.toJson()).toList(),
        'daily': daily.map((e) => e.toJson()).toList(),
      };
}

class CurrentWeather extends Equatable {
  final DateTime timestamp;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int windDeg;
  final double pressure;
  final double uvi;
  final int clouds;
  final double visibility;
  final double dewPoint;
  final DateTime sunrise;
  final DateTime sunset;
  final String weatherMain;
  final String weatherDescription;
  final String weatherIcon;

  const CurrentWeather({
    required this.timestamp,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.pressure,
    required this.uvi,
    required this.clouds,
    required this.visibility,
    required this.dewPoint,
    required this.sunrise,
    required this.sunset,
    required this.weatherMain,
    required this.weatherDescription,
    required this.weatherIcon,
  });

  @override
  List<Object?> get props => [
        timestamp, temperature, feelsLike, humidity, windSpeed, windDeg,
        pressure, uvi, clouds, visibility, dewPoint, sunrise, sunset,
        weatherMain, weatherDescription, weatherIcon,
      ];

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    return CurrentWeather(
      timestamp: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      temperature: (json['temp'] as num).toDouble(),
      feelsLike: (json['feels_like'] as num).toDouble(),
      humidity: json['humidity'] as int,
      windSpeed: (json['wind_speed'] as num).toDouble(),
      windDeg: json['wind_deg'] as int? ?? 0,
      pressure: (json['pressure'] as num).toDouble(),
      uvi: (json['uvi'] as num?)?.toDouble() ?? 0,
      clouds: json['clouds'] as int? ?? 0,
      visibility: (json['visibility'] as num?)?.toDouble() ?? 10000,
      dewPoint: (json['dew_point'] as num?)?.toDouble() ?? 0,
      sunrise: DateTime.fromMillisecondsSinceEpoch((json['sunrise'] as int) * 1000),
      sunset: DateTime.fromMillisecondsSinceEpoch((json['sunset'] as int) * 1000),
      weatherMain: weather['main']?.toString() ?? 'Clear',
      weatherDescription: weather['description']?.toString() ?? '',
      weatherIcon: weather['icon']?.toString() ?? '01d',
    );
  }

  Map<String, dynamic> toJson() => {
        'dt': timestamp.millisecondsSinceEpoch ~/ 1000,
        'temp': temperature,
        'feels_like': feelsLike,
        'humidity': humidity,
        'wind_speed': windSpeed,
        'wind_deg': windDeg,
        'pressure': pressure,
        'uvi': uvi,
        'clouds': clouds,
        'visibility': visibility,
        'dew_point': dewPoint,
        'sunrise': sunrise.millisecondsSinceEpoch ~/ 1000,
        'sunset': sunset.millisecondsSinceEpoch ~/ 1000,
        'weather': [
          {'main': weatherMain, 'description': weatherDescription, 'icon': weatherIcon},
        ],
      };
}

class HourlyWeather extends Equatable {
  final DateTime timestamp;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double pop;
  final String weatherIcon;
  final String weatherMain;

  const HourlyWeather({
    required this.timestamp,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pop,
    required this.weatherIcon,
    required this.weatherMain,
  });

  @override
  List<Object?> get props =>
      [timestamp, temperature, feelsLike, humidity, pop, weatherIcon, weatherMain];

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    return HourlyWeather(
      timestamp: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      temperature: (json['temp'] as num).toDouble(),
      feelsLike: (json['feels_like'] as num).toDouble(),
      humidity: json['humidity'] as int? ?? 0,
      pop: (json['pop'] as num?)?.toDouble() ?? 0,
      weatherIcon: weather['icon']?.toString() ?? '01d',
      weatherMain: weather['main']?.toString() ?? 'Clear',
    );
  }

  Map<String, dynamic> toJson() => {
        'dt': timestamp.millisecondsSinceEpoch ~/ 1000,
        'temp': temperature,
        'feels_like': feelsLike,
        'humidity': humidity,
        'pop': pop,
        'weather': [{'icon': weatherIcon, 'main': weatherMain}],
      };
}

class DailyWeather extends Equatable {
  final DateTime timestamp;
  final double tempMax;
  final double tempMin;
  final String weatherIcon;
  final String weatherMain;
  final double pop;
  final double uvi;
  final int humidity;
  final double windSpeed;

  const DailyWeather({
    required this.timestamp,
    required this.tempMax,
    required this.tempMin,
    required this.weatherIcon,
    required this.weatherMain,
    required this.pop,
    required this.uvi,
    required this.humidity,
    required this.windSpeed,
  });

  @override
  List<Object?> get props => [
        timestamp, tempMax, tempMin, weatherIcon, weatherMain,
        pop, uvi, humidity, windSpeed,
      ];

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final temp = json['temp'] as Map<String, dynamic>;
    return DailyWeather(
      timestamp: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      tempMax: (temp['max'] as num).toDouble(),
      tempMin: (temp['min'] as num).toDouble(),
      weatherIcon: weather['icon']?.toString() ?? '01d',
      weatherMain: weather['main']?.toString() ?? 'Clear',
      pop: (json['pop'] as num?)?.toDouble() ?? 0,
      uvi: (json['uvi'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'dt': timestamp.millisecondsSinceEpoch ~/ 1000,
        'temp': {'max': tempMax, 'min': tempMin},
        'weather': [{'icon': weatherIcon, 'main': weatherMain}],
        'pop': pop,
        'uvi': uvi,
        'humidity': humidity,
        'wind_speed': windSpeed,
      };
}
