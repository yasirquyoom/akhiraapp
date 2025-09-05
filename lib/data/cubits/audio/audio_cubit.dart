import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

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
  AudioCubit() : super(AudioInitial()) {
    _loadAudioTracks();
  }

  void _loadAudioTracks() {
    emit(AudioLoading());

    // Dummy audio tracks with working URLs
    final tracks = [
      const AudioTrack(
        id: '1',
        title: 'Titre',
        duration: '45 min 3 sec',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '2',
        title: 'Titre',
        duration: '42 min 15 sec',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '3',
        title: 'Titre',
        duration: '38 min 22 sec',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '4',
        title: 'Titre',
        duration: '41 min 8 sec',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '5',
        title: 'Titre',
        duration: '39 min 45 sec',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '6',
        title: 'Titre',
        duration: '43 min 12 sec',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
      ),
      const AudioTrack(
        id: '7',
        title: 'Titre',
        duration: '40 min 30 sec',
        audioUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
      ),
    ];

    emit(AudioLoaded(tracks: tracks));
  }

  void playTrack(AudioTrack track) {
    if (state is AudioLoaded) {
      final currentState = state as AudioLoaded;
      final updatedTracks =
          currentState.tracks.map((t) {
            return t.id == track.id
                ? t.copyWith(isPlaying: true)
                : t.copyWith(isPlaying: false);
          }).toList();

      emit(
        currentState.copyWith(
          tracks: updatedTracks,
          currentTrack: track,
          isPlaying: true,
          totalDuration: const Duration(minutes: 45, seconds: 3),
        ),
      );
    }
  }

  void pauseTrack() {
    if (state is AudioLoaded) {
      final currentState = state as AudioLoaded;
      emit(currentState.copyWith(isPlaying: false));
    }
  }

  void resumeTrack() {
    if (state is AudioLoaded) {
      final currentState = state as AudioLoaded;
      emit(currentState.copyWith(isPlaying: true));
    }
  }

  void updatePosition(Duration position) {
    if (state is AudioLoaded) {
      final currentState = state as AudioLoaded;
      emit(currentState.copyWith(currentPosition: position));
    }
  }

  void nextTrack() {
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

  void previousTrack() {
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
}
