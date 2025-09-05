import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ImageDownloadService {
  final Dio _dio = Dio();

  Future<String> downloadImage(String imageUrl) async {
    try {
      // Request storage permission
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        throw Exception('Storage permission denied');
      }

      // Download image
      final response = await _dio.get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data as Uint8List;

      // Save to gallery
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: 'akhira_image_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess'] == true) {
        return result['filePath'] ?? 'Image saved successfully';
      } else {
        throw Exception('Failed to save image to gallery');
      }
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  Future<String> downloadImageToAppDirectory(String imageUrl) async {
    try {
      // Download image
      final response = await _dio.get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data as Uint8List;

      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${directory.path}/$fileName');

      // Write file
      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }
}
