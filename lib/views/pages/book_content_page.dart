import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../core/language/language_manager.dart';
import '../../data/cubits/audio/audio_cubit.dart';
import '../../data/cubits/images/images_cubit.dart';
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
          onPressed: () => context.pop(),
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
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.tabActiveBg,
            ),
            labelColor: Colors.black,
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
    return const Center(child: Text('PDF Content - Coming Soon'));
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
                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
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
                color: Colors.black,
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
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
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
    return const Center(child: Text('Quiz Content - Coming Soon'));
  }

  Widget _buildVideosTab() {
    return const Center(child: Text('Video Player - Coming Soon'));
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
    return Stack(
      children: [
        // Main image with swipe functionality
        GestureDetector(
          onPanEnd: (details) {
            if (details.velocity.pixelsPerSecond.dx > 300) {
              // Swipe right - previous image
              context.read<ImagesCubit>().previousImage();
            } else if (details.velocity.pixelsPerSecond.dx < -300) {
              // Swipe left - next image
              context.read<ImagesCubit>().nextImage();
            }
          },
          child: Container(
            margin: EdgeInsets.only(
              top: 10.h,
              bottom: 40.h,
              left: 20.w,
              right: 20.w,
            ),
            width: double.infinity,
            height: double.infinity,

            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.all(Radius.circular(20.r)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(20.r)),
              child: Image.network(
                state.images[state.currentIndex].imageUrl,
                fit: BoxFit.cover,
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
            ),
          ),
        ),

        // Bottom overlay with title and controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
            ),
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image title
                Text(
                  state.images[state.currentIndex].title,
                  style: TextStyle(
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w600,
                    fontSize: 18.sp,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Download button
                    GestureDetector(
                      onTap: () async {
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
                      child: Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child:
                            state.isDownloading
                                ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                : Icon(
                                  Icons.download,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Share button
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement share functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Share functionality coming soon!'),
                          ),
                        );
                      },
                      child: Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Next image preview (bottom right corner)
        if (state.images.length > 1)
          Positioned(
            bottom: 20.h,
            right: 20.w,
            child: GestureDetector(
              onTap: () => context.read<ImagesCubit>().nextImage(),
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Image.network(
                    state
                        .images[(state.currentIndex + 1) % state.images.length]
                        .imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
