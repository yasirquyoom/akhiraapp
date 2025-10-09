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
  final Map<String, Map<String, BookContentData>> _cachedContentByType = {};
  BookContentData? _allContentData;
  String? _currentBookId;
  bool _isInitialLoad = true;

  BookContentCubit(this._repository) : super(BookContentInitial());

  Future<void> loadAllBookContent({required String bookId}) async {
    if (isClosed) return;

    // If we already have all content for this book, don't reload
    if (_allContentData != null && _currentBookId == bookId) {
      emit(BookContentLoaded(data: _allContentData!));
      return;
    }

    // Only emit loading state on initial load to prevent flickering
    if (_isInitialLoad) {
      emit(BookContentLoading());
      _isInitialLoad = false;
    }

    try {
      // Load all content without content_type filter
      final response = await _repository.getBookContent(
        bookId: bookId,
        contentType: null, // No filter - get all content
      );

      if (isClosed) return;

      if (response.status == 200 && response.data != null) {
        _allContentData = response.data!;
        _currentBookId = bookId;
        _cachedContent[bookId] = response.data!;
        
        // Cache content by type for faster access
        _cacheContentByType(bookId, response.data!);
        
        emit(BookContentLoaded(data: response.data!));
      } else {
        emit(BookContentError(message: response.message));
      }
    } catch (e) {
      if (isClosed) return;
      emit(BookContentError(message: e.toString()));
    }
  }

  // Cache content by type for faster tab switching
  void _cacheContentByType(String bookId, BookContentData allData) {
    if (!_cachedContentByType.containsKey(bookId)) {
      _cachedContentByType[bookId] = {};
    }
    
    // Group content by type
    final contentTypes = ['ebook', 'audio', 'quiz', 'video', 'image'];
    for (final type in contentTypes) {
      _cachedContentByType[bookId]![type] = _filterContentByType(allData, type);
    }
  }

  Future<void> loadContentByType({
    required String bookId,
    required String contentType,
  }) async {
    if (isClosed) return;

    // Check if we have this specific content type cached
    if (_cachedContentByType.containsKey(bookId) && 
        _cachedContentByType[bookId]!.containsKey(contentType)) {
      // Use cached content immediately without loading state
      emit(BookContentLoaded(data: _cachedContentByType[bookId]![contentType]!));
      return;
    }
    
    // If we have all content cached, filter it immediately without loading state
    if (_allContentData != null && _currentBookId == bookId) {
      final filteredData = _filterContentByType(_allContentData!, contentType);
      
      // Cache the filtered data
      if (!_cachedContentByType.containsKey(bookId)) {
        _cachedContentByType[bookId] = {};
      }
      _cachedContentByType[bookId]![contentType] = filteredData;
      
      emit(BookContentLoaded(data: filteredData));
      return;
    }

    // If we don't have all content, load it first
    await loadAllBookContent(bookId: bookId);
  }

  Future<void> refreshContentByType({
    required String bookId,
    required String contentType,
  }) async {
    if (isClosed) return;

    emit(BookContentLoading());

    try {
      // Load specific content type for refresh
      final response = await _repository.getBookContent(
        bookId: bookId,
        contentType: contentType,
      );

      if (isClosed) return;

      if (response.status == 200 && response.data != null) {
        // Update the cached all content with the refreshed data
        if (_allContentData != null && _currentBookId == bookId) {
          _updateContentInCache(_allContentData!, response.data!, contentType);
        }

        emit(BookContentLoaded(data: response.data!));
      } else {
        emit(BookContentError(message: response.message));
      }
    } catch (e) {
      if (isClosed) return;
      emit(BookContentError(message: e.toString()));
    }
  }

  BookContentData _filterContentByType(
    BookContentData allData,
    String contentType,
  ) {
    final filteredContents =
        allData.contents
            ?.where((content) => content.contentType == contentType)
            .toList();

    return BookContentData(
      bookDetails: allData.bookDetails,
      contentType: contentType,
      contents: filteredContents,
      total: filteredContents?.length ?? 0,
      skip: allData.skip,
      limit: allData.limit,
    );
  }

  void _updateContentInCache(
    BookContentData allData,
    BookContentData refreshedData,
    String contentType,
  ) {
    if (allData.contents != null && refreshedData.contents != null) {
      // Remove old content of this type
      allData.contents!.removeWhere(
        (content) => content.contentType == contentType,
      );
      // Add refreshed content
      allData.contents!.addAll(refreshedData.contents!);
    }
  }

  // Method to clear cache if needed
  void clearCache() {
    _cachedContent.clear();
    _allContentData = null;
    _currentBookId = null;
  }
}
