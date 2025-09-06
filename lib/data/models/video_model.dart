import 'package:equatable/equatable.dart';

class VideoModel extends Equatable {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final String duration;
  final String description;

  const VideoModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.duration,
    required this.description,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    thumbnailUrl,
    videoUrl,
    duration,
    description,
  ];
}
