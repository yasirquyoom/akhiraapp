import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../core/language/language_manager.dart';
import '../../router/app_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/height_spacer.dart';
import '../../widgets/language_toggle.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final LanguageManager _languageManager;
  final TextEditingController _bookCodeController = TextEditingController();
  bool _showAddBookModal = false;

  @override
  void initState() {
    super.initState();
    _languageManager = LanguageManager();
    _languageManager.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageManager.removeListener(_onLanguageChanged);
    _bookCodeController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  void _showAddBookDialog() {
    setState(() {
      _showAddBookModal = true;
    });
  }

  void _hideAddBookDialog() {
    setState(() {
      _showAddBookModal = false;
      _bookCodeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6DCED),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                children: [
                  // Header with logo and profile
                  Row(
                    children: [
                      // Logo
                      Row(
                        children: [
                          Image.asset(
                            AppAssets.iconLogo,
                            width: 32,
                            height: 32,
                          ),
                          const SizedBox(width: 8),

                          Image.asset(
                            AppAssets.appTextLogo,
                            scale: 10,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Language toggle
                      LanguageToggle(languageManager: _languageManager),
                      const SizedBox(width: 12),
                      // Profile icon
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const HeightSpacer(40),

                  Image.asset(AppAssets.homeTextImage, scale: 4),
                  // Quote box
                  // Container(
                  //   width: double.infinity,
                  //   padding: const EdgeInsets.all(20),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white.withOpacity(0.8),
                  //     borderRadius: BorderRadius.circular(16),
                  //   ),
                  //   child: Text(
                  //     _languageManager.getText(
                  //       'Une science qui vous accompagne pour l\'eternite',
                  //       'Une science qui vous accompagne pour l\'eternite',
                  //     ),
                  //     style: const TextStyle(
                  //       fontFamily: 'SFPro',
                  //       fontWeight: FontWeight.w700,
                  //       fontSize: 18,
                  //       fontStyle: FontStyle.italic,
                  //       color: AppColors.primary,
                  //       height: 1.3,
                  //     ),
                  //     textAlign: TextAlign.center,
                  //   ),
                  // ),
                  const HeightSpacer(40),
                  // Book image
                  Image.asset(AppAssets.bookImage, scale: 4),
                  const HeightSpacer(24),
                  // Empty library text
                  Text(
                    _languageManager.getText(
                      'Votre bibliothèque est vide',
                      'Votre bibliothèque est vide',
                    ),
                    style: const TextStyle(
                      fontFamily: 'SFPro',
                      fontWeight: FontWeight.w500,
                      fontSize: 24,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _languageManager.getText(
                        'Ajoutez votre premier livre en utilisant le code inclus dans votre achat chez Éditions Akhira.',
                        'Ajoutez votre premier livre en utilisant le code inclus dans votre achat chez Éditions Akhira.',
                      ),
                      style: const TextStyle(
                        fontFamily: 'SFPro',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0XFF788097),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Spacer(),
                  // Add book button
                  CustomButton(
                    label: _languageManager.getText(
                      'Add book',
                      'Ajoutez votre premier livre',
                    ),
                    onPressed: _showAddBookDialog,
                    useGradient: true,
                  ),
                  const HeightSpacer(40),
                ],
              ),
            ),
            // Add book modal
            if (_showAddBookModal)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0XFFD6DCED),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(
                          AppConstants.defaultPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Handle
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const HeightSpacer(20),
                            // Title
                            Text(
                              _languageManager.getText(
                                'Add your first book',
                                'Ajoutez votre premier livre',
                              ),
                              style: const TextStyle(
                                fontFamily: 'SFPro',
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            const HeightSpacer(16),
                            // Input field
                            CustomTextField(
                              controller: _bookCodeController,
                              hintText: _languageManager.getText(
                                'Enter book code',
                                'Entrez le code du livre',
                              ),
                            ),
                            const HeightSpacer(24),
                            // Verify button
                            CustomButton(
                              label: _languageManager.getText(
                                'Verify code',
                                'Vérifier le code',
                              ),
                              onPressed: () {
                                // TODO: Implement verify code logic
                                _hideAddBookDialog();
                              },
                              useGradient: false,
                              backgroundColor: AppColors.primary,
                              textColor: Colors.white,
                            ),
                            const HeightSpacer(16),
                            // Cancel button
                            Center(
                              child: GestureDetector(
                                onTap: _hideAddBookDialog,
                                child: Text(
                                  _languageManager.getText('Cancel', 'Annuler'),
                                  style: const TextStyle(
                                    fontFamily: 'SFPro',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const HeightSpacer(16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
