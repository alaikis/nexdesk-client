import 'storage_service.dart';

import 'secure_storage_service.dart';

/// 无人值守访问服务
/// 注意：完整实现需要各平台原生代码（Windows 服务/注册表、macOS LaunchAgent、Linux systemd）
/// 此处提供基础架构和设置 UI 接入
class UnattendedService {
  static const _enabledKey = 'unattended_enabled';
  static const _passwordKey = 'unattended_password';

  Future<bool> get isEnabled async {
    final v = await StorageService.getString(_enabledKey);
    return v == 'true';
  }

  Future<void> setEnabled(bool enabled) async {
    await StorageService.setString(_enabledKey, enabled.toString());
  }

  Future<String?> getPassword() async {
    return await SecureStorageService.getString(_passwordKey);
  }

  Future<void> setPassword(String password) async {
    await SecureStorageService.setString(_passwordKey, password);
  }

  /// 注册系统服务（需在各平台原生代码中实现）
  Future<bool> installService() async {
    // Windows: 注册表 Run 键 + sc.exe 服务
    // macOS: LaunchAgent plist
    // Linux: systemd service
    // 此处返回 true 表示设置已保存，实际服务注册需原生实现
    return true;
  }

  /// 移除系统服务
  Future<void> uninstallService() async {
    // 清理各平台服务注册
  }
}
