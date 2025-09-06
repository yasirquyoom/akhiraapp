import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary and brand
  static const Color primary = Color(0xFF2E4FB6); // #2E4FB6
  static const Color primaryGradientStart = Color(0xFF2E4FB6); // #2E4FB6
  static const Color primaryGradientEnd = Color(0xFF4D78FF); // #4D78FF

  // UI
  static const Color tabActiveBg = Color(0xff2E4FB6); // #FED455

  // Neutrals
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  // Feedback
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  static const Gradient primaryGradient = LinearGradient(
    colors: [primaryGradientStart, primaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
