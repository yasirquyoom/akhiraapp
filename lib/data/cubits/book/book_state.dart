import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// States
abstract class BookState extends Equatable {
  const BookState();

  @override
  List<Object?> get props => [];
}

class BookInitial extends BookState {}

class BookLoaded extends BookState {
  final String bookId;
  final String? bookTitle;

  const BookLoaded({required this.bookId, this.bookTitle});

  @override
  List<Object?> get props => [bookId, bookTitle];

  BookLoaded copyWith({String? bookId, String? bookTitle}) {
    return BookLoaded(
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
    );
  }
}

// Cubit
class BookCubit extends Cubit<BookState> {
  BookCubit() : super(BookInitial());

  void setBook({required String bookId, String? bookTitle}) {
    emit(BookLoaded(bookId: bookId, bookTitle: bookTitle));
  }

  void clearBook() {
    emit(BookInitial());
  }

  // Helper method to get current book ID
  String? getCurrentBookId() {
    if (state is BookLoaded) {
      return (state as BookLoaded).bookId;
    }
    return null;
  }

  // Helper method to get current book title
  String? getCurrentBookTitle() {
    if (state is BookLoaded) {
      return (state as BookLoaded).bookTitle;
    }
    return null;
  }

  // Helper method to check if book is loaded
  bool get isBookLoaded => state is BookLoaded;
}
