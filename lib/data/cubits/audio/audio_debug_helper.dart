import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AudioDebugHelper {
  static Future<void> testAudioPlayback() async {
    debugPrint('=== AUDIO PLAYBACK DEBUG TEST ===');

    final audioPlayer = AudioPlayer();

    try {
      // Test 1: Check if audio player is working with a simple URL
      debugPrint('Test 1: Testing with simple audio URL...');
      const testUrl =
          'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';

      await audioPlayer
          .play(UrlSource(testUrl))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException(
                'Test timeout',
                const Duration(seconds: 10),
              );
            },
          );

      debugPrint('Test 1 SUCCESS: Simple URL played');
      await audioPlayer.stop();
    } catch (e) {
      debugPrint('Test 1 FAILED: $e');
    }

    // Test 2: Check Supabase URL accessibility
    try {
      const supabaseUrl =
          'https://qkdeafwgtpqsglxyxycd.supabase.co/storage/v1/object/public/ebook-files/books/6ce220fc-7569-4f67-99bc-9c5617af0c1a/content/83d87a8e-7fdb-41f0-8bb8-0695aa8426f9.wav?';
      debugPrint('Test 2: Testing Supabase URL accessibility...');

      final dio = Dio();
      final response = await dio
          .head(supabaseUrl)
          .timeout(const Duration(seconds: 10));
      debugPrint(
        'Test 2 SUCCESS: Supabase URL accessible - Status: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Test 2 FAILED: Supabase URL not accessible - $e');
    }

    // Test 3: Try playing Supabase URL directly
    try {
      const supabaseUrl =
          'https://qkdeafwgtpqsglxyxycd.supabase.co/storage/v1/object/public/ebook-files/books/6ce220fc-7569-4f67-99bc-9c5617af0c1a/content/83d87a8e-7fdb-41f0-8bb8-0695aa8426f9.wav?';
      debugPrint('Test 3: Testing Supabase URL playback...');

      await audioPlayer
          .play(UrlSource(supabaseUrl))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(
                'Supabase playback timeout',
                const Duration(seconds: 15),
              );
            },
          );

      debugPrint('Test 3 SUCCESS: Supabase URL played');
      await audioPlayer.stop();
    } catch (e) {
      debugPrint('Test 3 FAILED: Supabase URL playback failed - $e');
    }

    await audioPlayer.dispose();
    debugPrint('=== END AUDIO PLAYBACK DEBUG TEST ===');
  }
}
