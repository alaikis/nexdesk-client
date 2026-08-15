import 'package:flutter/services.dart';

class WindowsCameraService {
  static const _channel = MethodChannel('nex.flutter/camera_windows');

  static Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<int> startCapture() async {
    final result = await _channel.invokeMethod<int>('startCapture');
    return result ?? -1;
  }

  static Future<void> stopCapture(int textureId) async {
    await _channel.invokeMethod('stopCapture', {'textureId': textureId});
  }

  static Future<bool> isSupported() async {
    final result = await _channel.invokeMethod<bool>('isSupported');
    return result ?? false;
  }
}
