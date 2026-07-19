import 'dart:async';
import 'package:flutter/services.dart';

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
  }

  Future<void> recordError(Object error, StackTrace? stackTrace, {Map<String, String>? context}) async {
    try {
      await _channel.invokeMethod('recordError', {
        'error': error.toString(),
        if (stackTrace != null) 'stacktrace': stackTrace.toString(),
        ...?context,
      });
    } on MissingPluginException catch (_) {
      // no-op
    }
  }

  Future<void> log(String message) async {
    try {
      await _channel.invokeMethod('log', {'message': message});
    } on MissingPluginException catch (_) {
      // no-op
    }
  }
}
