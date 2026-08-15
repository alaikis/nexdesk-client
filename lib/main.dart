import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app.dart';
import 'l10n/app_localizations.dart';
import 'features/auth/auth_provider.dart';
import 'features/devices/device_provider.dart';
import 'features/session/session_provider.dart';
import 'features/shares/share_provider.dart';
import 'platform/platform_service.dart';
import 'core/crash_reporter.dart';
import 'core/api_client.dart';
import 'core/input_injector_service.dart';
import 'core/update_service.dart';
import 'core/system_tray_service.dart';

class _NexWindowListener extends WindowListener {
  @override
  void onWindowMinimize() {
    SystemTrayService.hide();
  }

  @override
  void onWindowMaximize() {
    SystemTrayService.show();
  }

  @override
  void onWindowRestore() {
    SystemTrayService.show();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PlatformService.initPlatform();
  await CrashReporter().init();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1280, 800),
      center: true,
      minimumSize: Size(900, 600),
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

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (Platform.isWindows) {
      await SystemTrayService.init();
      windowManager.addListener(_NexWindowListener());
    }

    if (UpdateService().updateAvailable && UpdateService().latestUpdate != null) {
      final update = UpdateService().latestUpdate!;
      final ctx = NexApp.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        final l10n = AppLocalizations.of(ctx);
        final info = await PackageInfo.fromPlatform();
        showDialog(
          context: ctx,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            title: Text(l10n?.updateAvailable(info.version, update.version) ?? 'Update available: ${update.version}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n?.updateMessage ?? 'A new version is available. Would you like to download it?'),
                if (update.notes != null && update.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(update.notes!, style: Theme.of(dialogCtx).textTheme.bodyMedium),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(l10n?.later ?? 'Later'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  UpdateService().downloadUpdate();
                },
                child: Text(l10n?.download ?? 'Download'),
              ),
            ],
          ),
        );
      }
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: deviceProvider),
        ChangeNotifierProvider.value(value: sessionProvider),
        ChangeNotifierProvider.value(value: ShareProvider()),
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
