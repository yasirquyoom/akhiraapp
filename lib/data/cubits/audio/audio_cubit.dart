import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:audioplayers/audioplayers.dart';

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

  const AudioLoaded({
    required this.tracks,
    this.currentTrack,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
  });

  @override
  List<Object?> get props => [
    tracks,
    currentTrack,
    isPlaying,
    currentPosition,
    totalDuration,
  ];

  AudioLoaded copyWith({
    List<AudioTrack>? tracks,
    AudioTrack? currentTrack,
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
  }) {
    return AudioLoaded(
      tracks: tracks ?? this.tracks,
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
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

  AudioCubit() : super(AudioInitial()) {
    _loadAudioTracks();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      print('Duration changed: $duration');
      if (state is AudioLoaded) {
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(totalDuration: duration));
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (state is AudioLoaded) {
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(currentPosition: position));
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((playerState) {
      print('Player state changed: $playerState');
      if (state is AudioLoaded) {
        final currentState = state as AudioLoaded;
        bool isPlaying = playerState == PlayerState.playing;
        emit(currentState.copyWith(isPlaying: isPlaying));
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      print('Player completed');
      if (state is AudioLoaded) {
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(isPlaying: false));
      }
    });
  }

  void _loadAudioTracks() {
    emit(AudioLoading());

    // Dummy audio tracks with working URLs (10-20 seconds each)
    final tracks = [
      const AudioTrack(
        id: '1',
        title: 'Quran Recitation - Surah Al-Fatiha',
        duration: '0:15',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '2',
        title: 'Islamic Lecture - Faith and Practice',
        duration: '0:18',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '3',
        title: 'Quran Recitation - Surah Al-Baqarah (Part 1)',
        duration: '0:12',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '4',
        title: 'Islamic History - The Prophet\'s Life',
        duration: '0:20',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '5',
        title: 'Quran Recitation - Surah Al-Imran',
        duration: '0:16',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '6',
        title: 'Islamic Ethics - Moral Values',
        duration: '0:14',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '7',
        title: 'Quran Recitation - Surah An-Nisa',
        duration: '0:19',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '8',
        title: 'Islamic Spirituality - Inner Peace',
        duration: '0:17',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '9',
        title: 'Quran Recitation - Surah Al-Maidah',
        duration: '0:13',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '10',
        title: 'Islamic Law - Sharia Principles',
        duration: '0:21',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '11',
        title: 'Quran Recitation - Surah Al-Anam',
        duration: '0:15',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '12',
        title: 'Islamic Philosophy - Wisdom',
        duration: '0:18',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=150&h=150&fit=crop',
      ),
    ];

    emit(AudioLoaded(tracks: tracks));
  }

  void playTrack(AudioTrack track) async {
    print('Attempting to play track: ${track.title}');
    print('Audio URL: ${track.audioUrl}');

    if (state is AudioLoaded) {
      try {
        final currentState = state as AudioLoaded;

        // Stop current audio if playing
        await _audioPlayer.stop();
        print('Stopped current audio');

        // Update state
        emit(currentState.copyWith(currentTrack: track, isPlaying: true));
        print('Updated state');

        // Play the new audio
        await _audioPlayer.play(UrlSource(track.audioUrl));
        print('Started playing audio');
      } catch (e) {
        print('Error playing audio: $e');
        emit(AudioError(message: 'Failed to play audio: ${e.toString()}'));
      }
    }
  }

  void pauseTrack() async {
    if (state is AudioLoaded) {
      try {
        final currentState = state as AudioLoaded;
        emit(currentState.copyWith(isPlaying: false));
        await _audioPlayer.pause();
      } catch (e) {
        print('Error pausing audio: $e');
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
        print('Error resuming audio: $e');
      }
    }
  }

  void updatePosition(Duration position) {
    if (state is AudioLoaded) {
      final currentState = state as AudioLoaded;
      emit(currentState.copyWith(currentPosition: position));
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
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> close() {
    _audioPlayer.dispose();
    return super.close();
  }
}
