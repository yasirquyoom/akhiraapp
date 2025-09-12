import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../core/language/language_manager.dart';
import '../../router/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/height_spacer.dart';
import '../../widgets/language_toggle.dart';

class EmailSentPage extends StatefulWidget {
  const EmailSentPage({super.key});

  @override
  State<EmailSentPage> createState() => _EmailSentPageState();
}

class _EmailSentPageState extends State<EmailSentPage> {
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

  Future<void> _openEmailApp() async {
    try {
      // Try to open the default email app
      final Uri emailUri = Uri(scheme: 'mailto');
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Fallback: try to open Gmail app
        final Uri gmailUri = Uri.parse('googlegmail://');
        if (await canLaunchUrl(gmailUri)) {
          await launchUrl(gmailUri);
        } else {
          // Final fallback: open Gmail in browser
          final Uri gmailWebUri = Uri.parse('https://mail.google.com');
          if (await canLaunchUrl(gmailWebUri)) {
            await launchUrl(gmailWebUri, mode: LaunchMode.externalApplication);
          } else {
            throw Exception('Could not launch email app');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _languageManager.getText(
                'Could not open email app',
                'Impossible d\'ouvrir l\'application email',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryGradientStart,
              AppColors.primaryGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: BackButton(
                    color: Colors.white,
                    onPressed: () {
                      context.go(AppRoutes.login);
                    },
                  ),
                ),
                // Language toggle in top right
                Align(
                  alignment: Alignment.topRight,
                  child: LanguageToggle(languageManager: _languageManager),
                ),
                const Spacer(),
                // Email icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
                const HeightSpacer(32),
                // Success title
                Text(
                  _languageManager.getText(
                    'Email sent successfully',
                    'Email envoyé avec succès',
                  ),
                  style: const TextStyle(
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const HeightSpacer(12),
                // Subtitle
                Text(
                  _languageManager.getText(
                    'Please check your email',
                    'Veuillez vérifier votre email',
                  ),
                  style: TextStyle(
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                // Open email button
                CustomButton(
                  label: _languageManager.getText('Open email', 'Ouvrir email'),
                  onPressed: _openEmailApp,
                  useGradient: false,
                  backgroundColor: const Color(0xFFD6DCED),
                  textColor: AppColors.primary,
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
