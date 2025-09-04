import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../router/app_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      context.go(AppRoutes.welcome);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
