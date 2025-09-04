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

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  late final LanguageManager _languageManager;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _languageManager = LanguageManager();
    _languageManager.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageManager.removeListener(_onLanguageChanged);
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _languageManager.getText(
                      'Create account',
                      'Créer un compte',
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
              // Full name field
              CustomTextField(
                controller: _fullNameController,
                hintText: _languageManager.getText('Full name', 'Nom complet'),
                keyboardType: TextInputType.name,
              ),
              const HeightSpacer(16),
              // Email field
              CustomTextField(
                controller: _emailController,
                hintText: _languageManager.getText(
                  'Enter email',
                  'Entrez votre email',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const HeightSpacer(16),
              // Password field
              CustomTextField(
                controller: _passwordController,
                hintText: _languageManager.getText(
                  'Enter password',
                  'Entrez votre mot de passe',
                ),
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  onPressed:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                ),
              ),
              const HeightSpacer(32),
              // Create button
              CustomButton(
                label: _languageManager.getText('Create', 'Créer'),
                onPressed: () {
                  // TODO: Implement create account logic
                  context.go(AppRoutes.home);
                },
                useGradient: true,
              ),
              const HeightSpacer(24),
              // Bottom links
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      context.go(AppRoutes.forgotPassword);
                    },
                    child: Text(
                      _languageManager.getText(
                        'Mot de passe oublié',
                        'Mot de passe oublié',
                      ),
                      style: const TextStyle(
                        fontFamily: 'SFPro',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.go(AppRoutes.login);
                    },
                    child: Text(
                      _languageManager.getText(
                        'I already have an account',
                        'J\'ai déjà un compte',
                      ),
                      style: const TextStyle(
                        fontFamily: 'SFPro',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const HeightSpacer(16),
            ],
          ),
        ),
      ),
    );
  }
}
