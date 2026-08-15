import 'package:flutter/services.dart';

/// Linux desktop screen capture via PipeWire
class LinuxScreenCapture {
  static const _channel = MethodChannel('nex.flutter/screen_capture_linux');

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

  static Future<bool> requestPortalPermission() async {
    final result = await _channel.invokeMethod<bool>('requestPermission');
    return result ?? false;
  }

  static Future<bool> isSupported() async {
    final result = await _channel.invokeMethod<bool>('isSupported');
    return result ?? false;
  }

  /// Set privacy screen state. When enabled, native capture can signal
  /// the controllee to avoid capturing sensitive content.
  /// The actual black overlay for the remote viewer is rendered in the
  /// Flutter session view, not in native capture.
  static bool privacyEnabled = false;

  static Future<void> setPrivacyEnabled(bool enabled) async {
    privacyEnabled = enabled;
    try {
      await _channel.invokeMethod('setPrivacyEnabled', {'enabled': enabled});
    } on PlatformException catch (_) {
      // Fallback: track state locally if native side is unavailable
    }
  }

  static Future<List<Map<String, dynamic>>> enumerateWindows() async {
    final result = await _channel.invokeMethod<List<dynamic>>('enumerateWindows');
    return result?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<int> startWindowCapture(String windowId, int x, int y, int width, int height) async {
    final result = await _channel.invokeMethod<int>('startWindowCapture', {
      'windowId': windowId,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    });
    return result ?? -1;
  }
}
