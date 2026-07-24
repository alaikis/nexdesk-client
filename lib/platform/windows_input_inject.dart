import 'package:flutter/services.dart';

/// Windows input injection via SendInput API
class WindowsInputInject {
  static const _channel = MethodChannel('nex.flutter/input_inject_windows');

  /// Inject mouse move (absolute coordinates 0-65535)
  static Future<void> injectMouseMove(int x, int y, {bool absolute = true}) async {
    await _channel.invokeMethod('injectMouseMove', {
      'x': x,
      'y': y,
      'absolute': absolute,
    });
  }

  /// Inject mouse button event
  static Future<void> injectMouseButton(int button, bool down) async {
    await _channel.invokeMethod('injectMouseButton', {
      'button': button, // 0=left, 1=right, 2=middle
      'down': down,
    });
  }

  /// Inject mouse wheel
  static Future<void> injectMouseWheel(int delta) async {
    await _channel.invokeMethod('injectMouseWheel', {'delta': delta});
  }

  /// Inject keyboard key event (USB HID scan code)
  static Future<void> injectKey(int scanCode, bool down, {bool extended = false}) async {
    await _channel.invokeMethod('injectKey', {
      'scanCode': scanCode,
      'down': down,
      'extended': extended,
    });
  }

  /// Inject Unicode character (for text input)
  static Future<void> injectUnicode(String text) async {
    await _channel.invokeMethod('injectUnicode', {'text': text});
  }

  /// Set modifier keys state
  static Future<void> setModifiers({
    bool ctrl = false,
    bool alt = false,
    bool shift = false,
    bool win = false,
  }) async {
    await _channel.invokeMethod('setModifiers', {
      'ctrl': ctrl,
      'alt': alt,
      'shift': shift,
      'win': win,
    });
  }
}
