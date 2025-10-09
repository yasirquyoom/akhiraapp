import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/book_model.dart';
import '../../models/redeem_request.dart';
import '../../repositories/collection_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final CollectionRepository _collectionRepository;
  bool _hasLoaded = false;
  List<BookModel> _cachedBooks = [];
  static const String _cacheKey = 'cached_library_books';
  
  HomeCubit(this._collectionRepository) : super(HomeInitial()) {
    _loadCachedBooks();
  }
  
  // Load cached books from SharedPreferences
  Future<void> _loadCachedBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      
      if (cachedData != null && cachedData.isNotEmpty) {
        final List<dynamic> decodedData = jsonDecode(cachedData);
        _cachedBooks = decodedData
            .map((item) => BookModel.fromJson(item))
            .toList();
            
        // Emit cached data immediately to improve perceived performance
        if (_cachedBooks.isNotEmpty) {
          emit(HomeLoaded(books: _cachedBooks, isFromCache: true));
        }
      }
      
      // Always load fresh data after showing cached data
      loadCollections();
    } catch (e) {
      debugPrint('Error loading cached books: $e');
      // If cache loading fails, proceed with normal loading
      loadCollections();
    }
  }
  
  // Save books to cache
  Future<void> _saveToCache(List<BookModel> books) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedData = jsonEncode(books.map((book) => book.toJson()).toList());
      await prefs.setString(_cacheKey, encodedData);
      _cachedBooks = books;
    } catch (e) {
      debugPrint('Error saving books to cache: $e');
    }
  }

  Future<void> loadCollections({bool forceRefresh = false}) async {
    if (_hasLoaded && state is! HomeError && !forceRefresh) {
      return; // Don't reload if already loaded successfully
    }

    if (isClosed) return; // Don't emit if cubit is closed
    
    // Only show loading state if we don't have cached data
    if (_cachedBooks.isEmpty || state is! HomeLoaded) {
      emit(HomeLoading());
    }

    try {
      final response = await _collectionRepository.getCollections();

      if (isClosed) return; // Check again after async operation

      if (response.status == 200 && response.data?.collections != null) {
        final collections = response.data!.collections!;

        if (collections.isEmpty) {
          emit(HomeEmpty());
        } else {
          // Convert BookCollection to BookModel
          final books =
              collections
                  .map(
                    (collection) => BookModel(
                      id: collection.bookId,
                      title: collection.bookName,
                      author: collection.authorName,
                      coverImageUrl: collection.coverImageUrl,
                      editionName: collection.editionName,
                      totalPages: collection.totalPages,
                      addedAt: collection.addedAt,
                    ),
                  )
                  .toList();
          
          // Save to cache for future use
          _saveToCache(books);
          
          emit(HomeLoaded(books: books, isFromCache: false));
        }
        _hasLoaded = true;
      } else {
        // If API call fails but we have cached data, keep showing it
        if (_cachedBooks.isNotEmpty && state is! HomeLoaded) {
          emit(HomeLoaded(books: _cachedBooks, isFromCache: true));
        } else {
          emit(HomeError(message: response.message));
        }
      }
    } catch (e) {
      if (isClosed) return; // Check again after async operation
      
      // If network error but we have cached data, keep showing it
      if (_cachedBooks.isNotEmpty && state is! HomeLoaded) {
        emit(HomeLoaded(books: _cachedBooks, isFromCache: true));
      } else {
        emit(HomeError(message: e.toString()));
      }
    }
  }

  Future<void> redeemBook(String bookCode) async {
    if (isClosed) return; // Don't emit if cubit is closed

    emit(HomeRedeeming());

    try {
      final response = await _collectionRepository.redeemBook(
        RedeemRequest(code: bookCode),
      );

      if (isClosed) return; // Check again after async operation

      if (response.status == 200) {
        emit(HomeRedeemSuccess(message: response.message));
        // Reload collections after successful redemption
        _hasLoaded = false; // Reset flag to allow reload
        await loadCollections();
      } else {
        emit(HomeRedeemError(message: response.message));
      }
    } catch (e) {
      if (isClosed) return; // Check again after async operation
      emit(HomeRedeemError(message: e.toString()));
    }
  }
}
