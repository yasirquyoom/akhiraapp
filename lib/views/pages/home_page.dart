import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../core/language/language_manager.dart';
import '../../data/cubits/auth/auth_cubit.dart';
import '../../data/cubits/home/home_cubit.dart';
import '../../data/cubits/home/home_state.dart';
import '../../data/models/book_model.dart';
import '../../router/app_router.dart';
import '../../widgets/book_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_feedback.dart';
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

  void _addBook() {
    final bookCode = _bookCodeController.text.trim();
    if (bookCode.isNotEmpty) {
      try {
        final homeCubit = context.read<HomeCubit>();
        homeCubit.redeemBook(bookCode);
      } catch (e) {
        context.showErrorFeedback('Error: $e');
        _hideAddBookDialog();
      }
    } else {
      context.showWarningFeedback('Please enter a book code');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6DCED),
      body: SafeArea(
        child: BlocListener<HomeCubit, HomeState>(
          listener: (context, state) {
            if (state is HomeRedeemSuccess) {
              context.showSuccessFeedback(state.message);
              _hideAddBookDialog(); // Close modal on success
            } else if (state is HomeRedeemError) {
              context.showErrorFeedback(state.message);
              _hideAddBookDialog(); // Close modal on error
            } else if (state is HomeError) {
              context.showErrorFeedback(state.message);
            }
          },
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              return Stack(
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
                            // Profile icon with logout
                            GestureDetector(
                              onTap: () => _showLogoutDialog(),
                              child: Container(
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
                            ),
                          ],
                        ),
                        const HeightSpacer(20),
                        // Content based on state
                        Expanded(
                          child:
                              state is HomeLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : state is HomeEmpty
                                  ? _buildEmptyState()
                                  : state is HomeLoaded
                                  ? _buildLibraryState(state.books)
                                  : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                  // Add book modal
                  if (_showAddBookModal) _buildAddBookModal(state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Image.asset(AppAssets.homeTextImage, scale: 4),
        const HeightSpacer(40),
        Image.asset(AppAssets.bookImage, scale: 4),
        const HeightSpacer(24),
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
        const Spacer(),
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
    );
  }

  Widget _buildLibraryState(List<BookModel> books) {
    return Column(
      children: [
        // Library header with + button
        Row(
          children: [
            Text(
              _languageManager.getText('My Library', 'Ma Bibliothèque'),
              style: const TextStyle(
                fontFamily: 'SFPro',
                fontWeight: FontWeight.w700,
                fontSize: 24,
                fontStyle: FontStyle.italic,
                color: Color(0xff0C1138),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _showAddBookDialog,
              child: const Icon(Icons.add, color: Color(0xff0C1138), size: 30),
            ),
          ],
        ),
        const HeightSpacer(20),
        // Books grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return BookCard(
                book: books[index],
                onTap: () {
                  context.go(AppRoutes.bookDetails, extra: books[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddBookModal(HomeState state) {
    return Container(
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
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
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
                    state is HomeEmpty
                        ? _languageManager.getText(
                          'Add your first book',
                          'Ajoutez votre premier livre',
                        )
                        : _languageManager.getText(
                          'Add another book',
                          'Ajouter un autre livre',
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
                  state is HomeRedeeming
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButton(
                        label: _languageManager.getText(
                          'Verify code',
                          'Vérifier le code',
                        ),
                        onPressed: _addBook,
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
    );
  }
}
