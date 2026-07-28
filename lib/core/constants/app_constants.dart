class AppConstants {
  AppConstants._();

  // API - using free v2.5 endpoints
  static const String defaultApiKey = '';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String geoUrl = 'https://api.openweathermap.org/geo/1.0';

  // Cache
  static const Duration cacheDuration = Duration(minutes: 30);
  static const Duration forecastCacheDuration = Duration(hours: 1);
  static const String hiveBoxWeather = 'weather_cache';
  static const String hiveBoxSettings = 'user_settings';

  // Default location (Beijing)
  static const double defaultLat = 39.9042;
  static const double defaultLng = 116.4074;
  static const String defaultCity = 'Beijing';
  static const String defaultCountry = 'CN';

  // UI
  static const double panelBorderRadius = 12.0;
  static const double cardBorderRadius = 10.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration glitchDuration = Duration(milliseconds: 80);
}
