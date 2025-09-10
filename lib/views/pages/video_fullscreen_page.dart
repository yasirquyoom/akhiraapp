import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/video_model.dart';
import '../../constants/app_colors.dart';
import '../../router/app_router.dart';

class VideoFullscreenPage extends StatefulWidget {
  final VideoModel video;

  const VideoFullscreenPage({super.key, required this.video});

  @override
  State<VideoFullscreenPage> createState() => _VideoFullscreenPageState();
}

class _VideoFullscreenPageState extends State<VideoFullscreenPage> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl),
      );

      await _controller.initialize();
      setState(() {
        _isLoading = false;
      });

      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration) {
          setState(() {
            _isPlaying = false;
          });
          _controller.pause();
        }
      });
    } catch (e) {
      print('Error initializing video: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    // Reset orientation to allow all orientations when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _toggleLandscape() {
    setState(() {
      _isLandscape = !_isLandscape;
    });

    if (_isLandscape) {
      // Force landscape orientation
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Force portrait orientation
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Player
          Center(
            child:
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : _hasError
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 64.sp,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Failed to load video',
                          style: TextStyle(
                            fontFamily: 'SFPro',
                            fontWeight: FontWeight.w600,
                            fontSize: 18.sp,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Please check your internet connection',
                          style: TextStyle(
                            fontFamily: 'SFPro',
                            fontWeight: FontWeight.w400,
                            fontSize: 14.sp,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _hasError = false;
                            });
                            _initializeVideo();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                    : AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
          ),

          // Controls Overlay
          if (_showControls)
            GestureDetector(
              onTap: _toggleControls,
              child: Container(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    // Top Controls
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 16.h,
                          left: 16.w,
                          right: 16.w,
                          bottom: 16.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            // Back Button
                            GestureDetector(
                              onTap:
                                  () => context.go(
                                    '${AppRoutes.bookContent}?tab=3',
                                  ),
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.back,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            // Landscape Toggle Button
                            GestureDetector(
                              onTap: _toggleLandscape,
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isLandscape
                                      ? Icons.screen_rotation
                                      : Icons.screen_rotation_alt,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            // Video Title
                            Expanded(
                              child: Text(
                                widget.video.title,
                                style: TextStyle(
                                  fontFamily: 'SFPro',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.sp,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Center Play/Pause Button
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 40.sp,
                          ),
                        ),
                      ),
                    ),

                    // Bottom Controls
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
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Progress Bar
                            VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: AppColors.primary,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                bufferedColor: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            // Time and Duration
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_controller.value.position),
                                  style: TextStyle(
                                    fontFamily: 'SFPro',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.sp,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _formatDuration(_controller.value.duration),
                                  style: TextStyle(
                                    fontFamily: 'SFPro',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.sp,
                                    color: Colors.white,
                                  ),
                                ),
                                // Landscape Toggle Button (Bottom)
                                GestureDetector(
                                  onTap: _toggleLandscape,
                                  child: Container(
                                    padding: EdgeInsets.all(6.w),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isLandscape
                                          ? Icons.screen_rotation
                                          : Icons.screen_rotation_alt,
                                      color: Colors.white,
                                      size: 20.sp,
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

          // Tap to show/hide controls
          if (!_showControls)
            GestureDetector(
              onTap: _toggleControls,
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
        ],
      ),
    );
  }
}
