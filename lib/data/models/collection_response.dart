import 'package:equatable/equatable.dart';
import 'book_collection.dart';

class CollectionResponse extends Equatable {
  final int status;
  final String message;
  final CollectionData? data;

  const CollectionResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory CollectionResponse.fromJson(Map<String, dynamic> json) {
    return CollectionResponse(
      status: json['status'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? CollectionData.fromJson(json['data']) : null,
    );
  }

  @override
  List<Object?> get props => [status, message, data];
}

class CollectionData extends Equatable {
  final List<BookCollection>? collections;
  final int? total;
  final int? skip;
  final int? limit;
  final String? collectionId;
  final String? bookId;
  final String? bookName;
  final String? authorName;
  final String? editionName;
  final String? coverImageUrl;
  final int? totalPages;
  final String? addedAt;
  final String? codeUsed;

  const CollectionData({
    this.collections,
    this.total,
    this.skip,
    this.limit,
    this.collectionId,
    this.bookId,
    this.bookName,
    this.authorName,
    this.editionName,
    this.coverImageUrl,
    this.totalPages,
    this.addedAt,
    this.codeUsed,
  });

  factory CollectionData.fromJson(Map<String, dynamic> json) {
    return CollectionData(
      collections:
          json['collections'] != null
              ? (json['collections'] as List)
                  .map((item) => BookCollection.fromJson(item))
                  .toList()
              : null,
      total: json['total'] as int?,
      skip: json['skip'] as int?,
      limit: json['limit'] as int?,
      collectionId: json['collection_id'] as String?,
      bookId: json['book_id'] as String?,
      bookName: json['book_name'] as String?,
      authorName: json['author_name'] as String?,
      editionName: json['edition_name'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      totalPages: json['total_pages'] as int?,
      addedAt: json['added_at'] as String?,
      codeUsed: json['code_used'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    collections,
    total,
    skip,
    limit,
    collectionId,
    bookId,
    bookName,
    authorName,
    editionName,
    coverImageUrl,
    totalPages,
    addedAt,
    codeUsed,
  ];
}
