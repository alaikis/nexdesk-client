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
}
