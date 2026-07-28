import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/weather_utils.dart';
import '../../domain/weather_data.dart';
import '../../../../shared/widgets/weather_icon.dart';

class DailyForecastList extends StatelessWidget {
  final List<DailyWeather> dailyData;

  const DailyForecastList({super.key, required this.dailyData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('7天预报', Icons.calendar_month),
        const SizedBox(height: 8),
        ...dailyData.take(7).toList().asMap().entries.map(
              (entry) => _DailyRow(day: entry.value, index: entry.key),
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
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.accentCyan, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  final DailyWeather day;
  final int index;

  const _DailyRow({required this.day, required this.index});

  @override
  Widget build(BuildContext context) {
    final barMin = ((day.tempMin - (-10)) / 50).clamp(0.0, 0.8);
    final barMax = ((day.tempMax - (-10)) / 50).clamp(barMin + 0.1, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGlow, width: 0.2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              WeatherUtils.formatDay(day.timestamp),
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          WeatherIcon(iconCode: day.weatherIcon, size: 24),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              WeatherUtils.formatTemperature(day.tempMin),
              style: const TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Container(
                height: 4,
                color: AppColors.accentCyanDim,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    final left = barMin * totalWidth;
                    final w = (barMax - barMin) * totalWidth;
                    return Stack(
                      children: [
                        Positioned(
                          left: left,
                          child: Container(
                            width: w.clamp(12, totalWidth),
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.accentBlue, AppColors.accentCyan, AppColors.accentOrange],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentCyan.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              WeatherUtils.formatTemperature(day.tempMax),
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Orbitron', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          if (day.pop > 0.1) ...[
            const SizedBox(width: 6),
            Text('${(day.pop * 100).round()}%', style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, color: AppColors.accentBlue)),
          ],
        ],
      ),
    );
  }
}
