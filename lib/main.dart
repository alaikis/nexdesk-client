import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'features/auth/auth_provider.dart';
import 'features/devices/device_provider.dart';
import 'features/session/session_provider.dart';
import 'platform/platform_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PlatformService.initPlatform();

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => DeviceProvider()..loadDevices()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: const NexApp(),
    ),
  );
}
