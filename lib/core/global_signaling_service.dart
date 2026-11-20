import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../config/app_config.dart';
import '../features/session/session_provider.dart';
import 'api_client.dart';
import 'secure_storage_service.dart';
import 'signaling_service.dart';
import 'unattended_service.dart';

/// 全局信令监听。
///
/// 与「会话页内的信令」不同：这个连接在 app 启动后就常驻，用于接收
/// `sessionInvite`（会话邀请）。没有它，被控端即使客户端常驻托盘、即使
/// 开了无人值守，也收不到邀请，只能靠人手动打开会话页。
///
/// 收到邀请后：
/// - 本机已开启无人值守 → 直接自动接入（跳过选屏，走 auto=1）
/// - 未开启无人值守 → 弹确认框，由本机用户决定接受或拒绝
class GlobalSignalingService {
  GlobalSignalingService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  SignalingService? _service;
  bool _started = false;
  bool _connecting = false;
  String? _pendingSessionId;

  /// 启动常驻信令。需在登录成功后调用（要 jwt + device_id）。
  Future<void> start() async {
    if (_started || _connecting) return;
    _connecting = true;
    try {
      final token = await SecureStorageService.getString('jwt_token');
      final deviceId = await SecureStorageService.getString('device_id');
      if (token == null || token.isEmpty || deviceId == null || deviceId.isEmpty) {
        debugPrint('GlobalSignaling: skip start, missing token/device_id');
        return;
      }

      final service = SignalingService(
        serverUrl: AppConfig.wsSignalUrl,
        token: token,
        deviceId: deviceId,
      );
      service.messages.listen(_onMessage);
      await service.connect();
      _service = service;
      _started = true;
      debugPrint('GlobalSignaling: started for device $deviceId');
    } catch (e) {
      debugPrint('GlobalSignaling: start failed: $e');
    } finally {
      _connecting = false;
    }
  }

  Future<void> stop() async {
    await _service?.disconnect();
    _service = null;
    _started = false;
  }

  void _onMessage(SignalingMessage msg) {
    if (msg.type != SignalingMessageType.sessionInvite) return;

    final sessionId = msg.sessionId ?? msg.payload['session_id']?.toString();
    if (sessionId == null || sessionId.isEmpty) {
      debugPrint('GlobalSignaling: invite without session_id');
      return;
    }
    if (sessionId == _pendingSessionId) return;
    _pendingSessionId = sessionId;

    unawaited(_handleInvite(sessionId, msg.payload));
  }

  Future<void> _handleInvite(String sessionId, Map<String, dynamic> payload) async {
    final controllerName = payload['controller_name'] as String? ?? '未知设备';
    final deviceId = await SecureStorageService.getString('device_id') ?? '';

    final unattended = deviceId.isEmpty
        ? false
        : await UnattendedService().isEnabled(deviceId);

    if (unattended) {
      debugPrint('GlobalSignaling: unattended enabled, auto accepting $sessionId');
      await _join(sessionId);
      return;
    }

    await _askUser(sessionId, controllerName);
  }

  Future<void> _askUser(String sessionId, String controllerName) async {
    final ctx = NexApp.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      debugPrint('GlobalSignaling: no context to ask user about $sessionId');
      return;
    }

    final accept = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('远程协助请求'),
        content: Text('$controllerName 请求控制本机'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('拒绝'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('接受'),
          ),
        ],
      ),
    );

    if (accept == true) {
      await _join(sessionId);
    }
  }

  Future<void> _join(String sessionId) async {
    final ctx = NexApp.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    try {
      // 取完整 session 以正确判定 controller/controllee 角色。
      final res = await _api.get('/sessions/$sessionId');
      if (ctx.mounted) {
        final provider = ctx.read<SessionProvider>();
        provider.setActiveSession(Session.fromJson(res));
      }
      NexApp.router?.go('/session/$sessionId?auto=1');
    } catch (e) {
      debugPrint('GlobalSignaling: join failed: $e');
      _pendingSessionId = null;
    }
  }
}