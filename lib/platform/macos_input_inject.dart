import 'package:flutter/services.dart';

/// macOS input injection via CGEvent
class MacOSInputInject {
  static const _channel = MethodChannel('nex.flutter/input_inject_macos');

  static Future<void> injectMouseMove(int x, int y, {bool absolute = true}) async {
    await _channel.invokeMethod('injectMouseMove', {
      'x': x,
      'y': y,
      'absolute': absolute,
    });
  }

  static Future<void> injectMouseButton(int button, bool down) async {
    await _channel.invokeMethod('injectMouseButton', {
      'button': button,
      'down': down,
    });
  }

  static Future<void> injectMouseWheel(int delta) async {
    await _channel.invokeMethod('injectMouseWheel', {'delta': delta});
  }

  static Future<void> injectKey(int keyCode, bool down, {bool extended = false}) async {
    await _channel.invokeMethod('injectKey', {
      'keyCode': keyCode,
      'down': down,
      'extended': extended,
    });
  }

  static Future<bool> requestAccessibilityPermission() async {
    final result = await _channel.invokeMethod<bool>('requestAccessibility');
    return result ?? false;
  }
}
