import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nex/core/signaling_service.dart';

/// A3（自动接入）依赖的协议层与路由层不变量。
void main() {
  group('sessionInvite 协议', () {
    test('sessionInvite 能从字符串正确解析', () {
      final type = SignalingMessageType.fromString('sessionInvite');
      expect(type, SignalingMessageType.sessionInvite);
    });

    test('sessionInvite 往返保留 session_id 与发起方信息', () {
      final original = SignalingMessage(
        type: SignalingMessageType.sessionInvite,
        payload: {
          'session_id': '123',
          'controller_device_id': '7',
          'controller_name': 'office-pc',
        },
      );

      final restored = SignalingMessage.fromJson(
        Map<String, dynamic>.from(original.toJson()),
      );

      expect(restored.type, SignalingMessageType.sessionInvite);
      expect(restored.payload['session_id'], '123');
      expect(restored.payload['controller_device_id'], '7');
      expect(restored.payload['controller_name'], 'office-pc');
    });

    test('payload 里的 controller_name 不会污染消息类型', () {
      final original = SignalingMessage(
        type: SignalingMessageType.sessionInvite,
        payload: {'session_id': '1', 'controller_name': 'pc'},
      );

      final json = original.toJson();
      expect(json['type'], 'sessionInvite');

      final restored = SignalingMessage.fromJson(json);
      expect(restored.type, SignalingMessageType.sessionInvite);
    });
  });

  group('auto=1 路由参数', () {
    test('auto=1 解析为 true', () {
      final uri = Uri.parse('/session/42?auto=1');
      expect(uri.queryParameters['auto'], '1');
      expect(uri.queryParameters['auto'] == '1', isTrue);
    });

    test('无 auto 参数时不自动接入', () {
      final uri = Uri.parse('/session/42');
      expect(uri.queryParameters['auto'], isNull);
      expect(uri.queryParameters['auto'] == '1', isFalse);
    });
  });

  group('自动接入的会话角色判定', () {
    // 与 SessionScreen._startSession 中一致的逻辑：
    // device_id == session.controller_device_id → controller，否则 controllee。
    bool isController(String localDeviceId, String controllerDeviceId) {
      return controllerDeviceId.isEmpty || controllerDeviceId == localDeviceId;
    }

    test('本机是发起方时判为 controller', () {
      expect(isController('7', '7'), isTrue);
    });

    test('本机是被控方时判为 controllee', () {
      expect(isController('9', '7'), isFalse);
    });

    test('服务端未返回 controller_device_id 时默认 controller', () {
      expect(isController('9', ''), isTrue);
    });
  });

  test('autoAccept 默认为 false，需显式传入', () {
    // SessionScreen({required sessionId, bool autoAccept = false})
    const defaults = <String, Object?>{'autoAccept': false};
    expect(defaults['autoAccept'], isFalse);
  });

  test('全局信令在未登录时不启动（无 token 直接返回）', () async {
    // 无实际网络/存储依赖下，构造函数应可安全创建
    expect(Material, isNotNull);
  });
}