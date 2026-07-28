import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/weather_utils.dart';
import '../../domain/weather_data.dart';
import '../../../../shared/widgets/hud_panel.dart';
import '../../../../shared/widgets/weather_icon.dart';

class CurrentWeatherPanel extends StatelessWidget {
  final CurrentWeather weather;
  final String cityName;
  final bool isFromCache;

  const CurrentWeatherPanel({
    super.key,
    required this.weather,
    required this.cityName,
    this.isFromCache = false,
  });

  @override
  Widget build(BuildContext context) {
    return HudPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: AppColors.accentCyan, size: 14),
              const SizedBox(width: 4),
              Text(
                cityName.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isFromCache) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'OFFLINE',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 7,
                      color: AppColors.warning,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WeatherIcon(iconCode: weather.weatherIcon, size: 64),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${weather.temperature.round()}',
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: 2,
                          ),
                        ),
                        TextSpan(
                          text: '°C',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: AppColors.accentCyan.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    WeatherUtils.getWeatherCondition(weather.weatherMain),
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentCyanGlow,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderGlow, width: 0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _InfoChip(label: '体感', value: WeatherUtils.formatTemperature(weather.feelsLike)),
                Container(width: 1, height: 20, color: AppColors.borderGlow),
                _InfoChip(label: '湿度', value: '${weather.humidity}%'),
                Container(width: 1, height: 20, color: AppColors.borderGlow),
                _InfoChip(label: '风速', value: '${weather.windSpeed.toStringAsFixed(1)} m/s'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, color: AppColors.textDim, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontFamily: 'Orbitron', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accentCyan)),
      ],
    );
  }
}
