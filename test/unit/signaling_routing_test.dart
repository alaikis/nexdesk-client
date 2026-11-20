import 'package:flutter_test/flutter_test.dart';
import 'package:nex/core/signaling_service.dart';

/// P0 协商修复依赖的协议层不变量：
/// 1. 信令消息的 `to` 必须是 `<deviceID>:<sessionID>`，否则服务端直接丢弃；
/// 2. 保留字段（type/to/session_id）不能被 payload 覆盖；
/// 3. 协商消息往返后仍能正确分发到 callOffer / callAnswer / ice。
void main() {
  group('SignalingMessage 协商路由', () {
    test('to 字段序列化为 deviceID:sessionID', () {
      final msg = SignalingMessage(
        type: SignalingMessageType.callOffer,
        to: '42:session-abc',
        sessionId: 'session-abc',
        payload: {'sdp': 'v=0', 'sdp_type': 'offer'},
      );

      final json = msg.toJson();

      expect(json['type'], 'callOffer');
      expect(json['to'], '42:session-abc');
      expect(json['session_id'], 'session-abc');
      expect(json['sdp'], 'v=0');
      expect(json['sdp_type'], 'offer');
    });

    test('payload 中的 type 键不会覆盖信令消息类型', () {
      // 回归测试：修复前 payload 的 'type': 'offer' 会把消息类型改成 'offer'，
      // 对端 fromString 解析失败后降级为 error。
      final msg = SignalingMessage(
        type: SignalingMessageType.callOffer,
        to: '1:session-1',
        sessionId: 'session-1',
        payload: {'sdp': 'v=0', 'type': 'offer'},
      );

      final json = msg.toJson();
      expect(json['type'], 'callOffer');

      final restored = SignalingMessage.fromJson(json);
      expect(restored.type, SignalingMessageType.callOffer);
      expect(restored.payload.containsKey('type'), isFalse);
    });

    test('callAnswer 往返不丢失类型', () {
      final original = SignalingMessage(
        type: SignalingMessageType.callAnswer,
        to: '7:session-1',
        sessionId: 'session-1',
        payload: {'sdp': 'v=0', 'sdp_type': 'answer'},
      );

      final restored = SignalingMessage.fromJson(
        Map<String, dynamic>.from(original.toJson()),
      );

      expect(restored.type, SignalingMessageType.callAnswer);
      expect(restored.to, '7:session-1');
      expect(restored.sessionId, 'session-1');
      expect(restored.payload['sdp'], 'v=0');
      expect(restored.payload['sdp_type'], 'answer');
    });

    test('ice 候选往返不丢失', () {
      final original = SignalingMessage(
        type: SignalingMessageType.ice,
        to: '7:session-1',
        sessionId: 'session-1',
        payload: {
          'candidate': 'candidate:1 1 UDP 1 192.168.1.5 50000 typ host',
          'sdpMid': '0',
          'sdpMLineIndex': 0,
        },
      );

      final restored = SignalingMessage.fromJson(
        Map<String, dynamic>.from(original.toJson()),
      );

      expect(restored.type, SignalingMessageType.ice);
      expect(restored.payload['candidate'], contains('typ host'));
      expect(restored.payload['sdpMid'], '0');
    });

    test('callEnd 往返不丢失类型', () {
      final original = SignalingMessage(
        type: SignalingMessageType.callEnd,
        to: '7:session-1',
        sessionId: 'session-1',
        payload: {'reason': 'ended'},
      );

      final restored = SignalingMessage.fromJson(
        Map<String, dynamic>.from(original.toJson()),
      );

      expect(restored.type, SignalingMessageType.callEnd);
      expect(restored.payload['reason'], 'ended');
    });

    test('缺少 to 时不写入 to 键（服务端会丢弃此类消息）', () {
      final msg = SignalingMessage(
        type: SignalingMessageType.callOffer,
        sessionId: 'session-1',
        payload: {'sdp': 'v=0'},
      );

      expect(msg.to, isNull);
      expect(msg.toJson().containsKey('to'), isFalse);
    });

    test('clipboard 不再使用 type 作为 payload 键', () {
      final msg = SignalingMessage(
        type: SignalingMessageType.clipboard,
        sessionId: 'session-1',
        payload: {'content': 'hello', 'content_type': 'text'},
      );

      final restored = SignalingMessage.fromJson(
        Map<String, dynamic>.from(msg.toJson()),
      );

      expect(restored.type, SignalingMessageType.clipboard);
      expect(restored.payload['content'], 'hello');
      expect(restored.payload['content_type'], 'text');
    });
  });

  group('SignalingService 基础行为', () {
    test('未连接时 send 不抛异常', () async {
      final service = SignalingService(
        serverUrl: 'wss://example.invalid',
        token: 'token',
        deviceId: '1',
      );

      expect(service.isConnected, isFalse);
      expect(
        () => service.send(
          SignalingMessage(
            type: SignalingMessageType.callOffer,
            to: '2:session-1',
            sessionId: 'session-1',
            payload: {'sdp': 'v=0'},
          ),
        ),
        returnsNormally,
      );

      await service.disconnect();
    });

    test('messages 是广播流，可多订阅', () async {
      final service = SignalingService(
        serverUrl: 'wss://example.invalid',
        token: 'token',
        deviceId: '1',
      );

      final subA = service.messages.listen((_) {});
      final subB = service.messages.listen((_) {});
      expect(subA, isNotNull);
      expect(subB, isNotNull);

      await subA.cancel();
      await subB.cancel();
      await service.disconnect();
    });
  });
}