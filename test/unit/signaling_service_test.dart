import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/signaling_service.dart';

void main() {
  group('SignalingMessage', () {
    test('serializes and deserializes round-trip', () {
      final original = SignalingMessage(
        type: SignalingMessageType.callOffer,
        to: 'device-123',
        sessionId: 'session-456',
        payload: {'sdp': 'fake-sdp'},
      );
      final json = original.toJson();
      final restored = SignalingMessage.fromJson(json);
      expect(restored.type, SignalingMessageType.callOffer);
      expect(restored.to, 'device-123');
      expect(restored.sessionId, 'session-456');
      expect(restored.payload, {'sdp': 'fake-sdp'});
    });

    test('fromString maps known types', () {
      expect(SignalingMessageType.fromString('hello'), SignalingMessageType.hello);
      expect(SignalingMessageType.fromString('callOffer'), SignalingMessageType.callOffer);
      expect(SignalingMessageType.fromString('unknown'), SignalingMessageType.error);
    });

    test('toJson omits null fields', () {
      final msg = SignalingMessage(type: SignalingMessageType.ping);
      final json = msg.toJson();
      expect(json.containsKey('to'), isFalse);
      expect(json.containsKey('session_id'), isFalse);
      expect(json['type'], 'ping');
    });
  });
}
