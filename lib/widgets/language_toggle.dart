import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../core/language/language_manager.dart';

class LanguageToggle extends StatelessWidget {
  final LanguageManager languageManager;

  const LanguageToggle({super.key, required this.languageManager});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageManager,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => languageManager.toggleLanguage(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
  color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
  color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  languageManager.currentLanguage == AppLanguage.english
                      ? 'EN'
                      : 'FR',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.language, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        );
      },
    );
  }
}
