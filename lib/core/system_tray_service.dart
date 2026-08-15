import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SystemTrayService {
  static const _channel = MethodChannel('nex.flutter/system_tray_windows');

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _channel.invokeMethod('init');
      _initialized = true;
    } on PlatformException catch (e) {
      debugPrint('System tray init failed: $e');
    }
  }

  static Future<void> show() async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('show');
    } on PlatformException catch (e) {
      debugPrint('System tray show failed: $e');
    }
  }

  static Future<void> hide() async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('hide');
    } on PlatformException catch (e) {
      debugPrint('System tray hide failed: $e');
    }
  }

  static Future<void> toggle() async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('toggle');
    } on PlatformException catch (e) {
      debugPrint('System tray toggle failed: $e');
    }
  }

  static Future<void> destroy() async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('destroy');
      _initialized = false;
    } on PlatformException catch (e) {
      debugPrint('System tray destroy failed: $e');
    }
  }
}
