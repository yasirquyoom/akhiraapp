import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../data/cubits/auth/auth_cubit.dart';
import '../../router/app_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final AuthCubit _authCubit;

  @override
  void initState() {
    super.initState();
    _authCubit = getIt<AuthCubit>();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check authentication status
    await _authCubit.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      bloc: _authCubit,
      listener: (context, state) {
        if (!mounted) return;

        if (state.status == AuthStatus.authenticated) {
          // User is logged in, go to home
          context.go(AppRoutes.home);
        } else if (state.status == AuthStatus.unauthenticated) {
          // User is not logged in, go to welcome
          context.go(AppRoutes.welcome);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          children: [
            // Center app icon
            Center(
              child: Image.asset(AppAssets.appIcon, width: 132, height: 132),
            ),
            // Bottom text logo
            Positioned(
              left: 0,
              right: 0,
              bottom: 56,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  AppAssets.appTextLogo,
                  scale: 4,
                  fit: BoxFit.contain,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
