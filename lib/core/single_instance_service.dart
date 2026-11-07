import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SingleInstanceService {
  static const _channel = MethodChannel('nex.flutter/single_instance');

  static bool _isPrimary = true;

  static Future<bool> ensureSingleInstance() async {
    if (!Platform.isWindows) {
      return true;
    }
    try {
      final result = await _channel.invokeMethod<bool>('ensureSingleInstance');
      _isPrimary = result ?? true;
      return _isPrimary;
    } on PlatformException catch (e) {
      debugPrint('Single instance check failed: $e');
      return true;
    } on MissingPluginException {
      return true;
    }
  }

  static bool get isPrimary => _isPrimary;
}