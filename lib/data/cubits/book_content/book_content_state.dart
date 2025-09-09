import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/book_content_response.dart';
import '../../repositories/book_content_repository.dart';

// States
abstract class BookContentState extends Equatable {
  const BookContentState();

  @override
  List<Object?> get props => [];
}

class BookContentInitial extends BookContentState {}

class BookContentLoading extends BookContentState {}

class BookContentLoaded extends BookContentState {
  final BookContentData data;

  const BookContentLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class BookContentError extends BookContentState {
  final String message;

  const BookContentError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Cubit
class BookContentCubit extends Cubit<BookContentState> {
  final BookContentRepository _repository;
  final Map<String, BookContentData> _cachedContent = {};

  BookContentCubit(this._repository) : super(BookContentInitial());

  Future<void> loadBookContent({
    required String bookId,
    String? contentType,
  }) async {
    if (isClosed) return;

    // Create cache key
    final cacheKey = '${bookId}_${contentType ?? 'all'}';

    // Check if we already have this content cached
    if (_cachedContent.containsKey(cacheKey)) {
      emit(BookContentLoaded(data: _cachedContent[cacheKey]!));
      return;
    }

    emit(BookContentLoading());

    try {
      final response = await _repository.getBookContent(
        bookId: bookId,
        contentType: contentType,
      );

      if (isClosed) return;

      if (response.status == 200 && response.data != null) {
        // Cache the content
        _cachedContent[cacheKey] = response.data!;
        emit(BookContentLoaded(data: response.data!));
      } else {
        emit(BookContentError(message: response.message));
      }
    } catch (e) {
      if (isClosed) return;
      emit(BookContentError(message: e.toString()));
    }
  }

  Future<void> loadContentByType({
    required String bookId,
    required String contentType,
  }) async {
    await loadBookContent(bookId: bookId, contentType: contentType);
  }

  // Method to clear cache if needed
  void clearCache() {
    _cachedContent.clear();
  }
}
