import 'package:akhira/widgets/width_spacer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_constants.dart';
import '../../core/language/language_manager.dart';
import '../../data/cubits/book/book_state.dart';
import '../../data/models/book_model.dart';
import '../../router/app_router.dart';
import '../../widgets/height_spacer.dart';
import '../../widgets/language_toggle.dart';

class BookDetailsPage extends StatefulWidget {
  final BookModel? book;

  const BookDetailsPage({super.key, this.book});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  late final LanguageManager _languageManager;

  @override
  void initState() {
    super.initState();
    _languageManager = LanguageManager();
    _languageManager.addListener(_onLanguageChanged);

    // Set book ID in global state when page loads
    if (widget.book != null) {
      context.read<BookCubit>().setBook(
        bookId: widget.book!.id,
        bookTitle: widget.book!.title,
      );
    }
  }

  @override
  void dispose() {
    _languageManager.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Text(
          widget.book?.title ?? 'Book Details',
          style: const TextStyle(
            fontFamily: 'SFPro',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          LanguageToggle(languageManager: _languageManager),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              // Book Information Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2E4FB6), Color(0xff142350)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Book Cover
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image:
                              widget.book?.coverImageUrl != null
                                  ? DecorationImage(
                                    image: NetworkImage(
                                      widget.book!.coverImageUrl,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                  : const DecorationImage(
                                    image: NetworkImage(
                                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSbOWfIYTEzWQ4i2ryypJlyIQQ2G_GPTpr0pQ&usqp=CAU',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Book Details
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.book?.title ?? 'Unknown Book',
                            style: const TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                          const HeightSpacer(16),
                          _buildBookDetail(
                            'Author',
                            widget.book?.author ?? 'Unknown',
                          ),
                          const HeightSpacer(8),
                          _buildBookDetail(
                            'Edition',
                            widget.book?.editionName ?? 'Unknown',
                          ),
                          const HeightSpacer(8),
                          _buildBookDetail(
                            'Pages',
                            widget.book?.totalPages?.toString() ?? 'Unknown',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const HeightSpacer(32),
              // Content Options Grid
              _buildContentGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookDetail(String label, String value) {
    return Text(
      '$label: $value',
      style: const TextStyle(
        fontFamily: 'SFPro',
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildContentGrid() {
    return Column(
      children: [
        // First Row - 2 items
        Row(
          children: [
            Expanded(
              child: _buildContentCard(
                icon: AppAssets.iconEbook,
                title: _languageManager.getText(
                  'Digital book',
                  'Livre numérique',
                ),
                onTap: () {
                  if (widget.book?.id == null) {
                    return;
                  }
                  // Set book ID in global state
                  context.read<BookCubit>().setBook(
                    bookId: widget.book!.id,
                    bookTitle: widget.book!.title,
                  );
                  context.push(
                    '${AppRoutes.bookContent}?tab=0&bookId=${widget.book!.id}',
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildContentCard(
                icon: AppAssets.iconAudio,
                title: _languageManager.getText('Audio book', 'Livre audio'),
                onTap: () {
                  if (widget.book?.id == null) {
                    return;
                  }
                  // Set book ID in global state
                  context.read<BookCubit>().setBook(
                    bookId: widget.book!.id,
                    bookTitle: widget.book!.title,
                  );
                  context.push(
                    '${AppRoutes.bookContent}?tab=1&bookId=${widget.book!.id}',
                  );
                },
              ),
            ),
          ],
        ),
        const HeightSpacer(16),
        // Second Row - 2 items
        Row(
          children: [
            Expanded(
              child: _buildContentCard(
                icon: AppAssets.iconQuiz,
                title: _languageManager.getText('Quiz', 'Quiz'),
                onTap: () {
                  if (widget.book?.id == null) {
                    return;
                  }
                  // Set book ID in global state
                  context.read<BookCubit>().setBook(
                    bookId: widget.book!.id,
                    bookTitle: widget.book!.title,
                  );
                  context.push(
                    '${AppRoutes.bookContent}?tab=2&bookId=${widget.book!.id}',
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildContentCard(
                icon: AppAssets.iconVideo,
                title: _languageManager.getText('Videos', 'Vidéos'),
                onTap: () {
                  if (widget.book?.id == null) {
                    return;
                  }
                  // Set book ID in global state
                  context.read<BookCubit>().setBook(
                    bookId: widget.book!.id,
                    bookTitle: widget.book!.title,
                  );
                  context.push(
                    '${AppRoutes.bookContent}?tab=3&bookId=${widget.book!.id}',
                  );
                },
              ),
            ),
          ],
        ),
        const HeightSpacer(16),
        // Third Row - 1 centered item
        GestureDetector(
          onTap: () {
            if (widget.book?.id == null) {
              return;
            }
            // Set book ID in global state
            context.read<BookCubit>().setBook(
              bookId: widget.book!.id,
              bookTitle: widget.book!.title,
            );
            context.push(
              '${AppRoutes.bookContent}?tab=4&bookId=${widget.book!.id}',
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(AppAssets.iconImages, scale: 4),
                const WidthSpacer(16),
                Text(
                  _languageManager.getText('Images', 'Images'),
                  style: const TextStyle(
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(icon, width: 60, height: 60),
            const HeightSpacer(12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'SFPro',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
