import 'package:equatable/equatable.dart';

class BookModel extends Equatable {
  final String id;
  final String title;
  final String author;
  final String coverImageUrl;
  final String? description;
  final DateTime? publishedDate;
  final String? editionName;
  final int? totalPages;
  final String? addedAt;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.coverImageUrl,
    this.description,
    this.publishedDate,
    this.editionName,
    this.totalPages,
    this.addedAt,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['book_id'] as String? ?? json['id'] as String,
      title: json['book_name'] as String? ?? json['title'] as String,
      author: json['author_name'] as String? ?? json['author'] as String,
      coverImageUrl:
          json['cover_image_url'] as String? ?? json['coverImageUrl'] as String,
      description: json['description'] as String?,
      publishedDate:
          json['publishedDate'] != null
              ? DateTime.parse(json['publishedDate'] as String)
              : null,
      editionName: json['edition_name'] as String?,
      totalPages: json['total_pages'] as int?,
      addedAt: json['added_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverImageUrl': coverImageUrl,
      'description': description,
      'publishedDate': publishedDate?.toIso8601String(),
      'editionName': editionName,
      'totalPages': totalPages,
      'addedAt': addedAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    author,
    coverImageUrl,
    description,
    publishedDate,
    editionName,
    totalPages,
    addedAt,
  ];
}
