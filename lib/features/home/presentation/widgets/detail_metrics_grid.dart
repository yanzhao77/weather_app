import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/weather_utils.dart';
import '../../domain/weather_data.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../shared/widgets/hud_metric_card.dart';
import '../../../../shared/widgets/section_header.dart';

class DetailMetricsGrid extends ConsumerWidget {
  final CurrentWeather weather;

  const DetailMetricsGrid({super.key, required this.weather});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '详细指标', icon: Icons.grid_view),
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
              value: WeatherUtils.formatWindSpeed(weather.windSpeed, useKmh: settings.useKmh),
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
              label: '湿度',
              value: '${weather.humidity}%',
              icon: Icons.water_drop,
              accentColor: AppColors.accentBlue,
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
                  Text(WeatherUtils.formatClock(weather.sunrise, use24Hour: settings.use24Hour),
                      style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_downward, size: 10, color: AppColors.accentCyan),
                  const SizedBox(width: 2),
                  Text(WeatherUtils.formatClock(weather.sunset, use24Hour: settings.use24Hour),
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

}
