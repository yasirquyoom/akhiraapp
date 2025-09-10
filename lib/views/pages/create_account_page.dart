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

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  late final LanguageManager _languageManager;
  late final AuthCubit _authCubit;
  final TextEditingController _fullNameController = TextEditingController();
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
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _authCubit.close();
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  void _register() {
    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _languageManager.getText(
              'Please fill all fields',
              'Veuillez remplir tous les champs',
            ),
          ),
        ),
      );
      return;
    }

    _authCubit.register(
      name: _fullNameController.text.trim(),
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
            if (state.status == AuthStatus.registerSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message ?? 'User registered successfully',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              // Navigate to login page after successful registration
              context.go(AppRoutes.login);
            } else if (state.status == AuthStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Registration failed'),
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
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.login);
                        }
                      },
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
                  hintText: _languageManager.getText(
                    'Full name',
                    'Nom complet',
                  ),
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
                // Create button
                BlocBuilder<AuthCubit, AuthState>(
                  bloc: _authCubit,
                  builder: (context, state) {
                    return CustomButton(
                      label:
                          state.status == AuthStatus.loading
                              ? _languageManager.getText(
                                'Creating...',
                                'Création...',
                              )
                              : _languageManager.getText('Create', 'Créer'),
                      onPressed:
                          state.status == AuthStatus.loading ? null : _register,
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
      ),
    );
  }
}
