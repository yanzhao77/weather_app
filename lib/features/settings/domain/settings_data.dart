import 'package:equatable/equatable.dart';

class SettingsData extends Equatable {
  final bool useCelsius;
  final bool useKmh;
  final bool use24Hour;
  final bool showNotifications;
  final String? defaultCity;
  final String? apiKey;

  const SettingsData({
    this.useCelsius = true,
    this.useKmh = true,
    this.use24Hour = true,
    this.showNotifications = false,
    this.defaultCity,
    this.apiKey,
  });

  @override
  List<Object?> get props =>
      [useCelsius, useKmh, use24Hour, showNotifications, defaultCity, apiKey];

  SettingsData copyWith({
    bool? useCelsius,
    bool? useKmh,
    bool? use24Hour,
    bool? showNotifications,
    String? defaultCity,
    String? apiKey,
  }) {
    return SettingsData(
      useCelsius: useCelsius ?? this.useCelsius,
      useKmh: useKmh ?? this.useKmh,
      use24Hour: use24Hour ?? this.use24Hour,
      showNotifications: showNotifications ?? this.showNotifications,
      defaultCity: defaultCity ?? this.defaultCity,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  factory SettingsData.fromJson(Map<String, dynamic> json) {
    return SettingsData(
      useCelsius: json['useCelsius'] as bool? ?? true,
      useKmh: json['useKmh'] as bool? ?? true,
      use24Hour: json['use24Hour'] as bool? ?? true,
      showNotifications: json['showNotifications'] as bool? ?? false,
      defaultCity: json['defaultCity'] as String?,
      apiKey: json['apiKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'useCelsius': useCelsius,
        'useKmh': useKmh,
        'use24Hour': use24Hour,
        'showNotifications': showNotifications,
        'defaultCity': defaultCity,
        'apiKey': apiKey,
      };
}
