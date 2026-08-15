import 'package:flutter/services.dart';

class MacOSTerminalService {
  static const _channel = MethodChannel('nex.flutter/terminal_macos');

  static Future<bool> start(String shell) async {
    try {
      final result = await _channel.invokeMethod<bool>('start', {'shell': shell});
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  static Future<void> write(String data) async {
    await _channel.invokeMethod('write', {'data': data});
  }

  static Future<void> resize(int columns, int rows) async {
    await _channel.invokeMethod('resize', {'columns': columns, 'rows': rows});
  }
}
