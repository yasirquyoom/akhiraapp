import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class BookCollection extends Equatable {
  final String collectionId;
  final String bookId;
  final String bookName;
  final String authorName;
  final String editionName;
  final String coverImageUrl;
  final int totalPages;
  final String addedAt;

  const BookCollection({
    required this.collectionId,
    required this.bookId,
    required this.bookName,
    required this.authorName,
    required this.editionName,
    required this.coverImageUrl,
    required this.totalPages,
    required this.addedAt,
  });

  factory BookCollection.fromJson(Map<String, dynamic> json) {
    debugPrint('BookCollection JSON: $json');
    return BookCollection(
      collectionId: json['collection_id'] as String? ?? '',
      bookId: json['book_id'] as String? ?? '',
      bookName: json['book_name'] as String? ?? '',
      authorName: json['author_name'] as String? ?? '',
      editionName: json['edition_name'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String? ?? '',
      totalPages: json['total_pages'] as int? ?? 0,
      addedAt: json['added_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collection_id': collectionId,
      'book_id': bookId,
      'book_name': bookName,
      'author_name': authorName,
      'edition_name': editionName,
      'cover_image_url': coverImageUrl,
      'total_pages': totalPages,
      'added_at': addedAt,
    };
  }

  @override
  List<Object?> get props => [
    collectionId,
    bookId,
    bookName,
    authorName,
    editionName,
    coverImageUrl,
    totalPages,
    addedAt,
  ];
}
