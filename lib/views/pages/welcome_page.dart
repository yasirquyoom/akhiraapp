import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../core/language/language_manager.dart';
import '../../router/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/height_spacer.dart';
import '../../widgets/language_toggle.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _accepted = false;
  late final LanguageManager _languageManager;

  @override
  void initState() {
    super.initState();
    _languageManager = LanguageManager();
    _languageManager.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageManager.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Language toggle in top right
              Align(
                alignment: Alignment.topRight,
                child: LanguageToggle(languageManager: _languageManager),
              ),
              const Spacer(),
              // App Icon with rounded background
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Image.asset(AppAssets.appIcon, scale: 4),
                ),
              ),
              const HeightSpacer(32),
              // Welcome Title
              Text(
                _languageManager.getText('Welcome to', 'Bienvenue chez'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'SFPro',
                  fontWeight: FontWeight.w600,
                  fontSize: 36,
                  color: AppColors.white,
                ),
              ),
              const HeightSpacer(4),
              Text(
                _languageManager.getText(
                  'Éditions Akhira.',
                  'Éditions Akhira.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'SFPro',
                  fontWeight: FontWeight.w600,
                  fontSize: 36,
                  color: AppColors.white,
                ),
              ),
              const HeightSpacer(16),
              // Description
              Text(
                _languageManager.getText(
                  "Access exclusive digital content for your books, anytime, anywhere.",
                  "Accédez à du contenu numérique exclusif pour vos livres, à tout moment et partout.",
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'SFPro',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              // Terms and Conditions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'SFPro',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(
                            text: _languageManager.getText(
                              "I confirm having read and accepted all general conditions.",
                              "Je confirme avoir lu et accepté l'ensemble des conditions générales.",
                            ),
                          ),
                          TextSpan(
                            text: _languageManager.getText(
                              " Terms and Conditions",
                              " Conditions Générales",
                            ),
                            style: TextStyle(
                              color: AppColors.tabActiveBg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Transform.scale(
                    scale: 1.3,
                    child: Checkbox(
                      value: _accepted,
                      onChanged: (v) => setState(() => _accepted = v ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      activeColor: Colors.white,
                      checkColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const HeightSpacer(24),
              // Start Button
              CustomButton(
                label: _languageManager.getText('Start', 'Commencer'),
                useGradient: false,
                onPressed:
                    _accepted
                        ? () {
                          context.go(AppRoutes.login);
                        }
                        : null,
                backgroundColor: const Color(0xFFD6DCED),
                textColor: AppColors.primary,
              ),
              const HeightSpacer(16),
            ],
          ),
        ),
      ),
    );
  }
}
