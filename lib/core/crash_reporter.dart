import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'storage_service.dart';

class CrashReporter {
  static final CrashReporter _instance = CrashReporter._internal();
  factory CrashReporter() => _instance;
  CrashReporter._internal();

  static const MethodChannel _channel = MethodChannel('nex.flutter/crash_reporter');

  Future<void> init() async {
    try {
      await _channel.invokeMethod('init');
    } on MissingPluginException catch (_) {
      // Platform channel not implemented yet; no-op until wired.
    }

    FlutterError.onError = (details) {
      recordError(details.exception, details.stack, context: {'flutter_error': details.library});
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, context: {'platform_error': 'zone'});
      return true;
    };
  }

  Future<void> recordError(Object error, StackTrace? stackTrace, {Map<String, String>? context}) async {
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'error': error.toString(),
      if (stackTrace != null) 'stacktrace': stackTrace.toString(),
      if (context != null) ...context,
    };

    if (kDebugMode) {
      debugPrint('CRASH: ${entry['error']}');
      return;
    }

    try {
      await _channel.invokeMethod('recordError', entry);
    } on MissingPluginException catch (_) {
      await _persistLocally(entry);
    } catch (_) {
      await _persistLocally(entry);
    }
  }

  Future<void> log(String message) async {
    try {
      await _channel.invokeMethod('log', {'message': message});
    } on MissingPluginException catch (_) {
      // no-op
    }
  }

  Future<void> _persistLocally(Map<String, dynamic> entry) async {
    try {
      final existing = await StorageService.getStringList('crash_log');
      existing.add(jsonEncode(entry));
      if (existing.length > 50) {
        existing.removeRange(0, existing.length - 50);
      }
      await StorageService.setStringList('crash_log', existing);
    } catch (_) {
      // Swallow storage errors to avoid infinite loops
    }
  }
}
