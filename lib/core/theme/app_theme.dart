import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentCyan,
        secondary: AppColors.accentBlue,
        surface: AppColors.bgPanel,
        error: AppColors.error,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'monospace',
          fontSize: 56,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          letterSpacing: 2.0,
        ),
        displayMedium: TextStyle(
          fontFamily: 'monospace',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 1.5,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'monospace',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'monospace',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.accentCyan,
          letterSpacing: 1.0,
        ),
        labelMedium: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: AppColors.textDim,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          color: AppColors.textDim,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.panelBorderRadius),
          side: const BorderSide(color: AppColors.borderGlow, width: 0.5),
        ),
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSecondary,
        selectedItemColor: AppColors.accentCyan,
        unselectedItemColor: AppColors.textDim,
        type: BottomNavigationBarType.fixed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderGlow,
        thickness: 0.5,
      ),
    );
  }

  static BoxDecoration hudPanelDecoration() {
    return BoxDecoration(
      color: AppColors.bgPanel,
      borderRadius: BorderRadius.circular(AppConstants.panelBorderRadius),
      border: Border.all(color: AppColors.borderGlow, width: 0.5),
      boxShadow: const [
        BoxShadow(
          color: AppColors.accentCyanDim,
          blurRadius: 20,
          spreadRadius: 1,
        ),
      ],
    );
  }

  static BoxDecoration hudCardDecoration() {
    return BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      border: Border.all(color: AppColors.borderGlow, width: 0.3),
    );
  }
}
