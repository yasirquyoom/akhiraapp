import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class AudioCacheService {
  static const String _cacheFolder = 'audio_cache';
  static const int _maxCacheSize = 200 * 1024 * 1024; // 200MB
  static const Duration _cacheExpiry = Duration(days: 7);

  static Directory? _cacheDirectory;

  static Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory('${appDir.path}/$_cacheFolder');
    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }
    await _cleanupExpiredFiles();
  }

  static String _generateCacheKey(String url) {
    final normalized = url.trim().endsWith('?')
        ? url.trim().substring(0, url.trim().length - 1)
        : url.trim();
    final bytes = utf8.encode(normalized);
    final digest = md5.convert(bytes).toString();
    return digest;
  }

  static String _getCacheFilePath(String url) {
    final key = _generateCacheKey(url);
    return '${_cacheDirectory!.path}/$key.bin';
  }

  static String _getMetadataFilePath(String url) {
    final key = _generateCacheKey(url);
    return '${_cacheDirectory!.path}/$key.meta';
  }

  static Future<bool> isCached(String url) async {
    if (_cacheDirectory == null) await initialize();
    final file = File(_getCacheFilePath(url));
    final meta = File(_getMetadataFilePath(url));
    if (!await file.exists() || !await meta.exists()) return false;
    try {
      final metaContent = await meta.readAsString();
      final metadata = json.decode(metaContent);
      final cachedAt = DateTime.parse(metadata['cachedAt']);
      if (DateTime.now().difference(cachedAt) > _cacheExpiry) {
        await _deleteCacheFile(url);
        return false;
      }
      return true;
    } catch (_) {
      await _deleteCacheFile(url);
      return false;
    }
  }

  static Future<String?> cacheAudio(String url, {Function(double)? onProgress}) async {
    if (_cacheDirectory == null) await initialize();
    final targetPath = _getCacheFilePath(url);
    final metaPath = _getMetadataFilePath(url);

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final file = File(targetPath);
        final sink = file.openWrite();
        final contentLength = response.contentLength ?? 0;
        int received = 0;
        await for (final chunk in response.stream) {
          received += chunk.length;
          sink.add(chunk);
          if (onProgress != null && contentLength > 0) {
            onProgress((received / contentLength).clamp(0.0, 1.0));
          }
        }
        await sink.close();

        final meta = {
          'cachedAt': DateTime.now().toIso8601String(),
          'url': url,
          'size': await file.length(),
        };
        await File(metaPath).writeAsString(json.encode(meta));

        await _manageCacheSize();
        return targetPath;
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> getCachedFilePath(String url) async {
    if (await isCached(url)) {
      return _getCacheFilePath(url);
    }
    return null;
  }

  static Future<void> clearCache() async {
    if (_cacheDirectory == null) await initialize();
    await _cacheDirectory!.delete(recursive: true);
    await _cacheDirectory!.create(recursive: true);
  }

  static Future<void> _deleteCacheFile(String url) async {
    final file = File(_getCacheFilePath(url));
    final meta = File(_getMetadataFilePath(url));
    if (await file.exists()) await file.delete();
    if (await meta.exists()) await meta.delete();
  }

  static Future<void> _cleanupExpiredFiles() async {
    if (_cacheDirectory == null) return;
    final entities = _cacheDirectory!.listSync();
    for (final e in entities) {
      if (e is File && e.path.endsWith('.meta')) {
        try {
          final metaContent = await e.readAsString();
          final metadata = json.decode(metaContent);
          final cachedAt = DateTime.parse(metadata['cachedAt']);
          if (DateTime.now().difference(cachedAt) > _cacheExpiry) {
            final base = e.path.substring(0, e.path.length - 5);
            final bin = File('$base');
            if (await bin.exists()) await bin.delete();
            await e.delete();
          }
        } catch (_) {
          // On error, best-effort cleanup
          try {
            final base = e.path.substring(0, e.path.length - 5);
            final bin = File('$base');
            if (await bin.exists()) await bin.delete();
            await e.delete();
          } catch (_) {}
        }
      }
    }
  }

  static Future<void> _manageCacheSize() async {
    if (_cacheDirectory == null) return;
    int totalSize = 0;
    final files = <File>[];
    for (final e in _cacheDirectory!.listSync()) {
      if (e is File && e.path.endsWith('.bin')) {
        files.add(e);
        totalSize += await e.length();
      }
    }
    if (totalSize <= _maxCacheSize) return;
    // Evict oldest until under limit
    files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
    int idx = 0;
    while (totalSize > _maxCacheSize && idx < files.length) {
      try {
        final f = files[idx];
        final size = await f.length();
        await f.delete();
        totalSize -= size;
        final metaPath = '${f.path}.meta';
        final meta = File(metaPath);
        if (await meta.exists()) await meta.delete();
      } catch (_) {}
      idx++;
    }
  }
}