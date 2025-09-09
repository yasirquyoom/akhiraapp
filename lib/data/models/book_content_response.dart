import 'package:equatable/equatable.dart';
import 'book_content.dart';

class BookContentResponse extends Equatable {
  final int status;
  final String message;
  final BookContentData? data;

  const BookContentResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory BookContentResponse.fromJson(Map<String, dynamic> json) {
    return BookContentResponse(
      status: json['status'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      data:
          json['data'] != null ? BookContentData.fromJson(json['data']) : null,
    );
  }

  @override
  List<Object?> get props => [status, message, data];
}

class BookContentData extends Equatable {
  final BookDetails? bookDetails;
  final String? contentType;
  final List<BookContent>? contents;
  final int? total;
  final int? skip;
  final int? limit;

  const BookContentData({
    this.bookDetails,
    this.contentType,
    this.contents,
    this.total,
    this.skip,
    this.limit,
  });

  factory BookContentData.fromJson(Map<String, dynamic> json) {
    return BookContentData(
      bookDetails:
          json['book_details'] != null
              ? BookDetails.fromJson(json['book_details'])
              : null,
      contentType: json['content_type'] as String?,
      contents:
          json['contents'] != null
              ? (json['contents'] as List)
                  .map((item) => BookContent.fromJson(item))
                  .toList()
              : null,
      total: json['total'] as int?,
      skip: json['skip'] as int?,
      limit: json['limit'] as int?,
    );
  }

  @override
  List<Object?> get props => [
    bookDetails,
    contentType,
    contents,
    total,
    skip,
    limit,
  ];
}

class BookDetails extends Equatable {
  final String bookId;
  final String bookName;
  final String authorName;
  final String editionName;
  final int totalPages;
  final String coverImageUrl;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const BookDetails({
    required this.bookId,
    required this.bookName,
    required this.authorName,
    required this.editionName,
    required this.totalPages,
    required this.coverImageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookDetails.fromJson(Map<String, dynamic> json) {
    return BookDetails(
      bookId: json['book_id'] as String,
      bookName: json['book_name'] as String,
      authorName: json['author_name'] as String,
      editionName: json['edition_name'] as String,
      totalPages: json['total_pages'] as int,
      coverImageUrl: json['cover_image_url'] as String,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'book_name': bookName,
      'author_name': authorName,
      'edition_name': editionName,
      'total_pages': totalPages,
      'cover_image_url': coverImageUrl,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
    bookId,
    bookName,
    authorName,
    editionName,
    totalPages,
    coverImageUrl,
    isActive,
    createdAt,
    updatedAt,
  ];
}
