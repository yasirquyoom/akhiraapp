class PdfModel {
  final String id;
  final String title;
  final String pdfUrl;
  final String thumbnailUrl;
  final String description;
  final int totalPages;
  final String author;

  const PdfModel({
    required this.id,
    required this.title,
    required this.pdfUrl,
    required this.thumbnailUrl,
    required this.description,
    required this.totalPages,
    required this.author,
  });

  PdfModel copyWith({
    String? id,
    String? title,
    String? pdfUrl,
    String? thumbnailUrl,
    String? description,
    int? totalPages,
    String? author,
  }) {
    return PdfModel(
      id: id ?? this.id,
      title: title ?? this.title,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      description: description ?? this.description,
      totalPages: totalPages ?? this.totalPages,
      author: author ?? this.author,
    );
  }
}
