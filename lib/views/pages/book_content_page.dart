import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'package:akhira/data/cubits/quiz/quiz_cubit_new.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../core/language/language_manager.dart';
import '../../data/cubits/audio/audio_cubit.dart';
import '../../data/cubits/book/book_state.dart';
import '../../data/cubits/book_content/book_content_state.dart';
import '../../router/app_router.dart';
import '../../widgets/language_toggle.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import '../../services/pdf_cache_service.dart';

class BookContentPage extends StatefulWidget {
  final int initialTabIndex;
  final String? bookId;

  const BookContentPage({super.key, this.initialTabIndex = 0, this.bookId});

  @override
  State<BookContentPage> createState() => _BookContentPageState();
}

class _BookContentPageState extends State<BookContentPage>
    with SingleTickerProviderStateMixin {
  late final LanguageManager _languageManager;
  late TabController _tabController;
  int _currentTabIndex = 0;
  late PdfViewerController _pdfViewerController;
  double _currentZoomLevel = 1.0;
  
  // PDF caching variables
  bool _isPdfCaching = false;
  double _cachingProgress = 0.0;
  String? _cachedPdfPath;
  bool _isPdfCached = false;

  @override
  void initState() {
    super.initState();
    _languageManager = LanguageManager();
    _languageManager.addListener(_onLanguageChanged);
    _currentTabIndex = widget.initialTabIndex;
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: _currentTabIndex,
    );
    _pdfViewerController = PdfViewerController();
    _tabController.addListener(_onTabChanged);

    // Load all book content initially
    _loadAllBookContent();
    
    // Initialize PDF cache
    _initializePdfCache();
  }

  @override
  void dispose() {
    _languageManager.removeListener(_onLanguageChanged);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    // Pause audio when leaving Book Content page entirely
    try {
      context.read<AudioCubit>().pauseTrack();
    } catch (_) {}
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
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

  // PDF Caching Methods
  Future<void> _initializePdfCache() async {
    await PdfCacheService.initialize();
  }

  Future<void> _checkPdfCache(String pdfUrl) async {
    if (pdfUrl.isEmpty) return;
    
    setState(() {
      _isPdfCaching = true;
      _cachingProgress = 0.0;
    });

    try {
      // Check if PDF is already cached
      final isCached = await PdfCacheService.isCached(pdfUrl);
      
      if (isCached) {
        final cachedPath = await PdfCacheService.getCachedFilePath(pdfUrl);
        setState(() {
          _cachedPdfPath = cachedPath;
          _isPdfCached = true;
          _isPdfCaching = false;
          _cachingProgress = 1.0;
        });
      } else {
        // Cache the PDF
        await _cachePdf(pdfUrl);
      }
    } catch (e) {
      setState(() {
        _isPdfCaching = false;
        _cachingProgress = 0.0;
      });
      print('Error checking PDF cache: $e');
    }
  }

  Future<void> _cachePdf(String pdfUrl) async {
    try {
      final cachedPath = await PdfCacheService.cachePdf(
        pdfUrl,
        onProgress: (progress) {
          setState(() {
            _cachingProgress = progress;
          });
        },
      );

      if (cachedPath != null) {
        setState(() {
          _cachedPdfPath = cachedPath;
          _isPdfCached = true;
          _isPdfCaching = false;
          _cachingProgress = 1.0;
        });
      } else {
        setState(() {
          _isPdfCaching = false;
          _cachingProgress = 0.0;
        });
      }
    } catch (e) {
      setState(() {
        _isPdfCaching = false;
        _cachingProgress = 0.0;
      });
      print('Error caching PDF: $e');
    }
  }

  String _getPdfSource(String pdfUrl) {
    if (_isPdfCached && _cachedPdfPath != null) {
      return _cachedPdfPath!;
    }
    return pdfUrl;
  }

  Widget _buildPdfViewer(String pdfUrl) {
    if (_isPdfCached && _cachedPdfPath != null) {
      // Use cached file
      return SfPdfViewer.file(
        File(_cachedPdfPath!),
        controller: _pdfViewerController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        canShowPaginationDialog: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          print('Cached PDF loaded: ${details.document.pages.count} pages');
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          print('Cached PDF load failed: ${details.error}');
          // If cached file fails, try to reload from network
          setState(() {
            _isPdfCached = false;
            _cachedPdfPath = null;
          });
          _checkPdfCache(pdfUrl);
        },
      );
    } else {
      // Use network source
      return SfPdfViewer.network(
        _sanitizeUrl(pdfUrl),
        controller: _pdfViewerController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        canShowPaginationDialog: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          print('Network PDF loaded: ${details.document.pages.count} pages');
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          print('Network PDF load failed: ${details.error}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load PDF: ${details.description}'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  setState(() {
                    // Reset cache state and retry
                    _isPdfCaching = false;
                    _isPdfCached = false;
                    _cachedPdfPath = null;
                  });
                  _checkPdfCache(pdfUrl);
                },
              ),
            ),
          );
        },
      );
    }
  }

  void _onTabChanged() {
    final previousTabIndex = _currentTabIndex;
    setState(() {
      _currentTabIndex = _tabController.index;
    });

    // Pause audio if switching away from audio tab
    if (previousTabIndex == 1 && _currentTabIndex != 1) {
      context.read<AudioCubit>().pauseTrack();
    }

    // Filter content based on current tab
    _filterContentForCurrentTab();
  }

  void _loadAllBookContent() {
    // Prefer widget parameter if provided, then fallback to global state
    final bookCubit = context.read<BookCubit>();
    String? bookId =
        (widget.bookId != null && widget.bookId!.isNotEmpty)
            ? widget.bookId
            : bookCubit.getCurrentBookId();

    // Update global if different and clear cache to avoid stale UI
    if (bookId != null && bookId.isNotEmpty) {
      final currentGlobal = bookCubit.getCurrentBookId();
      if (currentGlobal != bookId) {
        bookCubit.setBook(bookId: bookId, bookTitle: 'Unknown Book');
        context.read<BookContentCubit>().clearCache();
        // Reset quiz state so questions load for the newly selected book
        if (mounted) {
          context.read<QuizCubit>().restartQuiz();
        }
      }
    }

    if (bookId == null || bookId.isEmpty) {
      print('Warning: Book ID is null or empty, cannot load content');
      return;
    }

    print('Loading all content for bookId: $bookId');
    context.read<BookContentCubit>().loadAllBookContent(bookId: bookId);

    // Also ensure quiz APIs load for this book on page entry
    // (score first inside cubit, then quizzes)
    context.read<QuizCubit>().loadQuizzesFromApi(bookId: bookId);
  }

  void _filterContentForCurrentTab() {
    // Prefer widget parameter if provided, then fallback to global state
    final bookCubit = context.read<BookCubit>();
    String? bookId =
        (widget.bookId != null && widget.bookId!.isNotEmpty)
            ? widget.bookId
            : bookCubit.getCurrentBookId();

    if (bookId == null || bookId.isEmpty) {
      print('Warning: Book ID is null or empty, cannot filter content');
      return;
    }

    String? contentType;
    switch (_currentTabIndex) {
      case 0: // Digital book
        contentType = 'ebook';
        break;
      case 1: // Audio book
        contentType = 'audio';
        break;
      case 2: // Quiz
        contentType = 'quiz';
        break;
      case 3: // Videos
        contentType = 'video';
        break;
      case 4: // Images
        contentType = 'image';
        break;
    }

    print('Filtering content for bookId: $bookId, contentType: $contentType');
    context.read<BookContentCubit>().loadContentByType(
      bookId: bookId,
      contentType: contentType ?? '',
    );
  }

  void _refreshCurrentTabContent() {
    // Prefer widget parameter if provided, then fallback to global state
    final bookCubit = context.read<BookCubit>();
    String? bookId =
        (widget.bookId != null && widget.bookId!.isNotEmpty)
            ? widget.bookId
            : bookCubit.getCurrentBookId();

    if (bookId == null || bookId.isEmpty) {
      print('Warning: Book ID is null or empty, cannot refresh content');
      return;
    }

    String? contentType;
    switch (_currentTabIndex) {
      case 0: // Digital book
        contentType = 'ebook';
        break;
      case 1: // Audio book
        contentType = 'audio';
        break;
      case 2: // Quiz
        contentType = 'quiz';
        break;
      case 3: // Videos
        contentType = 'video';
        break;
      case 4: // Images
        contentType = 'image';
        break;
    }

    print('Refreshing content for bookId: $bookId, contentType: $contentType');
    context.read<BookContentCubit>().refreshContentByType(
      bookId: bookId,
      contentType: contentType ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F4F0), // Light mint/sage green background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () {
            context.go(AppRoutes.bookDetails);
          },
        ),
        title: BlocBuilder<BookContentCubit, BookContentState>(
          builder: (context, state) {
            if (state is BookContentLoaded && state.data.bookDetails != null) {
              return Text(
                state.data.bookDetails!.bookName,
                style: const TextStyle(
                  fontFamily: 'SFPro',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.black,
                ),
              );
            }
            return Text(
              'Book Content',
              style: const TextStyle(
                fontFamily: 'SFPro',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black,
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          LanguageToggle(languageManager: _languageManager),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,

            tabAlignment: TabAlignment.center,
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorPadding: EdgeInsets.symmetric(vertical: 4),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: AppColors.tabActiveBg,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontFamily: 'SFPro',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'SFPro',
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            dividerColor: Colors.transparent, // Remove divider line
            tabs: [
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    _languageManager.getText('Digital book', 'Livre numérique'),
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    _languageManager.getText('Audio book', 'Livre audio'),
                  ),
                ),
              ),
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(_languageManager.getText('Quiz', 'Quiz')),
                ),
              ),
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(_languageManager.getText('Videos', 'Vidéos')),
                ),
              ),
              Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(_languageManager.getText('Images', 'Images')),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshCurrentTabContent();
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDigitalBookTab(),
            _buildAudioTab(),
            _buildQuizTab(),
            _buildVideosTab(),
            _buildImagesTab(),
          ],
        ),
      ),
      bottomNavigationBar:
          _currentTabIndex == 1
              ? BlocBuilder<AudioCubit, AudioState>(
                builder: (context, state) {
                  if (state is AudioLoaded && state.currentTrack != null) {
                    return _buildBottomPlayer(state);
                  }
                  return const SizedBox.shrink();
                },
              )
              : null,
    );
  }

  Widget _buildDigitalBookTab() {
    // Check if bookId is available in global state
    final bookCubit = context.read<BookCubit>();
    final bookId = bookCubit.getCurrentBookId();

    print('DEBUG: Digital Book Tab - bookId: $bookId');

    if (bookId == null || bookId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'No Book Selected',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please go back and select a book first',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text('Go to Home'),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<BookContentCubit, BookContentState>(
      builder: (context, state) {
        print('DEBUG: Digital Book Tab - state: ${state.runtimeType}');
        
        if (state is BookContentLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BookContentLoaded) {
          print('DEBUG: Digital Book Tab - loaded data: ${state.data.contents?.length} contents');
          
          final ebookContents =
              state.data.contents
                  ?.where((content) => content.contentType == 'ebook')
                  .toList() ??
              [];

          print('DEBUG: Digital Book Tab - ebook contents: ${ebookContents.length}');
          
          if (ebookContents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf, size: 64.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'No PDF Content Available',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This book doesn\'t have any PDF content',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Render PDF inline in this tab (first PDF)
          final ebook = ebookContents.first;
          print('DEBUG: Digital Book Tab - rendering PDF: ${ebook.title}, URL: ${ebook.fileUrl}');
          return _buildInlinePdfViewer(
            title: ebook.title,
            pdfUrl: ebook.fileUrl,
          );
        } else if (state is BookContentError) {
          print('DEBUG: Digital Book Tab - error: ${state.message}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                Text(
                  'Error loading content',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  state.message,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => _refreshCurrentTabContent(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const Center(child: Text('No content available'));
      },
    );
  }

  // Deprecated ebook list/card helpers removed.

  Widget _buildInlinePdfViewer({
    required String title,
    required String pdfUrl,
  }) {
    // Initialize caching when PDF URL is available
    if (pdfUrl.isNotEmpty && !_isPdfCaching && !_isPdfCached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPdfCache(pdfUrl);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Enhanced zoom controls bar with cache status
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[50]!, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Cache status indicator
              if (_isPdfCaching || _isPdfCached)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _isPdfCached ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: _isPdfCached ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isPdfCaching)
                        SizedBox(
                          width: 12.w,
                          height: 12.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                            value: _cachingProgress,
                          ),
                        )
                      else
                        Icon(
                          Icons.offline_bolt,
                          size: 12.sp,
                          color: Colors.green,
                        ),
                      SizedBox(width: 4.w),
                      Text(
                        _isPdfCaching ? 'Caching...' : 'Cached',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: _isPdfCached ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (_isPdfCaching || _isPdfCached) SizedBox(width: 12.w),
              
              // Zoom level display with enhanced styling
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.1), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.zoom_in,
                      size: 14.sp,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _getZoomPercentage(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              
              // Zoom controls with better styling
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom out button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20.r),
                        onTap: _currentZoomLevel > 0.5 ? _zoomOut : null,
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          child: Icon(
                            Icons.remove,
                            color: _currentZoomLevel > 0.5 ? AppColors.primary : Colors.grey,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20.h,
                      color: Colors.grey[300],
                    ),
                    // Reset zoom button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20.r),
                        onTap: _currentZoomLevel != 1.0 ? _resetZoom : null,
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          child: Icon(
                            Icons.refresh,
                            color: _currentZoomLevel != 1.0 ? AppColors.primary : Colors.grey,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20.h,
                      color: Colors.grey[300],
                    ),
                    // Zoom in button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20.r),
                        onTap: _currentZoomLevel < 3.0 ? _zoomIn : null,
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          child: Icon(
                            Icons.add,
                            color: _currentZoomLevel < 3.0 ? AppColors.primary : Colors.grey,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // PDF title with better styling
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              SizedBox(width: 16.w),
              
              // Fullscreen button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20.r),
                  onTap: () => _openFullscreenPdf(title, pdfUrl),
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.fullscreen,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Enhanced PDF viewer with gesture detection
        Expanded(
          child: GestureDetector(
            onScaleStart: (details) {
              // Store initial zoom level for pinch-to-zoom
            },
            onScaleUpdate: (details) {
              if (details.scale != 1.0) {
                final newZoomLevel = (_currentZoomLevel * details.scale).clamp(0.5, 3.0);
                if (newZoomLevel != _currentZoomLevel) {
                  setState(() {
                    _currentZoomLevel = newZoomLevel;
                    _pdfViewerController.zoomLevel = _currentZoomLevel;
                  });
                }
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: _buildPdfViewer(pdfUrl),
            ),
          ),
        ),
      ],
    );
  }

  String _sanitizeUrl(String url) {
    String u = url.trim();
    if (u.endsWith('?')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  void _openFullscreenPdf(String title, String pdfUrl) {
    final effectivePdfUrl = _getPdfSource(pdfUrl);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenPdfViewer(
          title: title,
          pdfUrl: effectivePdfUrl,
          isFromCache: _isPdfCached,
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$m:$s';
  }

  Widget _buildAudioTab() {
    // Check if bookId is available in global state
    final bookCubit = context.read<BookCubit>();
    final bookId = bookCubit.getCurrentBookId();

    if (bookId == null || bookId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'No Book Selected',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please go back and select a book first',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text('Go to Home'),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<BookContentCubit, BookContentState>(
      builder: (context, state) {
        if (state is BookContentLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BookContentLoaded) {
          final audioContents =
              state.data.contents
                  ?.where((content) => content.contentType == 'audio')
                  .toList() ??
              [];

          if (audioContents.isEmpty) {
            return const SizedBox.shrink();
          }

          // Load audio data into AudioCubit only if not already loaded
          final audioCubit = context.read<AudioCubit>();
          final audioState = audioCubit.state;
          final shouldLoad =
              audioState is! AudioLoaded || audioState.tracks.isEmpty;
          if (shouldLoad) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              audioCubit.loadAudioTracksFromApi(audioContents);
            });
          }

          return _buildAudioList(audioContents);
        } else if (state is BookContentError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAudioList(List<dynamic> audioContents) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: audioContents.length,
      itemBuilder: (context, index) {
        final audio = audioContents[index];
        return _buildAudioTrackCard(audio);
      },
    );
  }

  Widget _buildAudioTrackCard(dynamic audio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                (audio.coverImageUrl != null &&
                        (audio.coverImageUrl as String).isNotEmpty)
                    ? Image.network(
                      _sanitizeUrl(audio.coverImageUrl as String),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.audiotrack,
                              color: Colors.grey[400],
                            ),
                          ),
                    )
                    : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: Icon(Icons.audiotrack, color: Colors.grey[400]),
                    ),
          ),
          const SizedBox(width: 16),
          // Track Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  audio.title,
                  maxLines: 2,
                  style: const TextStyle(
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                // const SizedBox(height: 4),
                // Text(
                //   'File Size: ${audio.fileSizeMb.toStringAsFixed(1)} MB',
                //   style: const TextStyle(
                //     fontFamily: 'SFPro',
                //     fontWeight: FontWeight.w500,
                //     fontSize: 14,
                //     color: Colors.grey,
                //   ),
                // ),
              ],
            ),
          ),
          // Play Button
          GestureDetector(
            onTap: () {
              // Create an AudioTrack from the BookContent audio data
              final audioTrack = AudioTrack(
                id: audio.contentId ?? 'unknown',
                title: audio.title,
                duration: '0:00', // We don't have duration from API
                audioUrl: audio.fileUrl ?? '',
                thumbnailUrl: '', // BookContent doesn't have thumbnailUrl field
              );

              // Start playing the audio track
              context.read<AudioCubit>().playTrack(audioTrack);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.tabActiveBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPlayer(AudioLoaded state) {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.audioFullscreen);
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E4FB6), Color(0xFF142350)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    (state.currentTrack?.thumbnailUrl.isNotEmpty == true)
                        ? Image.network(
                          _sanitizeUrl(state.currentTrack!.thumbnailUrl),
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: Colors.white.withOpacity(0.2),
                                child: const Icon(
                                  Icons.audiotrack,
                                  color: Colors.white,
                                ),
                              ),
                        )
                        : Container(
                          color: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.audiotrack,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
            // Track Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.currentTrack?.title ?? 'Title',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'SFPro',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white, // Changed from black to white
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDuration(state.currentPosition)} / ${_formatDuration(state.totalDuration)}',
                    style: const TextStyle(
                      fontFamily: 'SFPro',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            // Controls
            Row(
              children: [
                IconButton(
                  onPressed: () => context.read<AudioCubit>().previousTrack(),
                  icon: const Icon(
                    Icons.skip_previous,
                    color: Colors.white,
                  ), // Changed from black to white
                ),
                IconButton(
                  onPressed: () {
                    if (state.isPlaying) {
                      context.read<AudioCubit>().pauseTrack();
                    } else {
                      context.read<AudioCubit>().resumeTrack();
                    }
                  },
                  icon: Icon(
                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white, // Changed from black to white
                    size: 32,
                  ),
                ),
                IconButton(
                  onPressed: () => context.read<AudioCubit>().nextTrack(),
                  icon: const Icon(
                    Icons.skip_next,
                    color: Colors.white,
                  ), // Changed from black to white
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizTab() {
    // Prefer widget parameter if provided, then fallback to global state
    final bookCubit = context.read<BookCubit>();
    final bookId =
        (widget.bookId != null && widget.bookId!.isNotEmpty)
            ? widget.bookId
            : bookCubit.getCurrentBookId();

    if (bookId == null || bookId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'No Book Selected',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please go back and select a book first',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text('Go to Home'),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<QuizCubit, QuizState>(
      builder: (context, state) {
        if (state is QuizLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is QuizLoaded) {
          final completedByApi =
              state.remainingQuestions == 0 &&
              (state.totalQuestionsFromApi > 0 || state.totalAttempted > 0);
          if (completedByApi) {
            return _buildScoreCardOnly(state, bookId);
          }
          // Avoid RangeError if questions not yet loaded
          if (state.questions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final allAnswered =
              state.totalAttempted >= state.totalQuestions &&
              state.totalQuestions > 0;
          if (allAnswered) {
            return _buildScoreCardOnly(state, bookId);
          }
          return _buildQuizContent(state, bookId);
        } else if (state is QuizCompleted) {
          // We no longer use this visual path; defer to Loaded score card logic
          return const SizedBox.shrink();
        } else if (state is QuizError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  'Error: ${state.message}',
                  style: TextStyle(fontSize: 16.sp, color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    context.read<QuizCubit>().loadQuizzesFromApi(
                      bookId: bookId,
                    );
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        } else {
          // QuizInitial state - load quizzes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<QuizCubit>().loadQuizzesFromApi(bookId: bookId);
          });
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildScoreCardOnly(QuizLoaded state, String bookId) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(30.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryGradientEnd],
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _languageManager.getText('Quiz Score', 'Score du Quiz'),
                  style: TextStyle(
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w700,
                    fontSize: 20.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${state.marksEarned}',
                            style: TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w700,
                              fontSize: 28.sp,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _languageManager.getText('Marks', 'Points'),
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 5,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${state.totalAttempted}/${state.totalQuestions}',
                            style: TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w700,
                              fontSize: 28.sp,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _languageManager.getText('Attempted', 'Tentées'),
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  '${state.percentage.toStringAsFixed(2)}%',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 48.h,
            child: ElevatedButton(
              onPressed:
                  state.isResetting
                      ? null
                      : () =>
                          context.read<QuizCubit>().resetBookAnswers(bookId),
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: AppColors.primary.withOpacity(0.7),
              ),
              child:
                  state.isResetting
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            _languageManager.getText(
                              'Resetting...',
                              'Réinitialisation...',
                            ),
                            style: TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                      : Text(
                        _languageManager.getText(
                          'Reset Answers',
                          'Réinitialiser',
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent(QuizLoaded state, String bookId) {
    return Stack(
      children: [
        // Main quiz content
        SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score and Progress Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(30.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryGradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    // Score
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${state.marksEarned}',
                            style: TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w700,
                              fontSize: 32.sp,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _languageManager.getText('Marks', 'Points'),
                            style: TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Container(
                      width: 5,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    // Question Progress
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${state.totalAttempted}/${state.totalQuestions}',
                            style: TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w700,
                              fontSize: 32.sp,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _languageManager.getText('Attempted', 'Tentées'),
                            style: TextStyle(
                              fontFamily: 'SFPro',
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Question
              Text(
                state.currentQuestion.question,
                style: TextStyle(
                  fontFamily: 'SFPro',
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: 24.h),

              // Options
              ...state.currentQuestion.options.map(
                (option) => _buildQuizOption(
                  option,
                  state.selectedOptionId == option.id,
                ),
              ),

              SizedBox(height: 24.h),

              // Navigation Buttons Row
              Row(
                children: [
                  // Back Button (only show for questions 2-5)
                  if (!state.isFirstQuestion) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            () => context.read<QuizCubit>().previousQuestion(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade700,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _languageManager.getText('Back', 'Retour'),
                              style: TextStyle(
                                fontFamily: 'SFPro',
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                  ],

                  // Next/Submit Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          state.selectedOptionId != null && !state.isSubmitting
                              ? () {
                                final cubit = context.read<QuizCubit>();
                                cubit.submitAnswer();
                                cubit.refreshBookScore(bookId);
                                cubit.nextQuestion();
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            state.selectedOptionId != null &&
                                    !state.isSubmitting
                                ? AppColors.primary
                                : Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child:
                          state.isSubmitting
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18.w,
                                    height: 18.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    _languageManager.getText(
                                      'Submitting...',
                                      'Envoi...',
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'SFPro',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    state.isLastQuestion
                                        ? _languageManager.getText(
                                          'Submit',
                                          'Envoyer',
                                        )
                                        : _languageManager.getText(
                                          'Next',
                                          'Suivant',
                                        ),
                                    style: TextStyle(
                                      fontFamily: 'SFPro',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.sp,
                                      color:
                                          state.selectedOptionId != null
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizOption(QuizOption option, bool isSelected) {
    return GestureDetector(
      onTap: () => context.read<QuizCubit>().selectOption(option.id),
      child: Container(
        margin: EdgeInsets.only(bottom: 20.h),
        child: Row(
          children: [
            // Option Letter Circle
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryGradientEnd],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  option.letter,
                  style: TextStyle(
                    fontFamily: 'SFPro',
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(width: 16.w),

            // Option Text
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(
                  fontFamily: 'SFPro',
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                  color: Colors.black,
                ),
              ),
            ),

            // Radio Button
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child:
                  isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 16.sp)
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  // Deprecated quiz completed helper removed.

  Widget _buildVideosTab() {
    // Check if bookId is available in global state
    final bookCubit = context.read<BookCubit>();
    final bookId = bookCubit.getCurrentBookId();

    print('DEBUG: Videos Tab - bookId: $bookId');

    if (bookId == null || bookId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'No Book Selected',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please go back and select a book first',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text('Go to Home'),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<BookContentCubit, BookContentState>(
      builder: (context, state) {
        print('DEBUG: Videos Tab - state: ${state.runtimeType}');
        
        if (state is BookContentLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BookContentLoaded) {
          print('DEBUG: Videos Tab - loaded data: ${state.data.contents?.length} contents');
          
          final videoContents =
              state.data.contents
                  ?.where((content) => content.contentType == 'video')
                  .toList() ??
              [];

          print('DEBUG: Videos Tab - video contents: ${videoContents.length}');
          
          if (videoContents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library, size: 64.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'No Video Content Available',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This book doesn\'t have any video content',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          print('DEBUG: Videos Tab - rendering video list with ${videoContents.length} videos');
          return _buildVideoList(videoContents);
        } else if (state is BookContentError) {
          print('DEBUG: Videos Tab - error: ${state.message}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  'Error loading videos',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  state.message,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => _refreshCurrentTabContent(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }
        // Avoid flicker on swipe: show nothing instead of a transient empty state
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildVideoList(List<dynamic> videoContents) {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: videoContents.length,
      itemBuilder: (context, index) {
        final video = videoContents[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildVideoCard(dynamic video) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: GestureDetector(
        onTap: () {
          // Navigate to video fullscreen page with video data
          context.push(
            AppRoutes.videoFullscreen,
            extra: {
              'title': video.title,
              'videoUrl': video.fileUrl ?? '',
              'thumbnailUrl': '', // BookContent doesn't have thumbnailUrl field
              'fileSize': video.fileSizeMb,
            },
          );
        },
        child: Container(
          height: 200.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Stack(
              children: [
                // Thumbnail: prefer content.coverImageUrl, fallback to icon
                Positioned.fill(
                  child:
                      (video.coverImageUrl != null &&
                              (video.coverImageUrl as String).isNotEmpty)
                          ? Image.network(
                            _sanitizeUrl((video.coverImageUrl as String)),
                            fit: BoxFit.cover,
                          )
                          : Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.videocam,
                              size: 64.sp,
                              color: Colors.grey[400],
                            ),
                          ),
                ),

                // Play Button Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32.sp,
                        ),
                      ),
                    ),
                  ),
                ),

                // Video Info
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          video.title,
                          style: TextStyle(
                            fontFamily: 'SFPro',
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // SizedBox(height: 4.h),
                        // Text(
                        //   'File Size: ${video.fileSizeMb.toStringAsFixed(1)} MB',
                        //   style: TextStyle(
                        //     fontFamily: 'SFPro',
                        //     fontWeight: FontWeight.w500,
                        //     fontSize: 14.sp,
                        //     color: Colors.white70,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagesTab() {
    // Check if bookId is available in global state
    final bookCubit = context.read<BookCubit>();
    final bookId = bookCubit.getCurrentBookId();

    if (bookId == null || bookId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'No Book Selected',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please go back and select a book first',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text('Go to Home'),
            ),
          ],
        ),
      );
    }

    return BlocBuilder<BookContentCubit, BookContentState>(
      builder: (context, state) {
        if (state is BookContentLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is BookContentLoaded) {
          final imageContents =
              state.data.contents
                  ?.where((content) => content.contentType == 'image')
                  .toList() ??
              [];

          if (imageContents.isEmpty) {
            return const SizedBox.shrink();
          }

          return _buildImageCardStack(imageContents);
        } else if (state is BookContentError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildImageCardStack(List<dynamic> imageContents) {
    return _ImageCardStackWidget(imageContents: imageContents);
  }
}

class _ImageCardStackWidget extends StatefulWidget {
  final List<dynamic> imageContents;

  const _ImageCardStackWidget({required this.imageContents});

  @override
  State<_ImageCardStackWidget> createState() => _ImageCardStackWidgetState();
}

class _ImageCardStackWidgetState extends State<_ImageCardStackWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _verticalAnimationController;
  late Animation<double> _animation;
  late Animation<double> _verticalAnimation;
  int _currentIndex = 0;
  double _dragDistance = 0.0;
  double _verticalDragDistance = 0.0;
  bool _isDragging = false;
  bool _isVerticalDragging = false;

  String _sanitizeUrlLocal(String url) {
    var u = (url).trim();
    if (u.endsWith('?')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  Future<void> _saveImageToGallery(String url, String fileName) async {
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        _sanitizeUrlLocal(url),
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = Uint8List.fromList(response.data ?? []);

      final has = await Gal.hasAccess();
      if (!has) {
        await Gal.requestAccess();
      }

      await Gal.putImageBytes(
        bytes,
        album: 'Akhira',
        name:
            fileName.isNotEmpty
                ? fileName
                : 'image_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to gallery')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving image: $e')));
    }
  }

  Future<void> _shareImage(String url, String fileName) async {
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        _sanitizeUrlLocal(url),
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = Uint8List.fromList(response.data ?? []);
      final tempDir = await Directory.systemTemp.createTemp('share_img_');
      final filePath =
          '${tempDir.path}/${fileName.isNotEmpty ? fileName : 'shared_image'}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing image: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _verticalAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _verticalAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _verticalAnimationController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _verticalAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _isDragging = true;
        _isVerticalDragging = true;
      },
      onPanUpdate: (details) {
        if (_isDragging || _isVerticalDragging) {
          setState(() {
            _dragDistance += details.delta.dx;
            _verticalDragDistance += details.delta.dy;
          });
        }
      },
      onPanEnd: (details) {
        _isDragging = false;
        _isVerticalDragging = false;

        // Determine swipe direction and velocity
        final horizontalVelocity = details.velocity.pixelsPerSecond.dx;
        final verticalVelocity = details.velocity.pixelsPerSecond.dy;
        final dragThreshold = 80.0;
        final velocityThreshold = 400.0;

        // Check if vertical gesture is more dominant
        if (_verticalDragDistance.abs() > _dragDistance.abs() && _verticalDragDistance.abs() > 30.0) {
          // Vertical swipe detected
          if (_verticalDragDistance.abs() > dragThreshold || verticalVelocity.abs() > velocityThreshold) {
            if (_verticalDragDistance < 0 || verticalVelocity < 0) {
              // Swipe up - next image with vertical animation
              _nextImageVertical();
            } else {
              // Swipe down - previous image with vertical animation
              _previousImageVertical();
            }
          }
        } else if (_dragDistance.abs() > 30.0) {
          // Horizontal swipe detected
          if (_dragDistance.abs() > dragThreshold || horizontalVelocity.abs() > velocityThreshold) {
            if (_dragDistance > 0 || horizontalVelocity > 0) {
              // Swipe right - previous image
              _previousImage();
            } else {
              // Swipe left - next image
              _nextImage();
            }
          }
        }

        // Reset drag distances
        setState(() {
          _dragDistance = 0.0;
          _verticalDragDistance = 0.0;
        });
      },
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Background cards (stacked behind)
            ..._buildBackgroundCards(),

            // Main card (on top)
            _buildMainCard(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundCards() {
    final cards = <Widget>[];
    final maxBackgroundCards = 2; // Only 2 background cards for cleaner look

    // Define gradient colors for background cards
    final gradientColors = [
      [Color(0xFF6B73FF), Color(0xFF9B59B6)], // Purple-blue gradient
      [Color(0xFF4A90E2), Color(0xFF7B68EE)], // Blue gradient
    ];

    for (int i = 1; i <= maxBackgroundCards; i++) {
      final scale = 1.0 - (i * 0.03); // Each card is 3% smaller
      final offset = i * 12.0; // Reduced offset for tighter stacking

      cards.add(
        Positioned(
          top: offset,
          left: offset,
          right: offset,
          bottom: offset,
          child: Transform.scale(
            scale: scale,
            child: Container(
              margin: EdgeInsets.only(top: 40.h, bottom: 80.h, left: 24.w, right: 24.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors[i - 1],
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[i - 1][0].withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return cards.reversed.toList(); // Reverse to show cards in correct order
  }

  Widget _buildMainCard() {
    final currentImage = widget.imageContents[_currentIndex];
    final rotation = _dragDistance * 0.001; // Convert drag distance to rotation
    final opacity = math.max(0.0, 1.0 - (_dragDistance.abs() * 0.002));
    
    // Vertical animation effects
    final verticalOffset = _isVerticalDragging ? _verticalDragDistance * 0.8 : 0.0;
    final verticalOpacity = math.max(0.3, 1.0 - (_verticalDragDistance.abs() * 0.001));
    final verticalScale = math.max(0.85, 1.0 - (_verticalDragDistance.abs() * 0.0003));
    final verticalRotation = _verticalDragDistance * 0.0005;

    return AnimatedBuilder(
      animation: Listenable.merge([_animation, _verticalAnimation]),
      builder: (context, child) {
        // Determine which animation to use based on gesture type
        final isVerticalGesture = _verticalDragDistance.abs() > _dragDistance.abs();
        
        if (isVerticalGesture) {
          // Vertical swipe animation
          return Transform.translate(
            offset: Offset(0, verticalOffset + (_verticalAnimation.value * -MediaQuery.of(context).size.height * 1.2)),
            child: Transform.scale(
              scale: verticalScale * (1.0 - _verticalAnimation.value * 0.3),
              child: Transform.rotate(
                angle: verticalRotation + (_verticalAnimation.value * verticalRotation * 2),
                child: Opacity(
                  opacity: verticalOpacity * (1.0 - _verticalAnimation.value),
                  child: _buildCard(currentImage),
                ),
              ),
            ),
          );
        } else {
          // Horizontal swipe animation
          return Transform.translate(
            offset: Offset(_dragDistance, 0),
            child: Transform.rotate(
              angle: rotation,
              child: Opacity(opacity: opacity, child: _buildCard(currentImage)),
            ),
          );
        }
      },
    );
  }

  Widget _buildCard(
    dynamic image, {
    double opacity = 1.0,
    bool isBackground = false,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 40.h, bottom: 80.h, left: 24.w, right: 24.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40.r),
        color: isBackground ? Colors.white.withOpacity(0.1) : Colors.white,
        border:
            isBackground
                ? Border.all(color: Colors.white.withOpacity(0.6), width: 2.0)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40.r),
        child: Stack(
          children: [
            // Image
            Image.network(
              image.fileUrl ?? '',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),



            // Bottom overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40.r),
                    bottomRight: Radius.circular(40.r),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.6),
                      Colors.transparent
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        image.title ?? 'Le titre de l\'image ira ici',
                        style: TextStyle(
                          fontFamily: 'SFPro',
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    GestureDetector(
                      onTap: () => _shareImage(
                        image.fileUrl ?? '',
                        image.title ?? '',
                      ),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        child: Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextImage() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.imageContents.length;
    });
  }

  void _previousImage() {
    setState(() {
      _currentIndex =
          _currentIndex == 0
              ? widget.imageContents.length - 1
              : _currentIndex - 1;
    });
  }

  void _nextImageVertical() {
    _verticalAnimationController.forward().then((_) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.imageContents.length;
      });
      _verticalAnimationController.reset();
    });
  }

  void _previousImageVertical() {
    _verticalAnimationController.forward().then((_) {
      setState(() {
        _currentIndex =
            _currentIndex == 0
                ? widget.imageContents.length - 1
                : _currentIndex - 1;
      });
      _verticalAnimationController.reset();
    });
  }
}

// Fullscreen PDF Viewer Widget
class _FullscreenPdfViewer extends StatefulWidget {
  final String title;
  final String pdfUrl;
  final bool isFromCache;

  const _FullscreenPdfViewer({
    required this.title,
    required this.pdfUrl,
    this.isFromCache = false,
  });

  @override
  State<_FullscreenPdfViewer> createState() => _FullscreenPdfViewerState();
}

class _FullscreenPdfViewerState extends State<_FullscreenPdfViewer> {
  late PdfViewerController _pdfController;
  double _currentZoomLevel = 1.0;
  bool _isLoading = true;
  bool _showControls = true;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _currentZoomLevel = (_currentZoomLevel + 0.25).clamp(0.5, 5.0);
      _pdfController.zoomLevel = _currentZoomLevel;
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoomLevel = (_currentZoomLevel - 0.25).clamp(0.5, 5.0);
      _pdfController.zoomLevel = _currentZoomLevel;
    });
  }

  void _resetZoom() {
    setState(() {
      _currentZoomLevel = 1.0;
      _pdfController.zoomLevel = _currentZoomLevel;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _goToPage() {
    showDialog(
      context: context,
      builder: (context) {
        int pageNumber = _currentPage;
        return AlertDialog(
          title: Text('Go to Page'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter page number (1-$_totalPages):'),
              SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Page number',
                ),
                onChanged: (value) {
                  pageNumber = int.tryParse(value) ?? _currentPage;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (pageNumber >= 1 && pageNumber <= _totalPages) {
                  _pdfController.jumpToPage(pageNumber);
                  Navigator.pop(context);
                }
              },
              child: Text('Go'),
            ),
          ],
        );
      },
    );
  }

  String _sanitizeUrl(String url) {
    String u = url.trim();
    if (u.endsWith('?')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PDF Viewer
          GestureDetector(
            onTap: _toggleControls,
            onScaleStart: (details) {
              // Store initial zoom level for pinch-to-zoom
            },
            onScaleUpdate: (details) {
              if (details.scale != 1.0) {
                final newZoomLevel = (_currentZoomLevel * details.scale).clamp(0.5, 5.0);
                if (newZoomLevel != _currentZoomLevel) {
                  setState(() {
                    _currentZoomLevel = newZoomLevel;
                    _pdfController.zoomLevel = _currentZoomLevel;
                  });
                }
              }
            },
            child: widget.isFromCache
                ? SfPdfViewer.file(
                    File(widget.pdfUrl),
                    controller: _pdfController,
                    canShowScrollHead: false,
                    canShowScrollStatus: false,
                    enableDoubleTapZooming: true,
                    enableTextSelection: true,
                    canShowPaginationDialog: false,
                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                      setState(() {
                        _isLoading = false;
                        _totalPages = details.document.pages.count;
                      });
                    },
                    onPageChanged: (PdfPageChangedDetails details) {
                      setState(() {
                        _currentPage = details.newPageNumber;
                      });
                    },
                    onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                      setState(() {
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to load cached PDF: ${details.description}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  )
                : SfPdfViewer.network(
                    _sanitizeUrl(widget.pdfUrl),
                    controller: _pdfController,
                    canShowScrollHead: false,
                    canShowScrollStatus: false,
                    enableDoubleTapZooming: true,
                    enableTextSelection: true,
                    canShowPaginationDialog: false,
                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                      setState(() {
                        _isLoading = false;
                        _totalPages = details.document.pages.count;
                      });
                    },
                    onPageChanged: (PdfPageChangedDetails details) {
                      setState(() {
                        _currentPage = details.newPageNumber;
                      });
                    },
                    onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                      setState(() {
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to load PDF: ${details.description}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading PDF...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Top controls
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.share, color: Colors.white),
                      onPressed: () {
                        // Share PDF functionality
                        Share.share(widget.pdfUrl, subject: widget.title);
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Bottom controls
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  top: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Page info
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    
                    // Go to page button
                    IconButton(
                      icon: Icon(Icons.bookmark, color: Colors.white),
                      onPressed: _goToPage,
                    ),
                    
                    Spacer(),
                    
                    // Zoom controls
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, color: Colors.white),
                            onPressed: _currentZoomLevel > 0.5 ? _zoomOut : null,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${(_currentZoomLevel * 100).round()}%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh, color: Colors.white),
                            onPressed: _currentZoomLevel != 1.0 ? _resetZoom : null,
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.white),
                            onPressed: _currentZoomLevel < 5.0 ? _zoomIn : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
