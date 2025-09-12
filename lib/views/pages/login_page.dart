import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/language/language_manager.dart';
import '../../data/cubits/auth/auth_cubit.dart';
import '../../router/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_feedback.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/height_spacer.dart';
import '../../widgets/language_toggle.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LanguageManager _languageManager;
  late final AuthCubit _authCubit;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _languageManager = LanguageManager();
    _authCubit = getIt<AuthCubit>();
    _languageManager.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageManager.removeListener(_onLanguageChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _authCubit.close();
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _login() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      context.showWarningFeedback(
        _languageManager.getText(
          'Please fill all fields',
          'Veuillez remplir tous les champs',
        ),
      );
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      context.showErrorFeedback(
        _languageManager.getText(
          'Please enter a valid email address',
          'Veuillez saisir une adresse e-mail valide',
        ),
      );
      return;
    }

    _authCubit.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocListener<AuthCubit, AuthState>(
          bloc: _authCubit,
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              context.showSuccessFeedback(state.message ?? 'Login successful');
              context.go(AppRoutes.home);
            } else if (state.status == AuthStatus.failure) {
              context.showErrorFeedback(state.errorMessage ?? 'Login failed');
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header with title only (no back button)
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      _languageManager.getText('Login', 'Connexion'),
                      style: const TextStyle(
                        fontFamily: 'SFPro',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    LanguageToggle(languageManager: _languageManager),
                  ],
                ),
                const HeightSpacer(40),
                // Welcome message
                Text(
                  _languageManager.getText('Bon retour!', 'Bon retour!'),
                  style: const TextStyle(
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    color: Colors.black,
                  ),
                ),
                const HeightSpacer(8),
                Text(
                  _languageManager.getText(
                    'Bienvenue',
                    'Bon detour" you correct\nto "Bienvenue',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const HeightSpacer(32),
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
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const HeightSpacer(32),
                // Login button
                BlocBuilder<AuthCubit, AuthState>(
                  bloc: _authCubit,
                  builder: (context, state) {
                    return CustomButton(
                      label: _languageManager.getText('Login', 'Se connecter'),
                      onPressed:
                          state.status == AuthStatus.loading ? null : _login,
                      isLoading: state.status == AuthStatus.loading,
                      useGradient: true,
                    );
                  },
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
                          'Forgot account',
                          'Mot de passe oublié',
                        ),
                        style: const TextStyle(
                          fontFamily: 'SFPro',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.push(AppRoutes.createAccount);
                      },
                      child: Text(
                        _languageManager.getText(
                          'Create account',
                          'Créer un compte',
                        ),
                        style: const TextStyle(
                          fontFamily: 'SFPro',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
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
      ),
    );
  }
}
