import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PdfCacheService {
  static const String _cacheFolder = 'pdf_cache';
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration _cacheExpiry = Duration(days: 7);

  static Directory? _cacheDirectory;

  /// Initialize the cache directory
  static Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory('${appDir.path}/$_cacheFolder');
    
    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }
    
    // Clean up expired cache files
    await _cleanupExpiredFiles();
  }

  /// Generate a unique cache key for a PDF URL
  static String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get the cache file path for a given URL
  static String _getCacheFilePath(String url) {
    final cacheKey = _generateCacheKey(url);
    return '${_cacheDirectory!.path}/$cacheKey.pdf';
  }

  /// Get the metadata file path for a given URL
  static String _getMetadataFilePath(String url) {
    final cacheKey = _generateCacheKey(url);
    return '${_cacheDirectory!.path}/$cacheKey.meta';
  }

  /// Check if a PDF is cached and not expired
  static Future<bool> isCached(String url) async {
    if (_cacheDirectory == null) await initialize();
    
    final cacheFile = File(_getCacheFilePath(url));
    final metaFile = File(_getMetadataFilePath(url));
    
    if (!await cacheFile.exists() || !await metaFile.exists()) {
      return false;
    }
    
    try {
      final metaContent = await metaFile.readAsString();
      final metadata = json.decode(metaContent);
      final cachedTime = DateTime.parse(metadata['cachedAt']);
      
      // Check if cache is expired
      if (DateTime.now().difference(cachedTime) > _cacheExpiry) {
        await _deleteCacheFile(url);
        return false;
      }
      
      return true;
    } catch (e) {
      // If metadata is corrupted, delete the cache file
      await _deleteCacheFile(url);
      return false;
    }
  }

  /// Get cached PDF file path if available
  static Future<String?> getCachedFilePath(String url) async {
    if (await isCached(url)) {
      return _getCacheFilePath(url);
    }
    return null;
  }

  /// Cache a PDF from URL
  static Future<String?> cachePdf(String url, {Function(double)? onProgress}) async {
    if (_cacheDirectory == null) await initialize();
    
    try {
      // Check if already cached
      if (await isCached(url)) {
        return _getCacheFilePath(url);
      }
      
      // Download the PDF
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final cacheFilePath = _getCacheFilePath(url);
        final metaFilePath = _getMetadataFilePath(url);
        
        // Write PDF file
        final cacheFile = File(cacheFilePath);
        await cacheFile.writeAsBytes(response.bodyBytes);
        
        // Write metadata
        final metadata = {
          'url': url,
          'cachedAt': DateTime.now().toIso8601String(),
          'size': response.bodyBytes.length,
          'contentType': response.headers['content-type'] ?? 'application/pdf',
        };
        
        final metaFile = File(metaFilePath);
        await metaFile.writeAsString(json.encode(metadata));
        
        // Check cache size and cleanup if needed
        await _manageCacheSize();
        
        return cacheFilePath;
      }
    } catch (e) {
      debugPrint('Error caching PDF: $e');
    }
    
    return null;
  }

  /// Delete a specific cache file
  static Future<void> _deleteCacheFile(String url) async {
    try {
      final cacheFile = File(_getCacheFilePath(url));
      final metaFile = File(_getMetadataFilePath(url));
      
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }
      
      if (await metaFile.exists()) {
        await metaFile.delete();
      }
    } catch (e) {
      debugPrint('Error deleting cache file: $e');
    }
  }

  /// Clean up expired cache files
  static Future<void> _cleanupExpiredFiles() async {
    if (_cacheDirectory == null) return;
    
    try {
      final files = await _cacheDirectory!.list().toList();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.meta')) {
          try {
            final metaContent = await file.readAsString();
            final metadata = json.decode(metaContent);
            final cachedTime = DateTime.parse(metadata['cachedAt']);
            
            if (DateTime.now().difference(cachedTime) > _cacheExpiry) {
              final url = metadata['url'];
              await _deleteCacheFile(url);
            }
          } catch (e) {
            // If metadata is corrupted, delete the file
            await file.delete();
            
            // Also delete corresponding PDF file
            final pdfPath = file.path.replaceAll('.meta', '.pdf');
            final pdfFile = File(pdfPath);
            if (await pdfFile.exists()) {
              await pdfFile.delete();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up expired files: $e');
    }
  }

  /// Manage cache size by deleting oldest files if needed
  static Future<void> _manageCacheSize() async {
    if (_cacheDirectory == null) return;
    
    try {
      final files = await _cacheDirectory!.list().toList();
      int totalSize = 0;
      List<Map<String, dynamic>> fileInfos = [];
      
      // Calculate total size and collect file info
      for (final file in files) {
        if (file is File && file.path.endsWith('.pdf')) {
          final stat = await file.stat();
          final metaPath = file.path.replaceAll('.pdf', '.meta');
          final metaFile = File(metaPath);
          
          if (await metaFile.exists()) {
            try {
              final metaContent = await metaFile.readAsString();
              final metadata = json.decode(metaContent);
              
              fileInfos.add({
                'file': file,
                'size': stat.size,
                'cachedAt': DateTime.parse(metadata['cachedAt']),
                'url': metadata['url'],
              });
              
              totalSize += stat.size;
            } catch (e) {
              // If metadata is corrupted, delete both files
              await file.delete();
              if (await metaFile.exists()) {
                await metaFile.delete();
              }
            }
          }
        }
      }
      
      // If cache size exceeds limit, delete oldest files
      if (totalSize > _maxCacheSize) {
        fileInfos.sort((a, b) => a['cachedAt'].compareTo(b['cachedAt']));
        
        for (final fileInfo in fileInfos) {
          if (totalSize <= _maxCacheSize * 0.8) break; // Keep 80% of max size
          
          await _deleteCacheFile(fileInfo['url']);
          totalSize -= (fileInfo['size'] as int);
        }
      }
    } catch (e) {
      debugPrint('Error managing cache size: $e');
    }
  }

  /// Clear all cached PDFs
  static Future<void> clearCache() async {
    if (_cacheDirectory == null) await initialize();
    
    try {
      if (await _cacheDirectory!.exists()) {
        await _cacheDirectory!.delete(recursive: true);
        await _cacheDirectory!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    if (_cacheDirectory == null) await initialize();
    
    try {
      final files = await _cacheDirectory!.list().toList();
      int totalSize = 0;
      int fileCount = 0;
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.pdf')) {
          final stat = await file.stat();
          totalSize += stat.size;
          fileCount++;
        }
      }
      
      return {
        'totalSize': totalSize,
        'fileCount': fileCount,
        'maxSize': _maxCacheSize,
        'usagePercentage': (totalSize / _maxCacheSize * 100).round(),
      };
    } catch (e) {
      return {
        'totalSize': 0,
        'fileCount': 0,
        'maxSize': _maxCacheSize,
        'usagePercentage': 0,
      };
    }
  }
}