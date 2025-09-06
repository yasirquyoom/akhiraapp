import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/image_download_service.dart';
import '../../../core/di/service_locator.dart';

class ImageModel extends Equatable {
  final String id;
  final String title;
  final String imageUrl;
  final String? description;

  const ImageModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.description,
  });

  @override
  List<Object?> get props => [id, title, imageUrl, description];
}

abstract class ImagesState extends Equatable {
  const ImagesState();

  @override
  List<Object?> get props => [];
}

class ImagesInitial extends ImagesState {}

class ImagesLoaded extends ImagesState {
  final List<ImageModel> images;
  final int currentIndex;
  final bool isDownloading;

  const ImagesLoaded({
    required this.images,
    this.currentIndex = 0,
    this.isDownloading = false,
  });

  ImagesLoaded copyWith({
    List<ImageModel>? images,
    int? currentIndex,
    bool? isDownloading,
  }) {
    return ImagesLoaded(
      images: images ?? this.images,
      currentIndex: currentIndex ?? this.currentIndex,
      isDownloading: isDownloading ?? this.isDownloading,
    );
  }

  @override
  List<Object?> get props => [images, currentIndex, isDownloading];
}

class ImagesCubit extends Cubit<ImagesState> {
  ImagesCubit() : super(ImagesInitial()) {
    _loadImages();
  }

  void _loadImages() {
    // Dummy images for demonstration
    final images = [
      const ImageModel(
        id: '1',
        title: 'Le titre de l\'image ira ici',
        imageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcREKWN8bJT4u9JQunIM9X0V7ecwkUMiI0uXUg&usqp=CAU',
        description: 'Beautiful mosque architecture',
      ),
      const ImageModel(
        id: '2',
        title: 'Architecture Details',
        imageUrl:
            'https://c8.alamy.com/comp/E9E9TK/quran-the-holy-book-of-islam-E9E9TK.jpg',
        description: 'Intricate architectural patterns',
      ),
      const ImageModel(
        id: '3',
        title: 'Historical Monument',
        imageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSbOWfIYTEzWQ4i2ryypJlyIQQ2G_GPTpr0pQ&usqp=CAU',
        description: 'Ancient historical structure',
      ),
      const ImageModel(
        id: '4',
        title: 'Cultural Heritage',
        imageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQSrbYNa8ittD3pTgeBc3UZ525hGa0KRKfBYw&usqp=CAU',
        description: 'Traditional cultural elements',
      ),
      const ImageModel(
        id: '5',
        title: 'Modern Architecture',
        imageUrl:
            '	https://c1.wallpaperflare.com/preview/122/762/486/kaaba-house-of-allah-muslim-islamic.jpg',
        description: 'Contemporary design elements',
      ),
    ];

    emit(ImagesLoaded(images: images));
  }

  void nextImage() {
    if (state is ImagesLoaded) {
      final currentState = state as ImagesLoaded;
      final nextIndex =
          (currentState.currentIndex + 1) % currentState.images.length;
      emit(currentState.copyWith(currentIndex: nextIndex));
    }
  }

  void previousImage() {
    if (state is ImagesLoaded) {
      final currentState = state as ImagesLoaded;
      final prevIndex =
          currentState.currentIndex == 0
              ? currentState.images.length - 1
              : currentState.currentIndex - 1;
      emit(currentState.copyWith(currentIndex: prevIndex));
    }
  }

  void goToImage(int index) {
    if (state is ImagesLoaded) {
      final currentState = state as ImagesLoaded;
      if (index >= 0 && index < currentState.images.length) {
        emit(currentState.copyWith(currentIndex: index));
      }
    }
  }

  Future<void> downloadImage(String imageUrl) async {
    if (state is ImagesLoaded) {
      final currentState = state as ImagesLoaded;
      emit(currentState.copyWith(isDownloading: true));

      try {
        final downloadService = getIt<ImageDownloadService>();
        await downloadService.downloadImage(imageUrl);

        emit(currentState.copyWith(isDownloading: false));
      } catch (e) {
        emit(currentState.copyWith(isDownloading: false));
        rethrow;
      }
    }
  }
}
