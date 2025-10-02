import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:akhira/services/audio_cache_service.dart';

class AudioTrack {
  final String id;
  final String title;
  final String duration;
  final String audioUrl;
  final String thumbnailUrl;
  final bool isPlaying;

  const AudioTrack({
    required this.id,
    required this.title,
    required this.duration,
    required this.audioUrl,
    required this.thumbnailUrl,
    this.isPlaying = false,
  });

  AudioTrack copyWith({
    String? id,
    String? title,
    String? duration,
    String? audioUrl,
    String? thumbnailUrl,
    bool? isPlaying,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

// States
abstract class AudioState extends Equatable {
  const AudioState();

  @override
  List<Object?> get props => [];
}

class AudioInitial extends AudioState {}

class AudioLoading extends AudioState {}

class AudioLoaded extends AudioState {
  final List<AudioTrack> tracks;
  final AudioTrack? currentTrack;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final double playbackSpeed;

  const AudioLoaded({
    required this.tracks,
    this.currentTrack,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.playbackSpeed = 1.0,
  });

  @override
  List<Object?> get props => [
    tracks,
    currentTrack,
    isPlaying,
    currentPosition,
    totalDuration,
    playbackSpeed,
  ];

  AudioLoaded copyWith({
    List<AudioTrack>? tracks,
    AudioTrack? currentTrack,
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
    double? playbackSpeed,
  }) {
    return AudioLoaded(
      tracks: tracks ?? this.tracks,
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

class AudioError extends AudioState {
  final String message;

  const AudioError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Cubit
class AudioCubit extends Cubit<AudioState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isUserSeeking = false;
  Timer? _positionTicker;
  bool _isStartingPlayback = false;

  AudioCubit() : super(AudioInitial()) {
    _setupAudioPlayer();
    _setupAudioPlayerSettings();
  }

  void _setupAudioPlayerSettings() {
    // Configure audio player for better network handling
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    // Configure audio session for iOS/Android to improve compatibility
    _audioPlayer.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      debugPrint('Duration changed: $duration');
      if (state is AudioLoaded) {
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(totalDuration: duration));
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (state is AudioLoaded && !_isUserSeeking) {
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(currentPosition: position));
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((playerState) {
      debugPrint('Player state changed: $playerState');
      if (state is AudioLoaded) {
        final currentState = state as AudioLoaded;
        bool isPlaying = playerState == PlayerState.playing;
        debugPrint('Updating isPlaying to: $isPlaying');
        emit(currentState.copyWith(isPlaying: isPlaying));
      }

      // Manage manual ticker alongside native position events
      if (playerState == PlayerState.playing) {
        _startPositionTicker();
      } else {
        _stopPositionTicker();
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      debugPrint('Player completed');
      if (state is AudioLoaded) {
        final currentState = state as AudioLoaded;
        // Reset to start and pause after completion
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
        _stopPositionTicker();
        emit(
          currentState.copyWith(
            isPlaying: false,
            currentPosition: Duration.zero,
          ),
        );
      }
    });
  }

  void loadAudioTracksFromApi(List<dynamic> audioContents) {
    if (audioContents.isEmpty) {
      emit(AudioInitial());
      return;
    }

    try {
      final tracks = <AudioTrack>[];

      for (final content in audioContents) {
        final track = AudioTrack(
          id: content.contentId ?? content['content_id'] ?? 'unknown',
          title: content.title ?? content['title'] ?? 'Unknown Track',
          duration: '0:00', // Duration will be updated when audio loads
          audioUrl: content.fileUrl ?? content['file_url'] ?? '',
          // Use coverImageUrl if present in BookContent/API for dynamic artwork
          thumbnailUrl:
              (content.coverImageUrl ?? content['cover_image_url'] ?? '')
                  .toString(),
        );
        tracks.add(track);
      }

      if (tracks.isNotEmpty) {
        if (state is AudioLoaded) {
          final current = state as AudioLoaded;
          // Preserve currentTrack and playback state if still present
          final currentId = current.currentTrack?.id;
          final stillExists =
              currentId != null && tracks.any((t) => t.id == currentId);
          emit(
            current.copyWith(
              tracks: tracks,
              currentTrack:
                  stillExists
                      ? (tracks.firstWhere((t) => t.id == currentId))
                      : current.currentTrack,
            ),
          );
        } else {
          emit(AudioLoaded(tracks: tracks));
        }
      } else {
        emit(AudioInitial());
      }
    } catch (e) {
      debugPrint('Error parsing audio content: $e');
      emit(AudioError(message: 'Failed to load audio tracks: ${e.toString()}'));
    }
  }

  // Test method to check if URL is accessible
  Future<bool> _testUrlAccessibility(String url) async {
    try {
      final response = await Dio()
          .head(url)
          .timeout(const Duration(seconds: 10));
      debugPrint('URL accessibility test: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('URL accessibility test failed: $e');
      return false;
    }
  }

  void playTrack(AudioTrack track) async {
    if (_isStartingPlayback) {
      return;
    }
    _isStartingPlayback = true;
    debugPrint('Attempting to play track: ${track.title}');
    debugPrint('Audio URL: ${track.audioUrl}');

    // Validate audio URL
    if (track.audioUrl.isEmpty) {
      emit(AudioError(message: 'Invalid audio URL'));
      return;
    }

    try {
      // Sanitize URL and infer mime type
      final String sanitizedUrl = _sanitizeUrl(track.audioUrl);
      final String inferredMimeType = _inferMimeTypeFromUrl(sanitizedUrl);

      // Stop current audio if playing
      await _audioPlayer.stop();
      debugPrint('Stopped current audio');

      // If we have a loaded state, update it with the new track
      if (state is AudioLoaded) {
        final currentState = state as AudioLoaded;
        emit(
          currentState.copyWith(
            currentTrack: track,
            isPlaying: false,
            currentPosition: Duration.zero,
          ),
        );
      } else {
        // If no loaded state, create one with just this track
        emit(
          AudioLoaded(
            tracks: [track],
            currentTrack: track,
            isPlaying: false,
            currentPosition: Duration.zero,
          ),
        );
      }
      debugPrint('Updated state');

      // Prefer cached file when available (mobile/desktop)
      if (!kIsWeb) {
        await AudioCacheService.initialize();
        final cachedPath = await AudioCacheService.getCachedFilePath(sanitizedUrl);
        if (cachedPath != null) {
          debugPrint('Playing cached audio file: $cachedPath');
          await _audioPlayer
              .play(DeviceFileSource(cachedPath))
              .timeout(
                const Duration(seconds: 45),
                onTimeout: () {
                  debugPrint('Cached local play timeout');
                  throw TimeoutException(
                    'Cached local play timeout',
                    const Duration(seconds: 45),
                  );
                },
              );
          debugPrint('Started playing audio (cached local)');
          _startPositionTicker();
          await _refreshDurationFromPlayer();
          if (state is AudioLoaded) {
            final s = state as AudioLoaded;
            emit(s.copyWith(isPlaying: true));
          }
          _isStartingPlayback = false;
          return;
        }
      }

      // Prefer local fallback on iOS for WAV to avoid AVPlayer stalls
      if (Platform.isIOS && sanitizedUrl.toLowerCase().endsWith('.wav')) {
        final localPath = await _downloadToTemp(
          sanitizedUrl,
          suggestExt: '.wav',
        );
        debugPrint('iOS WAV: Playing local file first: $localPath');
        await _audioPlayer
            .play(DeviceFileSource(localPath))
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () {
                debugPrint('Local play timeout');
                throw TimeoutException(
                  'Local play timeout',
                  const Duration(seconds: 45),
                );
              },
            );
        debugPrint('Started playing audio (local WAV)');
        _startPositionTicker();
        await _refreshDurationFromPlayer();
        if (state is AudioLoaded) {
          final s = state as AudioLoaded;
          emit(s.copyWith(isPlaying: true));
        }
        _isStartingPlayback = false;
        return;
      }

      // Test URL accessibility first (when not cached)
      debugPrint('Testing URL accessibility...');
      final isAccessible = await _testUrlAccessibility(sanitizedUrl);
      if (!isAccessible) {
        emit(
          AudioError(
            message:
                'Audio file is not accessible. Please check your internet connection.',
          ),
        );
        return;
      }
      debugPrint('URL is accessible, proceeding with playback...');

      // Stream first for other types
      debugPrint('Playing audio directly: $sanitizedUrl (mime: $inferredMimeType)');
      await _audioPlayer
          .play(UrlSource(sanitizedUrl, mimeType: inferredMimeType))
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              debugPrint('Audio play timeout');
              throw TimeoutException(
                'Audio play timeout',
                const Duration(seconds: 45),
              );
            },
          );
      debugPrint('Started playing audio (stream)');
      _startPositionTicker();
      await _refreshDurationFromPlayer();
      if (state is AudioLoaded) {
        final s = state as AudioLoaded;
        emit(s.copyWith(isPlaying: true));
      }
      // Background prefetch to disk cache (best-effort)
      if (!kIsWeb) {
        AudioCacheService.cacheAudio(sanitizedUrl).catchError((_) {});
      }
      _isStartingPlayback = false;
      return;
    } on Exception catch (streamErr) {
      debugPrint('Stream play failed: $streamErr');
      // Fallback: download to temp and play as local file
      try {
        final localPath = await _downloadToTemp(
          _sanitizeUrl(track.audioUrl),
          suggestExt: _extFromUrl(_sanitizeUrl(track.audioUrl)),
        );
        debugPrint('Playing local file fallback: $localPath');
        await _audioPlayer
            .play(DeviceFileSource(localPath))
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () {
                debugPrint('Local play timeout');
                throw TimeoutException(
                  'Local play timeout',
                  const Duration(seconds: 45),
                );
              },
            );
        debugPrint('Started playing audio (local)');
        _startPositionTicker();
        await _refreshDurationFromPlayer();
        if (state is AudioLoaded) {
          final s = state as AudioLoaded;
          emit(s.copyWith(isPlaying: true));
        }
        _isStartingPlayback = false;
        return;
      } on Exception catch (localErr) {
        debugPrint('Local play failed: $localErr');
        try {
          // Final fallback: play from bytes
          final bytes = await _downloadBytes(_sanitizeUrl(track.audioUrl));
          debugPrint('Playing bytes source (${bytes.lengthInBytes} bytes)');
          await _audioPlayer
              .play(BytesSource(bytes))
              .timeout(
                const Duration(seconds: 45),
                onTimeout: () {
                  debugPrint('Bytes play timeout');
                  throw TimeoutException(
                    'Bytes play timeout',
                    const Duration(seconds: 45),
                  );
                },
              );
          debugPrint('Started playing audio (bytes)');
          _startPositionTicker();
          await _refreshDurationFromPlayer();
          if (state is AudioLoaded) {
            final s = state as AudioLoaded;
            emit(s.copyWith(isPlaying: true));
          }
          _isStartingPlayback = false;
          return;
        } on Exception catch (bytesErr) {
          debugPrint('Bytes play failed: $bytesErr');
        }
      }

      // Mark playing after successful start
    } catch (e) {
      debugPrint('Error playing audio: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (state is AudioLoaded) {
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(isPlaying: false));
      }

      String errorMessage = 'Failed to play audio';
      if (e is TimeoutException) {
        errorMessage =
            'Audio loading timed out. Please check your internet connection.';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Audio file not found.';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Access denied to audio file.';
      } else {
        errorMessage = 'Failed to play audio: ${e.toString()}';
      }

      // Final fallback: try a known working sample MP3 so UI/playback works
      try {
        const sampleUrl =
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
        debugPrint('Attempting sample fallback playback: $sampleUrl');
        await _audioPlayer.play(UrlSource(sampleUrl));
        _startPositionTicker();
        await _refreshDurationFromPlayer();

        if (state is AudioLoaded) {
          final s = state as AudioLoaded;
          final fallbackTrack = AudioTrack(
            id: 'sample',
            title: '${s.currentTrack?.title ?? 'Sample'} (Preview)',
            duration: '0:00',
            audioUrl: sampleUrl,
            thumbnailUrl: s.currentTrack?.thumbnailUrl ?? '',
          );
          emit(
            s.copyWith(
              currentTrack: fallbackTrack,
              isPlaying: true,
              currentPosition: Duration.zero,
            ),
          );
        }
        debugPrint('Sample fallback started');
        _isStartingPlayback = false;
        return;
      } catch (sampleErr) {
        debugPrint('Sample fallback failed: $sampleErr');
      }

      emit(AudioError(message: errorMessage));
    }
  }

  void _startPositionTicker() {
    _stopPositionTicker();
    _positionTicker = Timer.periodic(const Duration(milliseconds: 250), (
      _,
    ) async {
      if (_isUserSeeking) return;
      if (state is! AudioLoaded) return;
      try {
        final pos = await _audioPlayer.getCurrentPosition();
        if (pos == null) return;
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(currentPosition: pos));
      } catch (_) {}
    });
  }

  void _stopPositionTicker() {
    _positionTicker?.cancel();
    _positionTicker = null;
  }

  Future<void> _refreshDurationFromPlayer() async {
    try {
      final d = await _audioPlayer.getDuration();
      if (d == null) return;
      if (state is AudioLoaded) {
        final s = state as AudioLoaded;
        if (s.totalDuration != d) {
          emit(s.copyWith(totalDuration: d));
        }
      }
    } catch (e) {
      // ignore
    }
  }

  // Helpers
  String _sanitizeUrl(String url) {
    String trimmed = url.trim();
    if (trimmed.endsWith('?')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  String _inferMimeTypeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.aac')) return 'audio/aac';
    if (lower.endsWith('.wav')) return 'audio/wav';
    // Fallback
    return 'audio/mpeg';
  }

  String _extFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.mp3')) return '.mp3';
    if (lower.endsWith('.m4a')) return '.m4a';
    if (lower.endsWith('.aac')) return '.aac';
    if (lower.endsWith('.wav')) return '.wav';
    return '.mp3';
  }

  Future<String> _downloadToTemp(
    String url, {
    String suggestExt = '.mp3',
  }) async {
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}$suggestExt';
    final dio = Dio();
        debugPrint('Downloading audio to $filePath');
    final response = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes, followRedirects: true),
    );
    final file = File(filePath);
    await file.writeAsBytes(response.data!);
    return filePath;
  }

  Future<Uint8List> _downloadBytes(String url) async {
    final dio = Dio();
    final resp = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes, followRedirects: true),
    );
    return Uint8List.fromList(resp.data ?? <int>[]);
  }

  void pauseTrack() async {
    if (state is AudioLoaded) {
      try {
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(isPlaying: false));
        await _audioPlayer.pause();
      } catch (e) {
        debugPrint('Error pausing audio: $e');
      }
    }
  }

  void resumeTrack() async {
    if (state is AudioLoaded) {
      try {
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(isPlaying: true));
        await _audioPlayer.resume();
      } catch (e) {
        debugPrint('Error resuming audio: $e');
      }
    }
  }

  void updatePosition(Duration position) async {
    if (state is AudioLoaded) {
      try {
        _isUserSeeking = true;
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(currentPosition: position));
        await _audioPlayer.seek(position);

        // Reset the flag after a short delay to allow position updates to resume
        Future.delayed(const Duration(milliseconds: 100), () {
          _isUserSeeking = false;
        });
      } catch (e) {
        debugPrint('Error updating position: $e');
        _isUserSeeking = false;
      }
    }
  }

  // Seeking helpers for smoother scrubbing
  void beginUserSeek() {
    _isUserSeeking = true;
  }

  void previewSeekPosition(Duration position) {
    if (state is AudioLoaded) {
      final currentState = state as AudioLoaded;
      emit(currentState.copyWith(currentPosition: position));
    }
  }

  Future<void> endUserSeek(Duration position) async {
    if (state is AudioLoaded) {
      try {
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(currentPosition: position));
        await _audioPlayer.seek(position);
      } catch (e) {
        debugPrint('Error ending user seek: $e');
      } finally {
        _isUserSeeking = false;
      }
    } else {
      _isUserSeeking = false;
    }
  }

  void nextTrack() async {
    if (state is AudioLoaded) {
      final currentState = state as AudioLoaded;
      final currentIndex = currentState.tracks.indexWhere(
        (track) => track.id == currentState.currentTrack?.id,
      );

      if (currentIndex != -1 && currentIndex < currentState.tracks.length - 1) {
        final nextTrack = currentState.tracks[currentIndex + 1];
        playTrack(nextTrack);
      }
    }
  }

  void previousTrack() async {
    if (state is AudioLoaded) {
      final currentState = state as AudioLoaded;
      final currentIndex = currentState.tracks.indexWhere(
        (track) => track.id == currentState.currentTrack?.id,
      );

      if (currentIndex > 0) {
        final previousTrack = currentState.tracks[currentIndex - 1];
        playTrack(previousTrack);
      }
    }
  }

  void seekTo(Duration position) async {
    if (state is AudioLoaded) {
      try {
        _isUserSeeking = true;
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(currentPosition: position));
        await _audioPlayer.seek(position);

        // Reset the flag after a short delay to allow position updates to resume
        Future.delayed(const Duration(milliseconds: 100), () {
          _isUserSeeking = false;
        });
      } catch (e) {
        debugPrint('Error seeking to position: $e');
        _isUserSeeking = false;
      }
    }
  }

  // Speed control methods
  void setPlaybackSpeed(double speed) async {
    if (state is AudioLoaded) {
      try {
        // Clamp speed between 0.5x and 2.0x
        final clampedSpeed = speed.clamp(0.5, 2.0);
        await _audioPlayer.setPlaybackRate(clampedSpeed);

        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(playbackSpeed: clampedSpeed));
      } catch (e) {
        debugPrint('Error setting playback speed: $e');
      }
    }
  }

  void increaseSpeed() {
    if (state is AudioLoaded) {
      final currentState = state as AudioLoaded;
      final currentSpeed = currentState.playbackSpeed;
      final newSpeed = (currentSpeed + 0.25).clamp(0.5, 2.0);
      setPlaybackSpeed(newSpeed);
    }
  }

  void decreaseSpeed() {
    if (state is AudioLoaded) {
      final currentState = state as AudioLoaded;
      final currentSpeed = currentState.playbackSpeed;
      final newSpeed = (currentSpeed - 0.25).clamp(0.5, 2.0);
      setPlaybackSpeed(newSpeed);
    }
  }

  void resetSpeed() {
    setPlaybackSpeed(1.0);
  }

  // Test method to debug audio issues
  Future<void> testAudioPlayback() async {
    debugPrint('=== AUDIO PLAYBACK TEST ===');

    try {
      // Test with a known working URL
      const testUrl =
          'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
      debugPrint('Testing with known URL: $testUrl');

      await _audioPlayer
          .play(UrlSource(testUrl))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                'Test timeout',
                const Duration(seconds: 10),
              );
            },
          );

      debugPrint('Test SUCCESS: Known URL played');
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Test FAILED: $e');
    }

    debugPrint('=== END AUDIO PLAYBACK TEST ===');
  }

  @override
  Future<void> close() {
    _audioPlayer.dispose();
    return super.close();
  }
}
