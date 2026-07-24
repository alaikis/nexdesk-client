import 'package:flutter/services.dart';

/// Linux input injection via uinput/evdev
class LinuxInputInject {
  static const _channel = MethodChannel('nex.flutter/input_inject_linux');

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

  static Future<void> injectKey(int keyCode, bool down) async {
    await _channel.invokeMethod('injectKey', {
      'keyCode': keyCode,
      'down': down,
    });
  }
}
