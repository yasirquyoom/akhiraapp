import 'package:akhira/data/models/pdf_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../../constants/app_colors.dart';
import '../../router/app_router.dart';
import '../../services/pdf_cache_service.dart';

class PdfViewerPage extends StatefulWidget {
  final PdfModel pdf;

  const PdfViewerPage({super.key, required this.pdf});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late PdfViewerController _pdfViewerController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  double _currentZoomLevel = 1.0;
  bool _isFromCache = false;
  String? _cachedPath;

  String _sanitizeUrl(String url) {
    var u = url.trim();
    if (u.isEmpty) return u;
    // Remove wrapping quotes/backticks
    if ((u.startsWith('"') && u.endsWith('"')) ||
        (u.startsWith("'") && u.endsWith("'")) ||
        (u.startsWith('`') && u.endsWith('`'))) {
      u = u.substring(1, u.length - 1);
    }
    // Remove trailing question marks introduced by formatting
    while (u.endsWith('?')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _initPdf();
  }

  Future<void> _initPdf() async {
    final url = _sanitizeUrl(widget.pdf.pdfUrl);
    if (!kIsWeb) {
      try {
        await PdfCacheService.initialize();
        final cached = await PdfCacheService.getCachedFilePath(url);
        if (cached != null) {
          setState(() {
            _cachedPath = cached;
            _isFromCache = true;
          });
          return;
        } else {
          // Background cache for future opens
          PdfCacheService.cachePdf(url).catchError((_) {});
        }
      } catch (_) {
        // ignore caching errors
      }
    }
    setState(() {
      _isFromCache = false;
    });
  }

  void _zoomIn() {
    setState(() {
      _currentZoomLevel = (_currentZoomLevel + 0.25).clamp(0.5, 3.0);
      _pdfViewerController.zoomLevel = _currentZoomLevel;
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoomLevel = (_currentZoomLevel - 0.25).clamp(0.5, 3.0);
      _pdfViewerController.zoomLevel = _currentZoomLevel;
    });
  }

  void _resetZoom() {
    setState(() {
      _currentZoomLevel = 1.0;
      _pdfViewerController.zoomLevel = _currentZoomLevel;
    });
  }

  String _getZoomPercentage() {
    return '${(_currentZoomLevel * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
  appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('${AppRoutes.bookContent}?tab=0'),
        ),
        // For preview-only, show a generic title
        title: Text(
          'PDF Preview',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Zoom level display
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              margin: EdgeInsets.only(right: 8.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                _getZoomPercentage(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // Zoom out button
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.black),
            onPressed: _currentZoomLevel > 0.5 ? _zoomOut : null,
            tooltip: 'Zoom Out',
          ),
          // Reset zoom button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _currentZoomLevel != 1.0 ? _resetZoom : null,
            tooltip: 'Reset Zoom',
          ),
          // Zoom in button
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.black),
            onPressed: _currentZoomLevel < 3.0 ? _zoomIn : null,
            tooltip: 'Zoom In',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isFromCache && _cachedPath != null)
            SfPdfViewer.file(
              File(_cachedPath!),
              controller: _pdfViewerController,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() {
                  _isLoading = false;
                });
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = details.error;
                });
              },
            )
          else
            SfPdfViewer.network(
              _sanitizeUrl(widget.pdf.pdfUrl),
              controller: _pdfViewerController,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                setState(() {
                  _isLoading = false;
                });
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = details.error;
                });
              },
            ),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16.h),
                    Text(
                      'Loading PDF...',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_hasError)
            Container(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                      SizedBox(height: 16.h),
                      Text(
                        'Failed to load PDF',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _errorMessage ??
                            'Please check your internet connection',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 32.w,
                            vertical: 12.h,
                          ),
                        ),
                        child: Text(
                          'Try Again',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
