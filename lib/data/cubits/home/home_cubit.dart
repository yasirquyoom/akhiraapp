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
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTjfCdT5dSfzKqLa3ROQuu257BFTCRP0-aqRw&s',
      ),
      const BookModel(
        id: '2',
        title: 'NO TIME TO DIE',
        author: 'JAMES BOND IS BACK!',
        coverImageUrl:
            'https://w0.peakpx.com/wallpaper/423/86/HD-wallpaper-muslim-dp-book-islamic-thumbnail.jpg',
      ),
      const BookModel(
        id: '3',
        title: "I'll Be There",
        author: 'a novel by HOLLY GOLDBERG SLOAN',
        coverImageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSHOuwg39tHgMIVLHWZjgHHIo-VtIUY21iLLA&s',
      ),
      const BookModel(
        id: '4',
        title: "I'll Be There",
        author: 'a novel by HOLLY GOLDBERG SLOAN',
        coverImageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS1xNYdMWh8_E9s9k2nednrfkTpsRVuQ1II3w&usqp=CAU',
      ),
      const BookModel(
        id: '5',
        title: "I'll Be There",
        author: 'a novel by HOLLY GOLDBERG SLOAN',
        coverImageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTrQYkpUFa7UFT0ANTF52y5PPz1BimvVfBtLQ&usqp=CAU',
      ),
      const BookModel(
        id: '6',
        title: "I'll Be There",
        author: 'a novel by HOLLY GOLDBERG SLOAN',
        coverImageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQukAB0NYyPpjDLvtuxEF6mzjPHSAoo1vH1zw&usqp=CAU',
      ),
    ];
  }

  BookModel _createDummyBook(String bookCode) {
    final imageUrls = [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTrQYkpUFa7UFT0ANTF52y5PPz1BimvVfBtLQ&usqp=CAU',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTihtvx5SIdixK75-zUTOkjlvJLVgrkn6DuOQ&usqp=CAU',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSHOuwg39tHgMIVLHWZjgHHIo-VtIUY21iLLA&s',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRSGQaa7FEfuxap2EkbrBtmY7WeCs1-FAVWmA&usqp=CAU',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTrQYkpUFa7UFT0ANTF52y5PPz1BimvVfBtLQ&usqp=CAU',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSHOuwg39tHgMIVLHWZjgHHIo-VtIUY21iLLA&s',
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
