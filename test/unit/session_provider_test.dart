import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/session/session_provider.dart';

void main() {
  group('Session', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'session-1',
        'controller_device_id': 'ctrl-1',
        'controllee_device_id': 'ctrllee-1',
        'started_at': '2026-01-01T00:00:00Z',
        'ended_at': '2026-01-01T01:00:00Z',
        'status': 'ended',
        'relay_used': true,
      };
      final session = Session.fromJson(json);
      expect(session.id, 'session-1');
      expect(session.controllerDeviceId, 'ctrl-1');
      expect(session.controlleeDeviceId, 'ctrllee-1');
      expect(session.startedAt, '2026-01-01T00:00:00Z');
      expect(session.endedAt, '2026-01-01T01:00:00Z');
      expect(session.status, 'ended');
      expect(session.relayUsed, true);
    });

    test('fromJson applies defaults for missing fields', () {
      final session = Session.fromJson({});
      expect(session.id, isA<String>());
      expect(session.status, 'active');
      expect(session.relayUsed, false);
    });
  });

  group('SessionProvider', () {
    test('starts with no active session', () {
      final provider = SessionProvider();
      expect(provider.activeSession, isNull);
      expect(provider.activeSessionId, isNull);
      expect(provider.history, isEmpty);
    });
  });
}
