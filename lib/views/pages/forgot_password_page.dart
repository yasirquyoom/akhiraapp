import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/language/language_manager.dart';
import '../../data/cubits/auth/auth_cubit.dart';
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
  late final AuthCubit _authCubit;
  final TextEditingController _emailController = TextEditingController();

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
    _authCubit.close();
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _sendResetLink() {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _languageManager.getText(
              'Please enter your email',
              'Veuillez saisir votre e-mail',
            ),
          ),
        ),
      );
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _languageManager.getText(
              'Please enter a valid email address',
              'Veuillez saisir une adresse e-mail valide',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _authCubit.forgotPassword(email: _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocListener<AuthCubit, AuthState>(
          bloc: _authCubit,
          listener: (context, state) {
            if (state.status == AuthStatus.forgotPasswordSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message ?? 'Password reset link sent successfully',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              context.go(AppRoutes.emailSent);
            } else if (state.status == AuthStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage ?? 'Failed to send reset link',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button and title
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.go(AppRoutes.login),
                      child: Icon(CupertinoIcons.back, color: Colors.black),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _languageManager.getText(
                        'Forgot account',
                        'Mot de passe oublié',
                      ),
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
                BlocBuilder<AuthCubit, AuthState>(
                  bloc: _authCubit,
                  builder: (context, state) {
                    return CustomButton(
                      label: _languageManager.getText('Confirm', 'Confirmer'),
                      onPressed:
                          state.status == AuthStatus.loading
                              ? null
                              : _sendResetLink,
                      isLoading: state.status == AuthStatus.loading,
                      useGradient: true,
                    );
                  },
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
