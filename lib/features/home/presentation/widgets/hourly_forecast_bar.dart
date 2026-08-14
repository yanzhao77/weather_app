import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/weather_utils.dart';
import '../../domain/weather_data.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/weather_icon.dart';

class HourlyForecastBar extends ConsumerWidget {
  final List<HourlyWeather> hourlyData;

  const HourlyForecastBar({super.key, required this.hourlyData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final displayData = hourlyData.take(12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '逐时预报', icon: Icons.schedule),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: displayData.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final hour = displayData[index];
              final isNow = DateTime.now()
                      .difference(hour.timestamp)
                      .abs()
                      .inHours <
                  3;
              return _HourlyCard(
                hour: hour,
                isNow: isNow,
                useCelsius: settings.useCelsius,
                use24Hour: settings.use24Hour,
              );
            },
          ),
        ),
      ],
    );
  }

}

class _HourlyCard extends StatelessWidget {
  final HourlyWeather hour;
  final bool isNow;
  final bool useCelsius;
  final bool use24Hour;

  const _HourlyCard({
    required this.hour,
    required this.isNow,
    required this.useCelsius,
    required this.use24Hour,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isNow ? AppColors.accentCyan.withValues(alpha: 0.08) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNow ? AppColors.accentCyan : AppColors.borderGlow,
          width: isNow ? 0.5 : 0.3,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isNow ? '现在' : WeatherUtils.formatHour(hour.timestamp, use24Hour: use24Hour),
            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: isNow ? AppColors.accentCyan : AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          WeatherIcon(iconCode: hour.weatherIcon, size: 24),
          const SizedBox(height: 4),
          Text(
            WeatherUtils.formatTemperature(hour.temperature, useCelsius: useCelsius),
            style: TextStyle(fontFamily: 'Orbitron', fontSize: 13, fontWeight: FontWeight.w600, color: isNow ? AppColors.accentCyan : AppColors.textPrimary),
          ),
          if (hour.pop > 0.1)
            Text('${(hour.pop * 100).round()}%', style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 8, color: AppColors.accentBlue)),
        ],
      ),
    );
  }
}
