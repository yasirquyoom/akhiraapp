import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      textTheme: _textTheme(base.textTheme),
      inputDecorationTheme: _inputTheme(base.inputDecorationTheme),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      filledButtonTheme: _filledButtonTheme(),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: AppColors.tabActiveBg,
        backgroundColor: AppColors.tabActiveBg.withOpacity(0.25),
        side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        labelStyle: TextStyle(color: AppColors.primary),
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.black,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => AppColors.primary,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => AppColors.primary.withOpacity(0.5),
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => AppColors.primary,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => AppColors.primary,
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    const family = AppConstants.fontFamily;
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: family),
      displayMedium: base.displayMedium?.copyWith(fontFamily: family),
      displaySmall: base.displaySmall?.copyWith(fontFamily: family),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: family),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: family),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: family),
      titleLarge: base.titleLarge?.copyWith(fontFamily: family),
      titleMedium: base.titleMedium?.copyWith(fontFamily: family),
      titleSmall: base.titleSmall?.copyWith(fontFamily: family),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: family),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: family),
      bodySmall: base.bodySmall?.copyWith(fontFamily: family),
      labelLarge: base.labelLarge?.copyWith(fontFamily: family),
      labelMedium: base.labelMedium?.copyWith(fontFamily: family),
      labelSmall: base.labelSmall?.copyWith(fontFamily: family),
    );
  }

  static InputDecorationTheme _inputTheme(InputDecorationTheme base) {
    return base.copyWith(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme() {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.tabActiveBg,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
