import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';

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

      // Save to gallery using gal package
      final fileName =
          'akhira_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Gal.putImageBytes(bytes, name: fileName);

      return 'Image saved successfully';
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
