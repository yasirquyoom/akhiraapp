import 'package:equatable/equatable.dart';

class BookModel extends Equatable {
  final String id;
  final String title;
  final String author;
  final String coverImageUrl;
  final String? description;
  final DateTime? publishedDate;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.coverImageUrl,
    this.description,
    this.publishedDate,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      coverImageUrl: json['coverImageUrl'] as String,
      description: json['description'] as String?,
      publishedDate:
          json['publishedDate'] != null
              ? DateTime.parse(json['publishedDate'] as String)
              : null,
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
  ];
}
