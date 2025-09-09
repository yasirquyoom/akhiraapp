import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/book_model.dart';
import '../../models/redeem_request.dart';
import '../../repositories/collection_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final CollectionRepository _collectionRepository;
  bool _hasLoaded = false;

  HomeCubit(this._collectionRepository) : super(HomeInitial()) {
    loadCollections();
  }

  Future<void> loadCollections() async {
    if (_hasLoaded && state is! HomeError) {
      return; // Don't reload if already loaded successfully
    }

    if (isClosed) return; // Don't emit if cubit is closed

    emit(HomeLoading());

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

          emit(HomeLoaded(books: books));
        }
        _hasLoaded = true;
      } else {
        emit(HomeError(message: response.message));
      }
    } catch (e) {
      if (isClosed) return; // Check again after async operation
      emit(HomeError(message: e.toString()));
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
