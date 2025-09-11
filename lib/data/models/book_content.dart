import 'package:equatable/equatable.dart';

class BookContent extends Equatable {
  final String contentId;
  final String bookId;
  final String contentType;
  final String title;
  final String fileName;
  final String fileUrl;
  final String? coverImageUrl;
  final double fileSizeMb;
  final String mimeType;
  final int contentNumber;
  final String createdAt;
  final String updatedAt;

  const BookContent({
    required this.contentId,
    required this.bookId,
    required this.contentType,
    required this.title,
    required this.fileName,
    required this.fileUrl,
    this.coverImageUrl,
    required this.fileSizeMb,
    required this.mimeType,
    required this.contentNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookContent.fromJson(Map<String, dynamic> json) {
    return BookContent(
      contentId: json['content_id'] as String,
      bookId: json['book_id'] as String,
      contentType: json['content_type'] as String,
      title: json['title'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      coverImageUrl: json['cover_image_url'] as String?,
      fileSizeMb: (json['file_size_mb'] as num).toDouble(),
      mimeType: json['mime_type'] as String,
      contentNumber: json['content_number'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content_id': contentId,
      'book_id': bookId,
      'content_type': contentType,
      'title': title,
      'file_name': fileName,
      'file_url': fileUrl,
      'cover_image_url': coverImageUrl,
      'file_size_mb': fileSizeMb,
      'mime_type': mimeType,
      'content_number': contentNumber,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
    contentId,
    bookId,
    contentType,
    title,
    fileName,
    fileUrl,
    coverImageUrl,
    fileSizeMb,
    mimeType,
    contentNumber,
    createdAt,
    updatedAt,
  ];
}
