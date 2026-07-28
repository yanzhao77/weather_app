import 'package:intl/intl.dart';

class WeatherUtils {
  WeatherUtils._();

  static String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  static String formatTemperature(double temp) {
    return '${temp.round()}°';
  }

  static String formatWindDirection(int degrees) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                        'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((degrees % 360) / 22.5).round() % 16;
    return directions[index];
  }

  static String formatTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  static String formatHour(DateTime dt) {
    return DateFormat('HH').format(dt);
  }

  static String formatDay(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = date.difference(today).inDays;

    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    if (diff == 2) return '后天';

    return DateFormat('E', 'zh_CN').format(dt);
  }

  static String getWeatherCondition(String main) {
    switch (main.toLowerCase()) {
      case 'clear':
        return '晴';
      case 'clouds':
        return '多云';
      case 'rain':
      case 'drizzle':
        return '雨';
      case 'thunderstorm':
        return '雷暴';
      case 'snow':
        return '雪';
      case 'mist':
      case 'fog':
      case 'haze':
        return '雾';
      default:
        return main;
    }
  }

  static String getUvLevel(double uvi) {
    if (uvi <= 2) return '低';
    if (uvi <= 5) return '中等';
    if (uvi <= 7) return '高';
    if (uvi <= 10) return '很高';
    return '极高';
  }
}
