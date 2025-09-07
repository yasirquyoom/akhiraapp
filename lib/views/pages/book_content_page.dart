import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../core/language/language_manager.dart';
import '../../data/cubits/audio/audio_cubit.dart';
import '../../data/cubits/images/images_cubit.dart';
import '../../data/cubits/pdf/pdf_cubit.dart';
import '../../data/cubits/quiz/quiz_cubit.dart';
import '../../data/cubits/videos/videos_cubit.dart';
import '../../data/models/pdf_model.dart';
import '../../data/models/video_model.dart';
import '../../router/app_router.dart';
import '../../widgets/language_toggle.dart';
import '../../widgets/image_card_stack.dart';

class BookContentPage extends StatefulWidget {
  final int initialTabIndex;

  const BookContentPage({super.key, this.initialTabIndex = 0});

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
        title: Text(
          'Patrick Ness',
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
    return BlocBuilder<PdfCubit, PdfState>(
      builder: (context, state) {
        if (state is PdfLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PdfLoaded) {
          return _buildPdfCard(state.pdf);
        } else if (state is PdfError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  'Error loading PDF',
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
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () => context.read<PdfCubit>().reloadPdf(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Retry', style: TextStyle(fontSize: 16.sp)),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('No PDF available'));
      },
    );
  }

  Widget _buildPdfCard(PdfModel pdf) {
    return Padding(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // PDF Preview Card
          GestureDetector(
            onTap: () => context.go(AppRoutes.pdfViewer),
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
                    CachedNetworkImage(
                      imageUrl: pdf.thumbnailUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.picture_as_pdf,
                              size: 64.sp,
                              color: Colors.grey[400],
                            ),
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
                              pdf.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'By ${pdf.author}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              ),
                            ),
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
                                  '${pdf.totalPages} pages',
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
                  pdf.description,
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
    return BlocBuilder<AudioCubit, AudioState>(
      builder: (context, state) {
        if (state is AudioLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AudioLoaded) {
          return _buildAudioList(state);
        } else if (state is AudioError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const Center(child: Text('No audio tracks'));
      },
    );
  }

  Widget _buildAudioList(AudioLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: state.tracks.length,
      itemBuilder: (context, index) {
        final track = state.tracks[index];
        return _buildAudioTrackCard(track, state);
      },
    );
  }

  Widget _buildAudioTrackCard(AudioTrack track, AudioLoaded state) {
    final isCurrentlyPlaying =
        state.currentTrack?.id == track.id && state.isPlaying;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Changed from gradient to white
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
              image: const DecorationImage(
                image: NetworkImage(
                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSbOWfIYTEzWQ4i2ryypJlyIQQ2G_GPTpr0pQ&usqp=CAU',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Track Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black, // Changed from white to black
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track.duration,
                  style: const TextStyle(
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.grey, // Changed from white70 to grey
                  ),
                ),
              ],
            ),
          ),
          // Play/Pause Button
          GestureDetector(
            onTap: () {
              if (isCurrentlyPlaying) {
                context.read<AudioCubit>().pauseTrack();
              } else {
                context.read<AudioCubit>().playTrack(track);
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.tabActiveBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
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
    return BlocBuilder<VideosCubit, VideosState>(
      builder: (context, state) {
        if (state is VideosLoaded) {
          return _buildVideoList(state);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildVideoList(VideosLoaded state) {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: state.videos.length,
      itemBuilder: (context, index) {
        final video = state.videos[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildVideoCard(VideoModel video) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: GestureDetector(
        onTap: () {
          // Navigate to fullscreen video player
          context.go('${AppRoutes.videoFullscreen}?videoId=${video.id}');
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
                  child: CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.error, color: Colors.grey),
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
                        SizedBox(height: 4.h),
                        Text(
                          video.duration,
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
        ),
      ),
    );
  }

  Widget _buildImagesTab() {
    return BlocBuilder<ImagesCubit, ImagesState>(
      builder: (context, state) {
        if (state is ImagesLoaded) {
          return _buildImageGallery(state);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildImageGallery(ImagesLoaded state) {
    return ImageCardStack(
      state: state,
      onSwipeLeft: () => context.read<ImagesCubit>().nextImage(),
      onSwipeRight: () => context.read<ImagesCubit>().previousImage(),
      onDownload: () async {
        try {
          await context.read<ImagesCubit>().downloadImage(
            state.images[state.currentIndex].imageUrl,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image downloaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Download failed: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      onShare: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share functionality coming soon!')),
        );
      },
    );
  }
}
