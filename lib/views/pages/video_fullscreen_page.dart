import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/video_model.dart';
import '../../constants/app_colors.dart';
import '../../router/app_router.dart';
import '../../utils/fullscreen_util_stub.dart' if (dart.library.html) '../../utils/fullscreen_util_web.dart';
import '../../services/video_cache_service.dart';

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
  bool _isFullscreen = false;
  double _volume = 1.0;
  double _lastNonZeroVolume = 1.0;
  bool _isMuted = false;
  double _playbackSpeed = 1.0;
  String? _formatLabel;
  String? _contentType;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      final sanitizedUrl = _sanitizeUrl(widget.video.videoUrl);
      // Prefer cached file on mobile/desktop
      if (!kIsWeb) {
        await VideoCacheService.initialize();
        final cachedPath = await VideoCacheService.getCachedFilePath(sanitizedUrl);
        if (cachedPath != null) {
          _formatLabel = _detectFormat(sanitizedUrl, _contentType);
          _controller = VideoPlayerController.file(File(cachedPath));

          await _controller.initialize();
          await _controller.setVolume(_volume);
          await _controller.setPlaybackSpeed(_playbackSpeed);
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

          // Done: play from cache
          return;
        }
      }
      // Best-effort fetch of content-type for labeling (may fail due to CORS on web)
      try {
        await _isVideoUrlAccessible(sanitizedUrl);
      } catch (_) {}
      _formatLabel = _detectFormat(sanitizedUrl, _contentType);
      _controller = VideoPlayerController.networkUrl(Uri.parse(sanitizedUrl));

      await _controller.initialize();
      await _controller.setVolume(_volume);
      await _controller.setPlaybackSpeed(_playbackSpeed);
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

      // Best-effort background prefetch to disk cache for future plays
      if (!kIsWeb) {
        VideoCacheService.cacheVideo(sanitizedUrl).catchError((_) {});
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      // Final fallback: sample URL to keep UX working
      try {
        await _initSampleVideo();
      } catch (e3) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  String _sanitizeUrl(String url) {
    String u = url.trim();
    if (u.endsWith('?')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  Future<bool> _isVideoUrlAccessible(String url) async {
    try {
      final resp = await Dio().head(url);
      final ct = (resp.headers['content-type']?.first ?? '').toLowerCase();
      final ok = resp.statusCode == 200 && ct.startsWith('video/');
      _contentType = ct;
      debugPrint('Video HEAD status=${resp.statusCode}, content-type=$ct, ok=$ok');
      return ok;
    } catch (e) {
      debugPrint('Video HEAD failed: $e');
      return false;
    }
  }

  Future<void> _initSampleVideo() async {
    const sampleUrl =
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    _controller = VideoPlayerController.networkUrl(Uri.parse(sampleUrl));
    await _controller.initialize();
    setState(() {
      _isLoading = false;
      _hasError = false;
    });
    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        setState(() {
          _isPlaying = false;
        });
        _controller.pause();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    // Reset fullscreen/orientation on exit
    if (kIsWeb) {
      FullscreenUtil.exitFullscreen();
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
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
    if (!kIsWeb) {
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
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    if (_isFullscreen) {
      FullscreenUtil.enterFullscreen();
    } else {
      FullscreenUtil.exitFullscreen();
    }
  }

  void _seekRelative(int seconds) {
    if (!_controller.value.isInitialized) return;
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    var target = pos + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > dur) target = dur;
    _controller.seekTo(target);
  }

  void _toggleMute() async {
    if (_isMuted) {
      setState(() {
        _isMuted = false;
        _volume = _lastNonZeroVolume;
      });
      await _controller.setVolume(_volume);
    } else {
      setState(() {
        _isMuted = true;
        _lastNonZeroVolume = _volume == 0 ? 1.0 : _volume;
        _volume = 0.0;
      });
      await _controller.setVolume(0.0);
    }
  }

  Future<void> _setVolume(double v) async {
    setState(() {
      _volume = v.clamp(0.0, 1.0);
      _isMuted = _volume == 0.0;
      if (!_isMuted) _lastNonZeroVolume = _volume;
    });
    await _controller.setVolume(_volume);
  }

  Future<void> _setPlaybackSpeed(double s) async {
    setState(() {
      _playbackSpeed = s;
    });
    await _controller.setPlaybackSpeed(s);
  }

  String _detectFormat(String url, String? contentType) {
    final lower = url.toLowerCase();
    String ext = '';
    final idx = lower.lastIndexOf('.');
    if (idx != -1) {
      ext = lower.substring(idx + 1);
    }
    String label = ext.isNotEmpty ? ext.toUpperCase() : 'Unknown';
    if ((contentType ?? '').isNotEmpty) {
      label = '$label • ${contentType!}';
    }
    return label;
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

          // Controls Overlay (only when controller is ready)
          if (_showControls && !_isLoading && !_hasError)
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
  Colors.black.withValues(alpha: 0.7),
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
  color: Colors.black.withValues(alpha: 0.5),
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
  color: Colors.black.withValues(alpha: 0.5),
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
                            if (_formatLabel != null) ...[
                              SizedBox(width: 12.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  _formatLabel!,
                                  style: TextStyle(
                                    fontFamily: 'SFPro',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
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
  color: Colors.black.withValues(alpha: 0.5),
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
  Colors.black.withValues(alpha: 0.7),
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
  backgroundColor: Colors.white.withValues(alpha: 0.3),
  bufferedColor: Colors.white.withValues(alpha: 0.5),
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
  color: Colors.black.withValues(alpha: 0.5),
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
                            SizedBox(height: 12.h),
                            // Playback Controls Row
                            Row(
                              children: [
                                // Skip Back 10s
                                GestureDetector(
                                  onTap: () => _seekRelative(-10),
                                  child: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
  color: Colors.black.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.replay_10,
                                      color: Colors.white,
                                      size: 22.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                // Play/Pause
                                GestureDetector(
                                  onTap: _togglePlayPause,
                                  child: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
  color: Colors.black.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isPlaying ? Icons.pause : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 22.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                // Skip Forward 10s
                                GestureDetector(
                                  onTap: () => _seekRelative(10),
                                  child: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
  color: Colors.black.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.forward_10,
                                      color: Colors.white,
                                      size: 22.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                // Mute/Unmute
                                GestureDetector(
                                  onTap: _toggleMute,
                                  child: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
  color: Colors.black.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isMuted || _volume == 0.0 ? Icons.volume_off : Icons.volume_up,
                                      color: Colors.white,
                                      size: 22.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                // Volume Slider
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.h,
                                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                                    ),
                                    child: Slider(
                                      value: _volume,
                                      min: 0.0,
                                      max: 1.0,
                                      onChanged: (v) => _setVolume(v),
                                      activeColor: AppColors.primary,
                                      inactiveColor: Colors.white30,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                // Playback Speed
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                                  decoration: BoxDecoration(
  color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: DropdownButton<double>(
                                    value: _playbackSpeed,
                                    dropdownColor: Colors.black87,
                                    underline: SizedBox.shrink(),
                                    iconEnabledColor: Colors.white,
                                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                                    items: const [
                                      DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                                      DropdownMenuItem(value: 1.0, child: Text('1x')),
                                      DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                                      DropdownMenuItem(value: 2.0, child: Text('2x')),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) _setPlaybackSpeed(v);
                                    },
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                // Fullscreen Toggle
                                GestureDetector(
                                  onTap: _toggleFullscreen,
                                  child: Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
  color: Colors.black.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                      color: Colors.white,
                                      size: 22.sp,
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
