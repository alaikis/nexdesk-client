import 'package:flutter/services.dart';

/// macOS desktop screen capture via ScreenCaptureKit
class MacOSScreenCapture {
  static const _channel = MethodChannel('nex.flutter/screen_capture_macos');

  static Future<List<Map<String, dynamic>>> enumerateDisplays() async {
    final result = await _channel.invokeMethod<List<dynamic>>('enumerateDisplays');
    return result?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<int> startCapture(int displayIndex) async {
    final result = await _channel.invokeMethod<int>('startCapture', {
      'displayIndex': displayIndex,
    });
    return result ?? -1;
  }

  static Future<void> stopCapture(int textureId) async {
    await _channel.invokeMethod('stopCapture', {'textureId': textureId});
  }

  static Future<bool> requestScreenCapturePermission() async {
    final result = await _channel.invokeMethod<bool>('requestPermission');
    return result ?? false;
  }

  static Future<bool> isSupported() async {
    final result = await _channel.invokeMethod<bool>('isSupported');
    return result ?? false;
  }
}
