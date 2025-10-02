// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

// Web-specific fullscreen helpers
class FullscreenUtil {
  static Future<void> enterFullscreen() async {
    try {
      (html.document.documentElement ?? html.document.body)?.requestFullscreen();
    } catch (_) {
      // Silently ignore as some browsers block without user gesture
    }
  }

  static Future<void> exitFullscreen() async {
    try {
      html.document.exitFullscreen();
    } catch (_) {
      // Ignore failures
    }
  }
}