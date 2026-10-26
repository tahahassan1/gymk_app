import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_geometry.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const border = OutlineInputBorder(
      borderRadius: AppGeometry.radius,
      borderSide: BorderSide(color: AppColors.ink, width: 1.5),
    );
    const textTheme = TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        height: 40 / 30,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        height: 34 / 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 28 / 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 26 / 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 26 / 16),
      bodyMedium: TextStyle(fontSize: 14, height: 22 / 14),
      bodySmall: TextStyle(fontSize: 12, height: 20 / 12),
      labelLarge: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w700,
      ),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandPrimary,
        onPrimary: AppColors.ink,
        secondary: AppColors.ink,
        onSecondary: AppColors.surface,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.danger,
        onError: AppColors.surface,
        outline: AppColors.divider,
      ),
      textTheme: textTheme.apply(
        fontFamily: 'Cairo',
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: TextStyle(color: AppColors.ink),
        filled: true,
        fillColor: AppColors.surface,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: AppGeometry.radius,
          borderSide: BorderSide(color: AppColors.ink, width: 2),
        ),
        errorMaxLines: 3,
        contentPadding: EdgeInsetsDirectional.all(AppGeometry.space16),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.ink,
        selectionColor: AppColors.brandPrimary,
        selectionHandleColor: AppColors.ink,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.brandPrimary,
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: AppColors.ink)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.brandPrimary,
        selectedIconTheme: IconThemeData(color: AppColors.ink),
        unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppGeometry.radius),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppGeometry.touchTarget),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(48, AppGeometry.controlHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppGeometry.space16,
            vertical: AppGeometry.space12,
          ),
          side: const BorderSide(color: AppColors.ink, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppGeometry.radius),
        ),
      ),
      datePickerTheme: const DatePickerThemeData(
        headerBackgroundColor: AppColors.brandPrimary,
        headerForegroundColor: AppColors.ink,
        todayForegroundColor: WidgetStatePropertyAll(AppColors.ink),
        todayBorder: BorderSide(color: AppColors.ink),
      ),
    );
  }
}
