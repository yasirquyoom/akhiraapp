import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/video_model.dart';

abstract class VideosState extends Equatable {
  const VideosState();

  @override
  List<Object?> get props => [];
}

class VideosInitial extends VideosState {}

class VideosLoaded extends VideosState {
  final List<VideoModel> videos;
  final VideoModel? currentVideo;

  const VideosLoaded({required this.videos, this.currentVideo});

  VideosLoaded copyWith({List<VideoModel>? videos, VideoModel? currentVideo}) {
    return VideosLoaded(
      videos: videos ?? this.videos,
      currentVideo: currentVideo ?? this.currentVideo,
    );
  }

  @override
  List<Object?> get props => [videos, currentVideo];
}

class VideosCubit extends Cubit<VideosState> {
  VideosCubit() : super(VideosInitial()) {
    _loadVideos();
  }

  void _loadVideos() {
    // Dummy video data with working video URLs
    final videos = [
      const VideoModel(
        id: '1',
        title: 'Introduction to Islamic Studies',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400&h=225&fit=crop',
        videoUrl:
            'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        duration: '02:30',
        description:
            'Learn the basics of Islamic studies and their importance.',
      ),
      const VideoModel(
        id: '2',
        title: 'Quran Recitation Techniques',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=225&fit=crop',
        videoUrl:
            'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
        duration: '03:45',
        description: 'Master the art of beautiful Quran recitation.',
      ),
      const VideoModel(
        id: '3',
        title: 'Islamic History and Civilization',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400&h=225&fit=crop',
        videoUrl:
            'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_5mb.mp4',
        duration: '04:15',
        description: 'Explore the rich history of Islamic civilization.',
      ),
      const VideoModel(
        id: '4',
        title: 'Prayer and Worship',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=225&fit=crop',
        videoUrl:
            'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_10mb.mp4',
        duration: '02:50',
        description: 'Understanding the importance of prayer in Islam.',
      ),
      const VideoModel(
        id: '5',
        title: 'Islamic Ethics and Morality',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=400&h=225&fit=crop',
        videoUrl:
            'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_20mb.mp4',
        duration: '03:20',
        description: 'Learn about Islamic principles of ethics and morality.',
      ),
    ];

    emit(VideosLoaded(videos: videos));
  }

  void selectVideo(VideoModel video) {
    if (state is VideosLoaded) {
      final currentState = state as VideosLoaded;
      emit(currentState.copyWith(currentVideo: video));
    }
  }

  void clearCurrentVideo() {
    if (state is VideosLoaded) {
      final currentState = state as VideosLoaded;
      emit(currentState.copyWith(currentVideo: null));
    }
  }
}
