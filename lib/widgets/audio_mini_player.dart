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

        return Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B1538), Color(0xFF5D0E26)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  final router = getIt<AppRouter>().router;
                  final path = router.routeInformationProvider.value.uri.path;
                  if (path != AppRoutes.audioFullscreen) {
                    router.push(AppRoutes.audioFullscreen);
                  }
                },
                child: Stack(
                  children: [
                    // Background decorative pattern
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF8B1538), Color(0xFF5D0E26)],
                          ),
                        ),
                        child: CustomPaint(
                          painter: IslamicPatternPainter(),
                        ),
                      ),
                    ),
                    
                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Top section with crescent and title
                          Row(
                            children: [
                              // Crescent moon
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CustomPaint(
                                  painter: CrescentPainter(),
                                ),
                              ),
                              const Spacer(),
                              // Title
                              Text(
                                audioState.currentTrack?.title ?? 'Le titre ira ici',
                                style: const TextStyle(
                                  fontFamily: 'SFPro',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              // Share icon
                              const Icon(
                                Icons.share,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Central illustration area
                          Expanded(
                            child: Row(
                              children: [
                                // Left decorative area
                                Expanded(
                                  flex: 1,
                                  child: Container(),
                                ),
                                
                                // Central book
                                SizedBox(
                                  width: 60,
                                  height: 50,
                                  child: CustomPaint(
                                    painter: BookPainter(),
                                  ),
                                ),
                                
                                // Right side with candle
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      width: 20,
                                      height: 40,
                                      child: CustomPaint(
                                        painter: CandlePainter(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Progress bar
                          Column(
                            children: [
                              // Time display
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatTime(audioState.currentPosition),
                                    style: const TextStyle(
                                      fontFamily: 'SFPro',
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    _formatTime(audioState.totalDuration),
                                    style: const TextStyle(
                                      fontFamily: 'SFPro',
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 4),
                              
                              // Progress bar
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: audioState.totalDuration.inMilliseconds > 0
                                      ? audioState.currentPosition.inMilliseconds / audioState.totalDuration.inMilliseconds
                                      : 0.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Media controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Repeat/shuffle
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.repeat,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Previous
                              IconButton(
                                onPressed: () => context.read<AudioCubit>().previousTrack(),
                                icon: const Icon(
                                  Icons.skip_previous,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Play/Pause
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    if (audioState.isPlaying) {
                                      context.read<AudioCubit>().pauseTrack();
                                    } else {
                                      context.read<AudioCubit>().resumeTrack();
                                    }
                                  },
                                  icon: Icon(
                                    audioState.isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: const Color(0xFF8B1538),
                                    size: 24,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Next
                              IconButton(
                                onPressed: () => context.read<AudioCubit>().nextTrack(),
                                icon: const Icon(
                                  Icons.skip_next,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Menu
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.menu,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  // Removed unused _sanitizeUrl helper to satisfy analyzer warnings.

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// Custom painter for Islamic decorative pattern
class IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
  ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw subtle geometric patterns
    final path = Path();
    
    // Create a subtle geometric pattern
    for (int i = 0; i < size.width; i += 30) {
      for (int j = 0; j < size.height; j += 30) {
        path.addOval(Rect.fromCircle(
          center: Offset(i.toDouble(), j.toDouble()),
          radius: 3,
        ));
      }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for crescent moon
class CrescentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700) // Gold color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Create crescent shape
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;
    
    // Outer circle
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    
    // Inner circle to create crescent
    final innerCenter = Offset(center.dx + radius * 0.3, center.dy);
    path.addOval(Rect.fromCircle(center: innerCenter, radius: radius * 0.8));
    
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for open book
class BookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bookPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    final shadowPaint = Paint()
  ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
      
    final linePaint = Paint()
  ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Book shadow
    final shadowPath = Path();
    shadowPath.moveTo(size.width * 0.1 + 2, size.height * 0.3 + 2);
    shadowPath.lineTo(size.width * 0.9 + 2, size.height * 0.3 + 2);
    shadowPath.lineTo(size.width * 0.9 + 2, size.height * 0.9 + 2);
    shadowPath.lineTo(size.width * 0.5 + 2, size.height * 0.8 + 2);
    shadowPath.lineTo(size.width * 0.1 + 2, size.height * 0.9 + 2);
    shadowPath.close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Book pages
    final bookPath = Path();
    bookPath.moveTo(size.width * 0.1, size.height * 0.3);
    bookPath.lineTo(size.width * 0.9, size.height * 0.3);
    bookPath.lineTo(size.width * 0.9, size.height * 0.9);
    bookPath.lineTo(size.width * 0.5, size.height * 0.8);
    bookPath.lineTo(size.width * 0.1, size.height * 0.9);
    bookPath.close();
    canvas.drawPath(bookPath, bookPaint);

    // Book spine
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.8),
      linePaint,
    );

    // Text lines on pages
    for (int i = 0; i < 4; i++) {
      final y = size.height * 0.4 + (i * size.height * 0.08);
      // Left page lines
      canvas.drawLine(
        Offset(size.width * 0.15, y),
        Offset(size.width * 0.45, y),
        linePaint,
      );
      // Right page lines
      canvas.drawLine(
        Offset(size.width * 0.55, y),
        Offset(size.width * 0.85, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for candle
class CandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final candlePaint = Paint()
      ..color = const Color(0xFFF5E6D3) // Cream color
      ..style = PaintingStyle.fill;
      
    final flamePaint = Paint()
      ..color = const Color(0xFFFF6B35) // Orange flame
      ..style = PaintingStyle.fill;
      
    final wickPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Candle body
    final candleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.3,
        size.height * 0.3,
        size.width * 0.4,
        size.height * 0.6,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(candleRect, candlePaint);

    // Wick
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.2),
      wickPaint,
    );

    // Flame
    final flamePath = Path();
    flamePath.moveTo(size.width * 0.5, size.height * 0.2);
    flamePath.quadraticBezierTo(
      size.width * 0.6, size.height * 0.15,
      size.width * 0.5, size.height * 0.1,
    );
    flamePath.quadraticBezierTo(
      size.width * 0.4, size.height * 0.15,
      size.width * 0.5, size.height * 0.2,
    );
    canvas.drawPath(flamePath, flamePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
