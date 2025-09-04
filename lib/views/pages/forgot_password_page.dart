import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../core/language/language_manager.dart';
import '../../router/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/height_spacer.dart';
import '../../widgets/language_toggle.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final LanguageManager _languageManager;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _languageManager = LanguageManager();
    _languageManager.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageManager.removeListener(_onLanguageChanged);
    _emailController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button and title
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.login),
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _languageManager.getText(
                      'Forget account',
                      'Mot de passe oublié',
                    ),
                    style: const TextStyle(
                      fontFamily: 'SFPro',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  LanguageToggle(languageManager: _languageManager),
                ],
              ),
              const HeightSpacer(40),
              // Heading
              Text(
                _languageManager.getText(
                  'Indiquez votre e-mail',
                  'Indiquez votre e-mail',
                ),
                style: const TextStyle(
                  fontFamily: 'SFPro',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
              const HeightSpacer(12),
              // Description
              Text(
                _languageManager.getText(
                  'Nous vous enverrons un lien par e-mail pour réinitialiser votre mot de passe.',
                  'Nous vous enverrons un lien par e-mail pour réinitialiser votre mot de passe.',
                ),
                style: const TextStyle(
                  fontFamily: 'SFPro',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const HeightSpacer(32),
              // Email field
              CustomTextField(
                controller: _emailController,
                hintText: _languageManager.getText(
                  'Enter email id',
                  'Entrez votre identifiant email',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const HeightSpacer(32),
              // Confirm button
              CustomButton(
                label: _languageManager.getText('Confirm', 'Confirmer'),
                onPressed: () {
                  // TODO: Implement forgot password logic
                  context.go(AppRoutes.emailSent);
                },
                useGradient: true,
              ),
              const HeightSpacer(16),
            ],
          ),
        ),
      ),
    );
  }
}
