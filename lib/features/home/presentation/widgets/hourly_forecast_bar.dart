import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/weather_utils.dart';
import '../../domain/weather_data.dart';
import '../../../../shared/widgets/weather_icon.dart';

class HourlyForecastBar extends StatelessWidget {
  final List<HourlyWeather> hourlyData;

  const HourlyForecastBar({super.key, required this.hourlyData});

  @override
  Widget build(BuildContext context) {
    final displayData = hourlyData.take(12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('逐时预报', Icons.schedule),
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
              final isNow = index == 0;
              return _HourlyCard(hour: hour, isNow: isNow);
            },
          ),
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

class _HourlyCard extends StatelessWidget {
  final HourlyWeather hour;
  final bool isNow;

  const _HourlyCard({required this.hour, required this.isNow});

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
            isNow ? '现在' : WeatherUtils.formatHour(hour.timestamp),
            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: isNow ? AppColors.accentCyan : AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          WeatherIcon(iconCode: hour.weatherIcon, size: 24),
          const SizedBox(height: 4),
          Text(
            WeatherUtils.formatTemperature(hour.temperature),
            style: TextStyle(fontFamily: 'Orbitron', fontSize: 13, fontWeight: FontWeight.w600, color: isNow ? AppColors.accentCyan : AppColors.textPrimary),
          ),
          if (hour.pop > 0.1)
            Text('${(hour.pop * 100).round()}%', style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 8, color: AppColors.accentBlue)),
        ],
      ),
    );
  }
}
