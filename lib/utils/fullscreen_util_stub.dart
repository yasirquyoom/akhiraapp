import 'package:flutter/services.dart';

// Default (non-web) fullscreen helpers
class FullscreenUtil {
  static Future<void> enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  static Future<void> exitFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}