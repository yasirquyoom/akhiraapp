class PdfModel {
  // Keep only PDF URL for preview-only functionality
  final String pdfUrl;

  const PdfModel({
    required this.pdfUrl,
  });

  PdfModel copyWith({
    String? pdfUrl,
  }) {
    return PdfModel(
      pdfUrl: pdfUrl ?? this.pdfUrl,
    );
  }
}
