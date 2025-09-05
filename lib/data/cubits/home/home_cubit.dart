import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/book_model.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial()) {
    _loadInitialData();
  }

  void _loadInitialData() {
    // For now, start with empty state
    emit(HomeEmpty());
  }

  void addBook(String bookCode) {
    // Simulate adding a book
    if (state is HomeEmpty) {
      // Add dummy books when transitioning from empty to loaded
      final dummyBooks = _getDummyBooks();
      emit(HomeLoaded(books: dummyBooks));
    } else if (state is HomeLoaded) {
      // Add a new book to existing list
      final currentBooks = (state as HomeLoaded).books;
      final newBook = _createDummyBook(bookCode);
      emit(HomeLoaded(books: [...currentBooks, newBook]));
    }
  }

  List<BookModel> _getDummyBooks() {
    return [
      const BookModel(
        id: '1',
        title: 'RELEASE',
        author: 'PATRICK NESS',
        coverImageUrl:
            'https://m.media-amazon.com/images/I/811t1pfIZXL._UF1000,1000_QL80_.jpg',
      ),
      const BookModel(
        id: '2',
        title: 'NO TIME TO DIE',
        author: 'JAMES BOND IS BACK!',
        coverImageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTihtvx5SIdixK75-zUTOkjlvJLVgrkn6DuOQ&usqp=CAU',
      ),
      const BookModel(
        id: '3',
        title: "I'll Be There",
        author: 'a novel by HOLLY GOLDBERG SLOAN',
        coverImageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQWSerKjBiU0iJuMFtv636HTFrVU_StkKMUfw&usqp=CAU',
      ),
      const BookModel(
        id: '4',
        title: "I'll Be There",
        author: 'a novel by HOLLY GOLDBERG SLOAN',
        coverImageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRSGQaa7FEfuxap2EkbrBtmY7WeCs1-FAVWmA&usqp=CAU',
      ),
      const BookModel(
        id: '5',
        title: "I'll Be There",
        author: 'a novel by HOLLY GOLDBERG SLOAN',
        coverImageUrl:
            'https://w0.peakpx.com/wallpaper/311/864/HD-wallpaper-harry-potter-books-harry-potter-thumbnail.jpg',
      ),
      const BookModel(
        id: '6',
        title: "I'll Be There",
        author: 'a novel by HOLLY GOLDBERG SLOAN',
        coverImageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRwyA53AnVGqwFd9K9r6FU6ZdJBftwyoeiLYA&usqp=CAU',
      ),
    ];
  }

  BookModel _createDummyBook(String bookCode) {
    final imageUrls = [
      'https://m.media-amazon.com/images/I/811t1pfIZXL._UF1000,1000_QL80_.jpg',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTihtvx5SIdixK75-zUTOkjlvJLVgrkn6DuOQ&usqp=CAU',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQWSerKjBiU0iJuMFtv636HTFrVU_StkKMUfw&usqp=CAU',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRSGQaa7FEfuxap2EkbrBtmY7WeCs1-FAVWmA&usqp=CAU',
      'https://w0.peakpx.com/wallpaper/311/864/HD-wallpaper-harry-potter-books-harry-potter-thumbnail.jpg',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRwyA53AnVGqwFd9K9r6FU6ZdJBftwyoeiLYA&usqp=CAU',
    ];

    return BookModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Book $bookCode',
      author: 'Author Name',
      coverImageUrl:
          imageUrls[DateTime.now().millisecondsSinceEpoch % imageUrls.length],
    );
  }
}
