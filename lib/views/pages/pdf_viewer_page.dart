import 'package:akhira/data/models/pdf_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../constants/app_colors.dart';
import '../../router/app_router.dart';

class PdfViewerPage extends StatefulWidget {
  final PdfModel pdf;

  const PdfViewerPage({super.key, required this.pdf});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 0;
  int _totalPages = 0;
  final bool _isReady = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('${AppRoutes.bookContent}?tab=0'),
        ),
        title: Text(
          widget.pdf.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isReady)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Center(
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 64.sp),
                  SizedBox(height: 16.h),
                  Text(
                    'Failed to load PDF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _errorMessage ?? 'Please check your internet connection',
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _hasError = false;
                        _errorMessage = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Retry', style: TextStyle(fontSize: 16.sp)),
                  ),
                ],
              ),
            )
          else
            PDFView(
              filePath: widget.pdf.pdfUrl,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: false,
              pageFling: true,
              pageSnap: true,
              onRender: (pages) {
                setState(() {
                  _totalPages = pages!;
                  _isLoading = false;
                });
              },
              onViewCreated: (PDFViewController controller) {
                // Controller is ready
              },
              onPageChanged: (page, total) {
                setState(() {
                  _currentPage = page! + 1;
                });
              },
              onError: (error) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                  _errorMessage = error.toString();
                });
              },
              onPageError: (page, error) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                  _errorMessage =
                      'Error loading page $page: ${error.toString()}';
                });
              },
            ),
        ],
      ),
    );
  }
}
