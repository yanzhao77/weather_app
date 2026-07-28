import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/weather_utils.dart';
import '../../domain/weather_data.dart';
import '../../../../shared/widgets/hud_metric_card.dart';

class DetailMetricsGrid extends StatelessWidget {
  final CurrentWeather weather;

  const DetailMetricsGrid({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('详细指标', Icons.grid_view),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: [
            HudMetricCard(
              label: '风速',
              value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
              icon: Icons.air,
              accentColor: AppColors.accentCyan,
              subtitle: WeatherUtils.formatWindDirection(weather.windDeg),
            ),
            HudMetricCard(
              label: '气压',
              value: '${weather.pressure.round()} hPa',
              icon: Icons.speed,
              accentColor: AppColors.accentPurple,
            ),
            HudMetricCard(
              label: '紫外线',
              value: weather.uvi.toStringAsFixed(1),
              icon: Icons.wb_sunny,
              accentColor: weather.uvi > 7 ? AppColors.accentPink : AppColors.accentOrange,
              subtitle: WeatherUtils.getUvLevel(weather.uvi),
            ),
            HudMetricCard(
              label: '日出 / 日落',
              value: '',
              icon: Icons.wb_twilight,
              accentColor: AppColors.accentOrange,
              customChild: Row(
                children: [
                  const Icon(Icons.arrow_upward, size: 10, color: AppColors.accentOrange),
                  const SizedBox(width: 2),
                  Text(WeatherUtils.formatTime(weather.sunrise),
                      style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_downward, size: 10, color: AppColors.accentCyan),
                  const SizedBox(width: 2),
                  Text(WeatherUtils.formatTime(weather.sunset),
                      style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: AppColors.textPrimary)),
                ],
              ),
            ),
            HudMetricCard(
              label: '云量',
              value: '${weather.clouds}%',
              icon: Icons.cloud,
              accentColor: AppColors.textSecondary,
            ),
            HudMetricCard(
              label: '能见度',
              value: '${(weather.visibility / 1000).toStringAsFixed(1)} km',
              icon: Icons.visibility,
              accentColor: AppColors.accentGreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.accentCyan),
          const SizedBox(width: 6),
          Text(title.toUpperCase(), style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.accentCyan, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
