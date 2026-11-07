import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

class SystemTrayService {
  static const _channel = MethodChannel('nex.flutter/system_tray_windows');

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _channel.invokeMethod('init');
      _channel.setMethodCallHandler(_handleMethodCall);
      _initialized = true;
    } on PlatformException catch (e) {
      debugPrint('System tray init failed: $e');
    }
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'tray_click':
      case 'tray_double_click':
        await showWindow();
        break;
      case 'tray_restore':
        await showWindow();
        break;
      case 'tray_quit':
        await destroy();
        await windowManager.destroy();
        break;
    }
  }

  static Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setSkipTaskbar(false);
  }

  static Future<void> hideWindow() async {
    await windowManager.hide();
    await windowManager.setSkipTaskbar(true);
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
