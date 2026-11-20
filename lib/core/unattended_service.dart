import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// 无人值守访问。
///
/// 分两部分：
/// 1. **云端授权**（服务端 `/devices/unattended`）：记录哪些设备允许无人值守、
///    以及 auto_start / keep_alive 偏好。
/// 2. **本机自启动**（各平台原生）：让客户端在登录后常驻，这样被控端无需有人
///    点击即可接入会话。
///
/// 注意：这里只负责「常驻 + 授权」。「被控端收到会话后自动开始推流」需要
/// 全局信令监听，属于后续阶段，本类不负责。
class UnattendedService {
  UnattendedService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  /// Windows 自启动注册表项名。
  static const _windowsRunKey = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const _windowsValueName = 'NEX';

  /// 判断本机是否已开启无人值守（以云端记录为准）。
  Future<bool> isEnabled(String deviceId) async {
    try {
      final items = await _api.listUnattendedDevices();
      return items.any((e) => e is Map && e['device_id'].toString() == deviceId);
    } on ApiException catch (e) {
      debugPrint('list unattended devices failed: $e');
      return false;
    }
  }

  /// 开启无人值守：先写云端授权，再按需配置本机自启动。
  Future<void> enable({
    required String deviceId,
    bool autoStart = true,
    bool keepAlive = true,
  }) async {
    await _api.enableUnattendedAccess(
      deviceId: deviceId,
      autoStart: autoStart,
      keepAlive: keepAlive,
    );
    if (autoStart) {
      await setAutoStart(true);
    }
  }

  /// 关闭无人值守。
  Future<void> disable(String deviceId, {bool clearAutoStart = true}) async {
    await _api.disableUnattendedAccess(deviceId);
    if (clearAutoStart) {
      await setAutoStart(false);
    }
  }

  /// 配置本机开机自启动。当前用户级配置，无需管理员权限。
  Future<bool> setAutoStart(bool enabled) async {
    if (kIsWeb) return false;
    try {
      if (Platform.isWindows) {
        return await _setWindowsAutoStart(enabled);
      }
      if (Platform.isMacOS) {
        return await _setMacAutoStart(enabled);
      }
      if (Platform.isLinux) {
        return await _setLinuxAutoStart(enabled);
      }
    } catch (e) {
      debugPrint('setAutoStart($enabled) failed: $e');
    }
    return false;
  }

  /// 查询本机自启动是否已配置。
  Future<bool> isAutoStartEnabled() async {
    if (kIsWeb) return false;
    try {
      if (Platform.isWindows) {
        final r = await Process.run('reg', ['query', _windowsRunKey, '/v', _windowsValueName]);
        return r.exitCode == 0;
      }
      if (Platform.isMacOS) {
        return File(_macPlistPath).existsSync();
      }
      if (Platform.isLinux) {
        return File(_linuxAutostartPath).existsSync();
      }
    } catch (e) {
      debugPrint('isAutoStartEnabled failed: $e');
    }
    return false;
  }

  Future<bool> _setWindowsAutoStart(bool enabled) async {
    final args = <String>[
      if (enabled) 'add' else 'delete',
      _windowsRunKey,
      '/v',
      _windowsValueName,
      '/f',
    ];
    if (enabled) {
      final exe = Platform.resolvedExecutable;
      args.addAll(['/t', 'REG_SZ', '/d', '"$exe"']);
    }
    final r = await Process.run('reg', args);
    if (r.exitCode != 0) {
      debugPrint('reg ${args.join(' ')} failed: ${r.stderr}');
    }
    return r.exitCode == 0;
  }

  static String get _macPlistPath {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/Library/LaunchAgents/com.nex.client.plist';
  }

  Future<bool> _setMacAutoStart(bool enabled) async {
    final file = File(_macPlistPath);
    if (!enabled) {
      if (await file.exists()) await file.delete();
      return true;
    }
    await file.parent.create(recursive: true);
    final exe = Platform.resolvedExecutable;
    final plist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.nex.client</string>
  <key>ProgramArguments</key>
  <array>
    <string>$exe</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
''';
    await file.writeAsString(plist);
    return true;
  }

  static String get _linuxAutostartPath {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.config/autostart/nex.desktop';
  }

  Future<bool> _setLinuxAutoStart(bool enabled) async {
    final file = File(_linuxAutostartPath);
    if (!enabled) {
      if (await file.exists()) await file.delete();
      return true;
    }
    await file.parent.create(recursive: true);
    final exe = Platform.resolvedExecutable;
    await file.writeAsString('''[Desktop Entry]
Type=Application
Name=NEX
Exec=$exe
Terminal=false
X-GNOME-Autostart-enabled=true
''');
    return true;
  }
}