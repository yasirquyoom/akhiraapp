import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, french }

class LanguageManager extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  AppLanguage _currentLanguage = AppLanguage.english;

  AppLanguage get currentLanguage => _currentLanguage;

  LanguageManager() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      _currentLanguage = AppLanguage.values.firstWhere(
        (lang) => lang.name == languageCode,
        orElse: () => AppLanguage.english,
      );
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.name);
      notifyListeners();
    }
  }

  Future<void> toggleLanguage() async {
    final newLanguage =
        _currentLanguage == AppLanguage.english
            ? AppLanguage.french
            : AppLanguage.english;
    await setLanguage(newLanguage);
  }

  String getText(String englishText, String frenchText) {
    switch (_currentLanguage) {
      case AppLanguage.english:
        return englishText;
      case AppLanguage.french:
        return frenchText;
    }
  }

  Locale getLocale() {
    switch (_currentLanguage) {
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.french:
        return const Locale('fr');
    }
  }
}
