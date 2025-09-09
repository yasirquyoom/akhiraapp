import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../core/language/language_manager.dart';
import '../../data/cubits/audio/audio_cubit.dart';
import '../../data/cubits/book/book_state.dart';
import '../../data/cubits/book_content/book_content_state.dart';
import '../../data/cubits/quiz/quiz_cubit.dart';
import '../../router/app_router.dart';
import '../../widgets/language_toggle.dart';

class BookContentPage extends StatefulWidget {
  final int initialTabIndex;
  final String? bookId;

  const BookContentPage({super.key, this.initialTabIndex = 0, this.bookId});

  @override
  State<BookContentPage> createState() => _BookContentPageState();
}

class _BookContentPageState extends State<BookContentPage>
    with SingleTickerProviderStateMixin {
  late final LanguageManager _languageManager;
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _languageManager = LanguageManager();
    _languageManager.addListener(_onLanguageChanged);
    _currentTabIndex = widget.initialTabIndex;
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: _currentTabIndex,
    );
    _tabController.addListener(_onTabChanged);

    // Load book content - will use global state or widget parameter
    _loadContentForCurrentTab();
  }

  @override
  void dispose() {
    _languageManager.removeListener(_onLanguageChanged);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  void _onTabChanged() {
    setState(() {
      _currentTabIndex = _tabController.index;
    });

    // Load content for the new tab
    _loadContentForCurrentTab();
  }

  void _loadContentForCurrentTab() {
    // Get book ID from global state first, fallback to widget parameter
    final bookCubit = context.read<BookCubit>();
    String? bookId = bookCubit.getCurrentBookId();

    // If no book ID in global state, try widget parameter
    if (bookId == null && widget.bookId != null && widget.bookId!.isNotEmpty) {
      bookId = widget.bookId;
      // Set it in global state for future use
      bookCubit.setBook(bookId: bookId!, bookTitle: 'Unknown Book');
    }

    if (bookId == null || bookId.isEmpty) {
      print('Warning: Book ID is null or empty, cannot load content');
      return;
    }

    String? contentType;
    switch (_currentTabIndex) {
      case 0: // Digital book
        contentType = 'ebook';
        break;
      case 1: // Audio book
        contentType = 'audio';
        break;
      case 2: // Quiz
        contentType = 'quiz';
        break;
      case 3: // Videos
        contentType = 'video';
        break;
      case 4: // Images
        contentType = 'image';
        break;
    }

    print('Loading content for bookId: $bookId, contentType: $contentType');
    context.read<BookContentCubit>().loadContentByType(
      bookId: bookId,
      contentType: contentType ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Navigate back to the book details page
            context.go(AppRoutes.bookDetails);
          },
        ),
        title: BlocBuilder<BookContentCubit, BookContentState>(
          builder: (context, state) {
            if (state is BookContentLoaded && state.data.bookDetails != null) {
              return Text(
                state.data.bookDetails!.bookName,
                style: const TextStyle(
                  fontFamily: 'SFPro',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.black,
                ),
              );
            }
            return Text(
              'Book Content',
              style: const TextStyle(
                fontFamily: 'SFPro',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black,
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          LanguageToggle(languageManager: _languageManager),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,

            tabAlignment: TabAlignment.center,
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorPadding: EdgeInsets.symmetric(vertical: 4),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: AppColors.tabActiveBg,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontFamily: 'SFPro',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'SFPro',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            dividerColor: Colors.transparent, // Remove divider line
            tabs: [
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    _languageManager.getText('Digital book', 'Livre numérique'),
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    _languageManager.getText('Audio book', 'Livre audio'),
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(_languageManager.getText('Quiz', 'Quiz')),
                ),
              ),
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(_languageManager.getText('Videos', 'Vidéos')),
                ),
              ),
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(_languageManager.getText('Images', 'Images')),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDigitalBookTab(),
          _buildAudioTab(),
          _buildQuizTab(),
          _buildVideosTab(),
          _buildImagesTab(),
        ],
      ),
      bottomNavigationBar: BlocBuilder<AudioCubit, AudioState>(
        builder: (context, state) {
          if (state is AudioLoaded && state.currentTrack != null) {
            return _buildBottomPlayer(state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDigitalBookTab() {
    // Check if bookId is available in global state
    final bookCubit = context.read<BookCubit>();
    final bookId = bookCubit.getCurrentBookId();

    if (bookId == null || bookId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'No Book Selected',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please go back and select a book first',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text('Go to Home'),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<BookContentCubit, BookContentState>(
      builder: (context, state) {
        if (state is BookContentLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BookContentLoaded) {
          final ebookContents =
              state.data.contents
                  ?.where((content) => content.contentType == 'ebook')
                  .toList() ??
              [];

          if (ebookContents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf, size: 64.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'No PDF available',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildEbookList(ebookContents);
        } else if (state is BookContentError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  'Error loading content',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  state.message,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => _loadContentForCurrentTab(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('No content available'));
      },
    );
  }

  Widget _buildEbookList(List<dynamic> ebookContents) {
    return ListView.builder(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: ebookContents.length,
      itemBuilder: (context, index) {
        final ebook = ebookContents[index];
        return _buildEbookCard(ebook);
      },
    );
  }

  Widget _buildEbookCard(dynamic ebook) {
    return Padding(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // PDF Preview Card
          GestureDetector(
            onTap: () {
              // Navigate to PDF viewer with actual PDF data
              context.push(
                AppRoutes.pdfViewer,
                extra: {
                  'id': ebook.contentId,
                  'title': ebook.title,
                  'pdfUrl': ebook.fileUrl,
                  'thumbnailUrl': '', // We don't have thumbnail from API
                  'description': 'PDF from book content',
                  'totalPages': 0, // We don't have page count from API
                  'author': 'Unknown Author', // We don't have author from API
                },
              );
            },
            child: Container(
              width: double.infinity,
              height: 400.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // PDF Thumbnail
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.picture_as_pdf,
                        size: 64.sp,
                        color: Colors.grey[400],
                      ),
                    ),
                    // Overlay with PDF icon
                    Positioned(
                      top: 16.h,
                      right: 16.w,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ),
                    // Bottom overlay with PDF info
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ebook.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // SizedBox(height: 4.h),
                            // Text(
                            //   'File Size: ${ebook.fileSizeMb.toStringAsFixed(1)} MB',
                            //   style: TextStyle(
                            //     color: Colors.white70,
                            //     fontSize: 14.sp,
                            //   ),
                            // ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.pages,
                                  color: Colors.white70,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'PDF Document',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Read Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          // PDF Description
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  ebook.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioTab() {
    // Check if bookId is available in global state
    final bookCubit = context.read<BookCubit>();
    final bookId = bookCubit.getCurrentBookId();

    if (bookId == null || bookId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'No Book Selected',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please go back and select a book first',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text('Go to Home'),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<BookContentCubit, BookContentState>(
      builder: (context, state) {
        if (state is BookContentLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BookContentLoaded) {
          final audioContents =
              state.data.contents
                  ?.where((content) => content.contentType == 'audio')
                  .toList() ??
              [];

          if (audioContents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.audiotrack, size: 64.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'No audio tracks available',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildAudioList(audioContents);
        } else if (state is BookContentError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const Center(child: Text('No audio tracks'));
      },
    );
  }

  Widget _buildAudioList(List<dynamic> audioContents) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: audioContents.length,
      itemBuilder: (context, index) {
        final audio = audioContents[index];
        return _buildAudioTrackCard(audio);
      },
    );
  }

  Widget _buildAudioTrackCard(dynamic audio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: Icon(Icons.audiotrack, color: Colors.grey[400], size: 30),
          ),
          const SizedBox(width: 16),
          // Track Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  audio.title,
                  maxLines: 2,
                  style: const TextStyle(
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                // const SizedBox(height: 4),
                // Text(
                //   'File Size: ${audio.fileSizeMb.toStringAsFixed(1)} MB',
                //   style: const TextStyle(
                //     fontFamily: 'SFPro',
                //     fontWeight: FontWeight.w500,
                //     fontSize: 14,
                //     color: Colors.grey,
                //   ),
                // ),
              ],
            ),
          ),
          // Play Button
          GestureDetector(
            onTap: () {
              // Create an AudioTrack from the BookContent audio data
              final audioTrack = AudioTrack(
                id: audio.contentId ?? 'unknown',
                title: audio.title,
                duration: '0:00', // We don't have duration from API
                audioUrl: audio.fileUrl ?? '',
                thumbnailUrl: '', // BookContent doesn't have thumbnailUrl field
              );

              // Start playing the audio track
              context.read<AudioCubit>().playTrack(audioTrack);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.tabActiveBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPlayer(AudioLoaded state) {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.audioFullscreen);
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E4FB6), Color(0xFF142350)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSbOWfIYTEzWQ4i2ryypJlyIQQ2G_GPTpr0pQ&usqp=CAU',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Track Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.currentTrack?.title ?? 'Title',
                    style: const TextStyle(
                      fontFamily: 'SFPro',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white, // Changed from black to white
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.currentTrack?.duration ?? '45 min 3 sec',
                    style: const TextStyle(
                      fontFamily: 'SFPro',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.white70, // Changed from grey to white70
                    ),
                  ),
                ],
              ),
            ),
            // Controls
            Row(
              children: [
                IconButton(
                  onPressed: () => context.read<AudioCubit>().previousTrack(),
                  icon: const Icon(
                    Icons.skip_previous,
                    color: Colors.white,
                  ), // Changed from black to white
                ),
                IconButton(
                  onPressed: () {
                    if (state.isPlaying) {
                      context.read<AudioCubit>().pauseTrack();
                    } else {
                      context.read<AudioCubit>().resumeTrack();
                    }
                  },
                  icon: Icon(
                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white, // Changed from black to white
                    size: 32,
                  ),
                ),
                IconButton(
                  onPressed: () => context.read<AudioCubit>().nextTrack(),
                  icon: const Icon(
                    Icons.skip_next,
                    color: Colors.white,
                  ), // Changed from black to white
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizTab() {
    return BlocBuilder<QuizCubit, QuizState>(
      builder: (context, state) {
        if (state is QuizLoaded) {
          return _buildQuizContent(state);
        } else if (state is QuizCompleted) {
          return _buildQuizCompleted(state);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildQuizContent(QuizLoaded state) {
    return Stack(
      children: [
        // Main quiz content
        SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score and Progress Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(30.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryGradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    // Score
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${state.correctAnswers}',
                            style: TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w700,
                              fontSize: 32.sp,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _languageManager.getText('My score', 'Mon score'),
                            style: TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Container(
                      width: 5,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    // Question Progress
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${state.currentQuestionIndex + 1}/${state.totalQuestions}',
                            style: TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w700,
                              fontSize: 32.sp,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _languageManager.getText('Questions', 'Questions'),
                            style: TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Question
              Text(
                state.currentQuestion.question,
                style: TextStyle(
                  fontFamily: 'SFPro',
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: 24.h),

              // Options
              ...state.currentQuestion.options.map(
                (option) => _buildQuizOption(
                  option,
                  state.selectedOptionId == option.id,
                ),
              ),

              SizedBox(height: 24.h),

              // Navigation Buttons Row
              Row(
                children: [
                  // Back Button (only show for questions 2-5)
                  if (!state.isFirstQuestion) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            () => context.read<QuizCubit>().previousQuestion(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade700,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _languageManager.getText('Back', 'Retour'),
                              style: TextStyle(
                                fontFamily: 'SFPro',
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                  ],

                  // Next/Submit Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          state.selectedOptionId != null
                              ? () {
                                context.read<QuizCubit>().submitAnswer();
                                context.read<QuizCubit>().nextQuestion();
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            state.selectedOptionId != null
                                ? AppColors.primary
                                : Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            state.isLastQuestion
                                ? _languageManager.getText('Submit', 'Envoyer')
                                : _languageManager.getText('Next', 'Suivant'),
                            style: TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                              color:
                                  state.selectedOptionId != null
                                      ? Colors.white
                                      : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizOption(QuizOption option, bool isSelected) {
    return GestureDetector(
      onTap: () => context.read<QuizCubit>().selectOption(option.id),
      child: Container(
        margin: EdgeInsets.only(bottom: 20.h),
        child: Row(
          children: [
            // Option Letter Circle
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryGradientEnd],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  option.letter,
                  style: TextStyle(
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(width: 16.w),

            // Option Text
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(
                  fontFamily: 'SFPro',
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                  color: Colors.black,
                ),
              ),
            ),

            // Radio Button
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child:
                  isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 16.sp)
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCompleted(QuizCompleted state) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _languageManager.getText('Quiz Completed!', 'Quiz Terminé!'),
              style: TextStyle(
                fontFamily: 'SFPro',
                fontWeight: FontWeight.w700,
                fontSize: 24.sp,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              _languageManager.getText(
                'Your score: ${state.score}/${state.totalQuestions}',
                'Votre score: ${state.score}/${state.totalQuestions}',
              ),
              style: TextStyle(
                fontFamily: 'SFPro',
                fontWeight: FontWeight.w500,
                fontSize: 18.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () => context.read<QuizCubit>().restartQuiz(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                _languageManager.getText('Restart', 'Recommencer'),
                style: TextStyle(
                  fontFamily: 'SFPro',
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosTab() {
    // Check if bookId is available in global state
    final bookCubit = context.read<BookCubit>();
    final bookId = bookCubit.getCurrentBookId();

    if (bookId == null || bookId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'No Book Selected',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please go back and select a book first',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text('Go to Home'),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<BookContentCubit, BookContentState>(
      builder: (context, state) {
        if (state is BookContentLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BookContentLoaded) {
          final videoContents =
              state.data.contents
                  ?.where((content) => content.contentType == 'video')
                  .toList() ??
              [];

          if (videoContents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam, size: 64.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'No videos available',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildVideoList(videoContents);
        } else if (state is BookContentError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  'Error loading videos',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  state.message,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => _loadContentForCurrentTab(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('No videos available'));
      },
    );
  }

  Widget _buildVideoList(List<dynamic> videoContents) {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: videoContents.length,
      itemBuilder: (context, index) {
        final video = videoContents[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildVideoCard(dynamic video) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: GestureDetector(
        onTap: () {
          // Navigate to video fullscreen page with video data
          context.push(
            AppRoutes.videoFullscreen,
            extra: {
              'title': video.title,
              'videoUrl': video.fileUrl ?? '',
              'thumbnailUrl': '', // BookContent doesn't have thumbnailUrl field
              'fileSize': video.fileSizeMb,
            },
          );
        },
        child: Container(
          height: 200.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Stack(
              children: [
                // Thumbnail Image
                Positioned.fill(
                  child: Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.videocam,
                      size: 64.sp,
                      color: Colors.grey[400],
                    ),
                  ),
                ),

                // Play Button Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32.sp,
                        ),
                      ),
                    ),
                  ),
                ),

                // Video Info
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          video.title,
                          style: TextStyle(
                            fontFamily: 'SFPro',
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // SizedBox(height: 4.h),
                        // Text(
                        //   'File Size: ${video.fileSizeMb.toStringAsFixed(1)} MB',
                        //   style: TextStyle(
                        //     fontFamily: 'SFPro',
                        //     fontWeight: FontWeight.w500,
                        //     fontSize: 14.sp,
                        //     color: Colors.white70,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagesTab() {
    // Check if bookId is available in global state
    final bookCubit = context.read<BookCubit>();
    final bookId = bookCubit.getCurrentBookId();

    if (bookId == null || bookId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'No Book Selected',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please go back and select a book first',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text('Go to Home'),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<BookContentCubit, BookContentState>(
      builder: (context, state) {
        if (state is BookContentLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BookContentLoaded) {
          final imageContents =
              state.data.contents
                  ?.where((content) => content.contentType == 'image')
                  .toList() ??
              [];

          if (imageContents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 64.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'No images available',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildImageCardStack(imageContents);
        } else if (state is BookContentError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const Center(child: Text('No images available'));
      },
    );
  }

  Widget _buildImageCardStack(List<dynamic> imageContents) {
    return _ImageCardStackWidget(imageContents: imageContents);
  }
}

class _ImageCardStackWidget extends StatefulWidget {
  final List<dynamic> imageContents;

  const _ImageCardStackWidget({required this.imageContents});

  @override
  State<_ImageCardStackWidget> createState() => _ImageCardStackWidgetState();
}

class _ImageCardStackWidgetState extends State<_ImageCardStackWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _currentIndex = 0;
  double _dragDistance = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _isDragging = true;
      },
      onPanUpdate: (details) {
        if (_isDragging) {
          setState(() {
            _dragDistance += details.delta.dx;
          });
        }
      },
      onPanEnd: (details) {
        _isDragging = false;

        // Determine swipe direction and velocity
        final velocity = details.velocity.pixelsPerSecond.dx;
        final dragThreshold = 100.0;

        if (_dragDistance.abs() > dragThreshold || velocity.abs() > 500) {
          if (_dragDistance > 0 || velocity > 0) {
            // Swipe right - previous image
            _previousImage();
          } else {
            // Swipe left - next image
            _nextImage();
          }
        }

        // Reset drag distance
        setState(() {
          _dragDistance = 0.0;
        });
      },
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Background cards (stacked behind)
            ..._buildBackgroundCards(),

            // Main card (on top)
            _buildMainCard(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundCards() {
    final cards = <Widget>[];
    final maxBackgroundCards = math.min(3, widget.imageContents.length - 1);

    for (int i = 1; i <= maxBackgroundCards; i++) {
      final cardIndex = (_currentIndex + i) % widget.imageContents.length;
      final scale = 1.0 - (i * 0.02); // Each card is 2% smaller
      final offset = i * 20.0; // Each card is offset by 20px

      cards.add(
        Positioned(
          top: offset,
          left: offset,
          right: offset,
          bottom: offset,
          child: Transform.scale(
            scale: scale,
            child: _buildCard(
              widget.imageContents[cardIndex],
              opacity: 0.7 - (i * 0.1), // Much more visible opacity
              isBackground: true,
            ),
          ),
        ),
      );
    }

    return cards.reversed.toList(); // Reverse to show cards in correct order
  }

  Widget _buildMainCard() {
    final currentImage = widget.imageContents[_currentIndex];
    final rotation = _dragDistance * 0.001; // Convert drag distance to rotation
    final opacity = math.max(0.0, 1.0 - (_dragDistance.abs() * 0.002));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_dragDistance, 0),
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(opacity: opacity, child: _buildCard(currentImage)),
          ),
        );
      },
    );
  }

  Widget _buildCard(
    dynamic image, {
    double opacity = 1.0,
    bool isBackground = false,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 10.h, bottom: 40.h, left: 20.w, right: 20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20.r)),
        color: isBackground ? Colors.white.withOpacity(0.1) : null,
        border:
            isBackground
                ? Border.all(color: Colors.white.withOpacity(0.6), width: 2.0)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(20.r)),
        child: Stack(
          children: [
            // Image
            Image.network(
              image.fileUrl ?? '',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),

            // Bottom overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      image.title,
                      style: TextStyle(
                        fontFamily: 'SFPro',
                        fontWeight: FontWeight.w600,
                        fontSize: 18.sp,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // SizedBox(height: 8.h),
                    // Text(
                    //   'File Size: ${image.fileSizeMb.toStringAsFixed(1)} MB',
                    //   style: TextStyle(
                    //     fontFamily: 'SFPro',
                    //     fontWeight: FontWeight.w500,
                    //     fontSize: 14.sp,
                    //     color: Colors.white70,
                    //   ),
                    // ),
                    SizedBox(height: 4.h),
                    Text(
                      'Image ${_currentIndex + 1} of ${widget.imageContents.length}',
                      style: TextStyle(
                        fontFamily: 'SFPro',
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextImage() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.imageContents.length;
    });
  }

  void _previousImage() {
    setState(() {
      _currentIndex =
          _currentIndex == 0
              ? widget.imageContents.length - 1
              : _currentIndex - 1;
    });
  }
}
