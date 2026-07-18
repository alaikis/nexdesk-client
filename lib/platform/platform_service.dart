import 'dart:io';

enum AppPlatform { desktop, android, unknown }

class PlatformService {
  static AppPlatform get platform {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return AppPlatform.desktop;
    }
    if (Platform.isAndroid) {
      return AppPlatform.android;
    }
    return AppPlatform.unknown;
  }

  static bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  static Future<void> initPlatform() async {
    if (isDesktop) {
      await _initDesktop();
    } else if (isAndroid) {
      await _initAndroid();
    }
  }

  static Future<void> _initDesktop() async {
    // Desktop-specific initialization
    // window_manager is already initialized in main.dart
  }

  static Future<void> _initAndroid() async {
    // Android-specific initialization
    // Request notification permission for foreground service
    // request notification permission if needed
  }
}
