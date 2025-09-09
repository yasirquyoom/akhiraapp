import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/language/language_manager.dart';
import '../../data/cubits/audio/audio_cubit.dart';
import '../../widgets/language_toggle.dart';

class AudioFullscreenPage extends StatefulWidget {
  const AudioFullscreenPage({super.key});

  @override
  State<AudioFullscreenPage> createState() => _AudioFullscreenPageState();
}

class _AudioFullscreenPageState extends State<AudioFullscreenPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _swipeController;
  late Animation<double> _swipeAnimation;
  late LanguageManager _languageManager;

  @override
  void initState() {
    super.initState();
    _languageManager = getIt<LanguageManager>();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _swipeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioCubit, AudioState>(
      builder: (context, state) {
        if (state is! AudioLoaded || state.currentTrack == null) {
          return Scaffold(
            backgroundColor: AppColors.primaryGradientEnd,
            body: const Center(
              child: Text(
                'No audio playing',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.primaryGradientEnd,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Top Controls
                  _buildTopControls(),

                  // Main Content
                  Expanded(child: _buildMainContent(state)),

                  // Bottom Controls
                  _buildBottomControls(state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopControls() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          // Language Toggle
          LanguageToggle(languageManager: _languageManager),
        ],
      ),
    );
  }

  Widget _buildMainContent(AudioLoaded state) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Add haptic feedback
        HapticFeedback.lightImpact();

        // Swipe left = next track
        if (details.primaryVelocity! > 0) {
          context.read<AudioCubit>().previousTrack();
        }
        // Swipe right = previous track
        else if (details.primaryVelocity! < 0) {
          context.read<AudioCubit>().nextTrack();
        }
      },
      onHorizontalDragUpdate: (details) {
        // Visual feedback during swipe
        if (details.delta.dx.abs() > 5) {
          _swipeController.forward().then((_) {
            _swipeController.reverse();
          });
        }
      },
      child: AnimatedBuilder(
        animation: _swipeAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_swipeAnimation.value * 0.05),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Album Art
                  Container(
                    width: 300.w,
                    height: 300.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: Image.network(
                        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSbOWfIYTEzWQ4i2ryypJlyIQQ2G_GPTpr0pQ&usqp=CAU',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryGradientEnd,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 80,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  // Track Title
                  Text(
                    state.currentTrack!.title,
                    style: TextStyle(
                      fontFamily: 'SFPro',
                      fontWeight: FontWeight.w700,
                      fontSize: 24.sp,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 8.h),

                  // Artist/Author
                  Text(
                    state.currentTrack?.title ?? 'Unknown Artist',
                    style: TextStyle(
                      fontFamily: 'SFPro',
                      fontWeight: FontWeight.w500,
                      fontSize: 16.sp,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 20.h),

                  // // Swipe Hint
                  // Text(
                  //   'Swipe left/right to change tracks',
                  //   style: TextStyle(
                  //     fontFamily: 'SFPro',
                  //     fontWeight: FontWeight.w400,
                  //     fontSize: 12.sp,
                  //     color: Colors.white.withOpacity(0.6),
                  //   ),
                  //   textAlign: TextAlign.center,
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomControls(AudioLoaded state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        children: [
          // Progress Bar
          _buildProgressBar(state),

          SizedBox(height: 20.h),

          // Control Buttons
          _buildControlButtons(state),
        ],
      ),
    );
  }

  Widget _buildProgressBar(AudioLoaded state) {
    return Column(
      children: [
        // Progress Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
            trackHeight: 4.h,
          ),
          child: Slider(
            value:
                state.currentPosition.inMilliseconds /
                (state.totalDuration.inMilliseconds > 0
                    ? state.totalDuration.inMilliseconds
                    : 1),
            onChanged: (value) {
              final newPosition = Duration(
                milliseconds:
                    (value * state.totalDuration.inMilliseconds).round(),
              );
              context.read<AudioCubit>().updatePosition(newPosition);
            },
            min: 0.0,
            max: 1.0,
          ),
        ),

        // Time Labels
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(state.currentPosition),
                style: TextStyle(
                  fontFamily: 'SFPro',
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                  color: Colors.white70,
                ),
              ),
              Text(
                _formatTime(state.totalDuration),
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
    );
  }

  Widget _buildControlButtons(AudioLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle Button
        IconButton(
          onPressed: () {
            // TODO: Implement shuffle functionality
          },
          icon: Icon(
            Icons.shuffle,
            color: Colors.white.withOpacity(0.7),
            size: 24.sp,
          ),
        ),

        // Previous Button
        IconButton(
          onPressed: () => context.read<AudioCubit>().previousTrack(),
          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
        ),

        // Play/Pause Button
        GestureDetector(
          onTap: () {
            if (state.isPlaying) {
              context.read<AudioCubit>().pauseTrack();
            } else {
              context.read<AudioCubit>().resumeTrack();
            }
          },
          child: Container(
            width: 70.w,
            height: 70.w,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              state.isPlaying ? Icons.pause : Icons.play_arrow,
              color: AppColors.primaryGradientEnd,
              size: 32.sp,
            ),
          ),
        ),

        // Next Button
        IconButton(
          onPressed: () => context.read<AudioCubit>().nextTrack(),
          icon: const Icon(Icons.skip_next, color: Colors.white, size: 32),
        ),

        // Repeat Button
        IconButton(
          onPressed: () {
            // TODO: Implement repeat functionality
          },
          icon: Icon(
            Icons.repeat,
            color: Colors.white.withOpacity(0.7),
            size: 24.sp,
          ),
        ),
      ],
    );
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
