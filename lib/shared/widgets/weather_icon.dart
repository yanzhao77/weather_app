import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class WeatherIcon extends StatelessWidget {
  final String iconCode;
  final double size;
  final bool animated;

  const WeatherIcon({
    super.key,
    required this.iconCode,
    this.size = 48,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getWeatherIconData(iconCode);
    final color = _getWeatherColor(iconCode);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: size * 0.3,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
      child: Icon(iconData, color: color, size: size * 0.7),
    );
  }

  IconData _getWeatherIconData(String code) {
    // OpenWeatherMap icon codes: 01d=clear_day, 01n=clear_night, etc.
    switch (code) {
      case '01d':
        return Icons.wb_sunny;
      case '01n':
        return Icons.nightlight_round;
      case '02d':
      case '02n':
        return Icons.cloud_queue;
      case '03d':
      case '03n':
        return Icons.cloud;
      case '04d':
      case '04n':
        return Icons.cloud_circle;
      case '09d':
      case '09n':
        return Icons.cloud_queue_outlined;
      case '10d':
        return Icons.umbrella;
      case '10n':
        return Icons.water_drop;
      case '11d':
      case '11n':
        return Icons.flash_on;
      case '13d':
      case '13n':
        return Icons.ac_unit;
      case '50d':
      case '50n':
        return Icons.foggy;
      default:
        return Icons.wb_cloudy;
    }
  }

  Color _getWeatherColor(String code) {
    if (code.startsWith('01')) {
      if (code.endsWith('d')) return const Color(0xFFFFD700);
      return const Color(0xFF4169E1);
    }
    if (code.startsWith('02')) return AppColors.accentCyan;
    if (code.startsWith('03') || code.startsWith('04')) {
      return AppColors.textSecondary;
    }
    if (code.startsWith('09') || code.startsWith('10')) {
      return const Color(0xFF4A90D9);
    }
    if (code.startsWith('11')) return AppColors.accentPink;
    if (code.startsWith('13')) return AppColors.accentCyan;
    if (code.startsWith('50')) return AppColors.textDim;
    return AppColors.accentCyan;
  }
}
