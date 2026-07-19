import 'dart:async';
import 'package:flutter/services.dart';

class ScreenCaptureService {
  static const MethodChannel _channel = MethodChannel('nex.flutter/screen_capture');

  static Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod('requestPermission') ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<void> startService() async {
    try {
      await _channel.invokeMethod('startService');
    } on PlatformException catch (_) {
      // no-op
    }
  }

  static Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
    } on PlatformException catch (_) {
      // no-op
    }
  }
}
