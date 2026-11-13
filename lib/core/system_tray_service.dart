import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
      case 'tray_restore':
        await showWindow();
        break;
      case 'tray_hide':
        await hideWindow();
        break;
      case 'tray_open_control_center':
        await showWindow();
        _navigateTo('/');
        break;
      case 'tray_about':
        await showWindow();
        _showAbout();
        break;
      case 'tray_quit':
        await destroy();
        await windowManager.destroy();
        break;
    }
  }

  static void _navigateTo(String path) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use GoRouter's global navigator when available.
      try {
        final router = GoRouter.of(_rootContext!);
        router.go(path);
      } catch (_) {
        // Fallback: rely on the app's default route.
      }
    });
  }

  static BuildContext? _rootContext;
  static void setRootContext(BuildContext context) => _rootContext = context;

  static Future<void> _showAbout() async {
    try {
      final info = await PackageInfo.fromPlatform();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _rootContext;
        if (context == null) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('LitchiViewer'),
            content: Text(
              '${info.appName} ${info.version} (build ${info.buildNumber})\n'
              'Secure WebRTC remote desktop control.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    } catch (e) {
      debugPrint('Show about failed: $e');
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
