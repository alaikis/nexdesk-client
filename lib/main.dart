import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app.dart';
import 'features/auth/auth_provider.dart';
import 'features/devices/device_provider.dart';
import 'features/session/session_provider.dart';
import 'platform/platform_service.dart';
import 'core/crash_reporter.dart';
import 'core/api_client.dart';
import 'core/input_injector_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PlatformService.initPlatform();
  await CrashReporter().init();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1280, 800),
      center: true,
      minimumSize: Size(800, 600),
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      windowManager.show();
      windowManager.focus();
    });
  }

  final auth = AuthProvider();
  await auth.init();

  final deviceProvider = DeviceProvider()..loadDevices();
  final sessionProvider = SessionProvider();

  await _checkForUpdates();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1D1D1F)),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: deviceProvider),
        ChangeNotifierProvider.value(value: sessionProvider),
      ],
      child: const NexApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final inputInjector = InputInjectorService();
    await inputInjector.init(sessionProvider);
    inputInjector.start();
  });
}

Future<void> _checkForUpdates() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final api = ApiClient();
    final platform = Platform.operatingSystem;
    final release = await api.getRelease(platform);
    final latestVersion = release['version'] as String?;
    final updateUrl = release['url'] as String?;
    if (latestVersion == null || updateUrl == null) return;
    if (latestVersion.compareTo(info.version) > 0) {
      debugPrint('Update available: $latestVersion (current: ${info.version})');
    }
  } catch (e) {
    debugPrint('Update check failed: $e');
  }
}
