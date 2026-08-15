import 'package:flutter/services.dart';

class WindowsPrintService {
  static const _channel = MethodChannel('nex.flutter/print_windows');

  static Future<List<String>> getPrinters() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getPrinters');
      return result?.cast<String>() ?? [];
    } on PlatformException catch (_) {
      return [];
    }
  }

  static Future<bool> print(String printerName, String filePath, String format) async {
    try {
      final result = await _channel.invokeMethod<bool>('print', {
        'printer_name': printerName,
        'file_path': filePath,
        'format': format,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<bool> printBytes(String printerName, Uint8List data, String fileName, String format) async {
    try {
      final result = await _channel.invokeMethod<bool>('printBytes', {
        'printer_name': printerName,
        'data': data,
        'file_name': fileName,
        'format': format,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
