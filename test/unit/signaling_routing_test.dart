import 'package:flutter_test/flutter_test.dart';
import 'package:nex/core/signaling_service.dart';

/// 客户端 <-> 服务端信令线格式契约。
///
/// 服务端 `internal/ws.Message` 定义为：
///   type / to / session_id / seq / payload(json.RawMessage)
/// 业务数据放在**嵌套的 payload** 里。客户端必须与之保持一致，否则：
/// - 客户端发扁平 payload → 服务端 Message.Payload = nil → SDP 丢失
/// - 服务端发嵌套 payload → 客户端读顶层拿不到 sdp
void main() {
  group('信令线格式（与服务端 ws.Message 对齐）', () {
    test('toJson 把业务数据放进嵌套 payload', () {
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
      expect(json['payload'], isA<Map>());
      expect((json['payload'] as Map)['sdp'], 'v=0');
      // 顶层不应再出现 sdp
      expect(json.containsKey('sdp'), isFalse);
    });

    test('模拟服务端转发：嵌套 payload 能被正确解析', () {
      // 服务端 hub 转发的形态
      final wire = <String, dynamic>{
        'type': 'callOffer',
        'session_id': '123',
        'payload': {
          'sdp': 'v=0\r\na=group:BUNDLE 0',
          'sdp_type': 'offer',
          'from': '7',
        },
      };

      final msg = SignalingMessage.fromJson(wire);

      expect(msg.type, SignalingMessageType.callOffer);
      expect(msg.sessionId, '123');
      expect(msg.payload['sdp'], contains('a=group:BUNDLE 0'));
      expect(msg.payload['sdp_type'], 'offer');
      expect(msg.payload['from'], '7');
    });

    test('服务端 payload 为字符串 JSON 时也能解析', () {
      final wire = <String, dynamic>{
        'type': 'callAnswer',
        'session_id': '9',
        'payload': '{"sdp":"v=0","sdp_type":"answer"}',
      };

      final msg = SignalingMessage.fromJson(wire);

      expect(msg.type, SignalingMessageType.callAnswer);
      expect(msg.payload['sdp'], 'v=0');
    });

    test('无 payload 时不产生异常', () {
      final wire = <String, dynamic>{'type': 'callEnd', 'session_id': '1'};
      final msg = SignalingMessage.fromJson(wire);
      expect(msg.type, SignalingMessageType.callEnd);
      expect(msg.payload, isEmpty);
    });

    test('兼容扁平格式（旧客户端）', () {
      final wire = <String, dynamic>{
        'type': 'ice',
        'to': '7:1',
        'session_id': '1',
        'candidate': 'candidate:1 1 UDP 1 10.0.0.2 5000 typ host',
      };

      final msg = SignalingMessage.fromJson(wire);

      expect(msg.type, SignalingMessageType.ice);
      expect(msg.payload['candidate'], contains('typ host'));
    });

    test('完整往返：client -> wire -> client 保持语义', () {
      final original = SignalingMessage(
        type: SignalingMessageType.callAnswer,
        to: '7:session-1',
        sessionId: 'session-1',
        payload: {'sdp': 'v=0', 'sdp_type': 'answer'},
      );

      final restored = SignalingMessage.fromJson(original.toJson());

      expect(restored.type, SignalingMessageType.callAnswer);
      expect(restored.to, '7:session-1');
      expect(restored.sessionId, 'session-1');
      expect(restored.payload['sdp'], 'v=0');
      expect(restored.payload['sdp_type'], 'answer');
    });

    test('保留字段不被 payload 覆盖（type 仍是消息类型）', () {
      final msg = SignalingMessage(
        type: SignalingMessageType.callOffer,
        to: '1:1',
        sessionId: '1',
        payload: {'sdp': 'v=0', 'sdp_type': 'offer'},
      );

      final json = msg.toJson();
      expect(json['type'], 'callOffer');

      final restored = SignalingMessage.fromJson(json);
      expect(restored.type, SignalingMessageType.callOffer);
      expect(restored.payload['sdp_type'], 'offer');
    });

    test('空 payload 不写 payload 键', () {
      final msg = SignalingMessage(type: SignalingMessageType.ping);
      expect(msg.toJson().containsKey('payload'), isFalse);
    });
  });

  group('信令目标地址', () {
    test('to 必须是 deviceID:sessionID（服务端要求）', () {
      final msg = SignalingMessage(
        type: SignalingMessageType.callOffer,
        to: '42:7',
        sessionId: '7',
        payload: {'sdp': 'v=0'},
      );
      final json = msg.toJson();
      expect(json['to'], '42:7');
      expect((json['to'] as String).split(':').first, '42');
    });

    test('未设置 to 时不写 to 键（服务端会丢弃该消息）', () {
      final msg = SignalingMessage(
        type: SignalingMessageType.callOffer,
        sessionId: '7',
        payload: {'sdp': 'v=0'},
      );
      expect(msg.toJson().containsKey('to'), isFalse);
    });
  });
}