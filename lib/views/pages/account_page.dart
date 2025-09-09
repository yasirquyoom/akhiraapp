import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_assets.dart';
import '../../core/language/language_manager.dart';
import '../../data/cubits/auth/auth_cubit.dart';
import '../../router/app_router.dart';
import '../../widgets/language_toggle.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(_languageManager.getText('Logout', 'Déconnexion')),
            content: Text(
              _languageManager.getText(
                'Are you sure you want to logout?',
                'Êtes-vous sûr de vouloir vous déconnecter?',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_languageManager.getText('Cancel', 'Annuler')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<AuthCubit>().logout();
                  context.go(AppRoutes.login);
                },
                child: Text(_languageManager.getText('Logout', 'Déconnexion')),
              ),
            ],
          ),
    );
  }

  Future<void> _shareApp() async {
    // TODO: Implement app sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _languageManager.getText(
            'Share functionality coming soon!',
            'Fonctionnalité de partage bientôt disponible!',
          ),
        ),
      ),
    );
  }

  Future<void> _rateApp() async {
    // TODO: Implement app rating functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _languageManager.getText(
            'Rating functionality coming soon!',
            'Fonctionnalité d\'évaluation bientôt disponible!',
          ),
        ),
      ),
    );
  }

  Future<void> _openTelegram() async {
    const url =
        'https://t.me/akhira_app'; // Replace with actual Telegram channel
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _languageManager.getText(
              'Could not open Telegram',
              'Impossible d\'ouvrir Telegram',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openFacebook() async {
    const url =
        'https://facebook.com/akhira_app'; // Replace with actual Facebook page
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _languageManager.getText(
              'Could not open Facebook',
              'Impossible d\'ouvrir Facebook',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openInstagram() async {
    const url =
        'https://instagram.com/akhira_app'; // Replace with actual Instagram page
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _languageManager.getText(
              'Could not open Instagram',
              'Impossible d\'ouvrir Instagram',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0C1138)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _languageManager.getText('Account', 'Connexion'),
          style: TextStyle(
            color: const Color(0xFF0C1138),
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          LanguageToggle(languageManager: _languageManager),
          SizedBox(width: 16.w),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        children: [
          // About Us
          _buildMenuItem(
            icon: AppAssets.iconLogo,
            title: _languageManager.getText('About Us', 'À propos de nous'),
            onTap: () {
              // TODO: Navigate to about us page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _languageManager.getText(
                      'About Us page coming soon!',
                      'Page À propos de nous bientôt disponible!',
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 16.h),

          // Privacy Policy
          _buildMenuItem(
            icon: AppAssets.iconPrivacyPolicy,
            title: _languageManager.getText(
              'Privacy Policy',
              'Politique de confidentialité',
            ),
            onTap: () {
              // TODO: Navigate to privacy policy page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _languageManager.getText(
                      'Privacy Policy page coming soon!',
                      'Page Politique de confidentialité bientôt disponible!',
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 16.h),

          // Share App
          _buildMenuItem(
            icon: AppAssets.iconShare,
            title: _languageManager.getText(
              'Share this app',
              'Partager cette application',
            ),
            onTap: _shareApp,
          ),

          SizedBox(height: 16.h),

          // Rate App
          _buildMenuItem(
            icon: AppAssets.iconRating,
            title: _languageManager.getText(
              'Rate on Play Store',
              'Noter sur le Play Store',
            ),
            onTap: _rateApp,
          ),

          SizedBox(height: 16.h),

          // Logout
          _buildMenuItem(
            icon: AppAssets.iconLogout,
            title: _languageManager.getText('Logout', 'Déconnexion'),
            onTap: _showLogoutDialog,
            isDestructive: true,
          ),

          SizedBox(height: 32.h),

          // Social Media Section
          Text(
            _languageManager.getText('Follow Us', 'Suivez-nous'),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0C1138),
            ),
          ),

          SizedBox(height: 16.h),

          // Telegram
          _buildSocialMenuItem(
            icon: AppAssets.iconTelegram,
            title: _languageManager.getText(
              'Join Telegram channel',
              'Rejoignez la chaîne Telegram',
            ),
            onTap: _openTelegram,
            iconColor: const Color(0xFF0088CC),
          ),

          SizedBox(height: 16.h),

          // Facebook
          _buildSocialMenuItem(
            icon: AppAssets.iconFacebook,
            title: _languageManager.getText(
              'Follow us on Facebook',
              'Suivez-nous sur Facebook',
            ),
            onTap: _openFacebook,
            iconColor: const Color(0xFF1877F2),
          ),

          SizedBox(height: 16.h),

          // Instagram
          _buildSocialMenuItem(
            icon: AppAssets.iconInstagram,
            title: _languageManager.getText(
              'Follow us on Instagram',
              'Suivez-nous sur Instagram',
            ),
            onTap: _openInstagram,
            iconColor: const Color(0xFFE4405F),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.grey[50],
      ),
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Image.asset(icon, scale: 4),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: const Color(0xFF0C1138),
          size: 20.sp,
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
    );
  }

  Widget _buildSocialMenuItem({
    required dynamic icon,
    required String title,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.grey[50],
      ),
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Image.asset(icon, scale: 4),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0C1138),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: const Color(0xFF0C1138),
          size: 20.sp,
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
    );
  }
}
