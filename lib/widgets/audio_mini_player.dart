import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/cubits/audio/audio_cubit.dart';
import '../router/app_router.dart';
import '../core/di/service_locator.dart';

class AudioMiniPlayer extends StatelessWidget {
  const AudioMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    // Hide mini player on the dedicated audio fullscreen page
    final appRouter = getIt<AppRouter>().router;
    final currentPath = appRouter.routeInformationProvider.value.uri.path;
    if (currentPath == AppRoutes.audioFullscreen) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<AudioCubit, AudioState>(
      builder: (context, state) {
        if (state is! AudioLoaded || state.currentTrack == null) {
          return const SizedBox.shrink();
        }

        final audioState = state;

        return SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: Container(
            margin: const EdgeInsets.all(12),
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E4FB6), Color(0xFF142350)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final router = getIt<AppRouter>().router;
                  final path = router.routeInformationProvider.value.uri.path;
                  if (path != AppRoutes.audioFullscreen) {
                    router.push(AppRoutes.audioFullscreen);
                  }
                },
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            (audioState.currentTrack?.thumbnailUrl.isNotEmpty ==
                                    true)
                                ? Image.network(
                                  _sanitizeUrl(
                                    audioState.currentTrack!.thumbnailUrl,
                                  ),
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Container(
                                        color: Colors.white.withOpacity(0.2),
                                        child: const Icon(
                                          Icons.audiotrack,
                                          color: Colors.white,
                                        ),
                                      ),
                                )
                                : Container(
                                  color: Colors.white.withOpacity(0.2),
                                  child: const Icon(
                                    Icons.audiotrack,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),

                    // Title & duration
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            audioState.currentTrack?.title ?? 'Title',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatTime(audioState.currentPosition)} / ${_formatTime(audioState.totalDuration)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Controls
                    Row(
                      children: [
                        IconButton(
                          onPressed:
                              () => context.read<AudioCubit>().previousTrack(),
                          icon: const Icon(
                            Icons.skip_previous,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (audioState.isPlaying) {
                              context.read<AudioCubit>().pauseTrack();
                            } else {
                              context.read<AudioCubit>().resumeTrack();
                            }
                          },
                          icon: Icon(
                            audioState.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        IconButton(
                          onPressed:
                              () => context.read<AudioCubit>().nextTrack(),
                          icon: const Icon(
                            Icons.skip_next,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _sanitizeUrl(String url) {
    var u = url.trim();
    if (u.endsWith('?')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
