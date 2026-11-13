import 'dart:async';
import 'package:flutter/services.dart';
import 'api_client.dart';

enum ClipboardType { text, image, file }

class ClipboardEvent {
  final int id;
  final int sessionId;
  final int deviceId;
  final ClipboardType type;
  final String? payload;
  final String direction;
  final DateTime createdAt;

  ClipboardEvent({
    required this.id,
    required this.sessionId,
    required this.deviceId,
    required this.type,
    this.payload,
    required this.direction,
    required this.createdAt,
  });

  factory ClipboardEvent.fromJson(Map<String, dynamic> json) {
    final rawDeviceId = json['device_id'] ?? json['deviceId'];
    final deviceId = rawDeviceId is int ? rawDeviceId : int.tryParse(rawDeviceId.toString()) ?? 0;
    return ClipboardEvent(
      id: (json['id'] ?? 0) as int,
      sessionId: (json['session_id'] ?? json['sessionId'] ?? 0) as int,
      deviceId: deviceId,
      type: ClipboardType.values.firstWhere((t) => t.name == (json['type'] ?? 'text'), orElse: () => ClipboardType.text),
      payload: json['content'] as String? ?? json['payload'] as String?,
      direction: json['direction'] as String? ?? 'in',
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ClipboardService {
  static final ClipboardService _instance = ClipboardService._internal();
  factory ClipboardService() => _instance;
  ClipboardService._internal();

  final ApiClient _api = ApiClient();
  Timer? _watchTimer;
  String? _lastText;
  String? _sessionId;

  /// Real-time sender provided by the signaling service. When set, local
  /// clipboard changes are pushed to the session partner over the WebSocket
  /// instead of relying solely on HTTP polling.
  void Function(String sessionId, String text)? sendClipboard;

  void startWatching(String sessionId, int deviceId, Function(ClipboardEvent) onEvent) {
    _sessionId = sessionId;
    _watchTimer?.cancel();
    // Seed _lastText with the current clipboard so pre-existing content is not
    // echoed to the partner when watching starts.
    Clipboard.getData('text/plain').then((data) {
      _lastText = data?.text ?? '';
    });
    _watchTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text ?? '';
      if (text.isEmpty || text == _lastText) return;
      _lastText = text;
      // Persist to history via HTTP so the clipboard log stays complete.
      try {
        await _api.post('/sessions/$sessionId/clipboard', {
          'content': text,
          'type': 'text',
        });
      } catch (_) {
        // history persistence is best-effort
      }
      // Push to the partner in real time when a signaling link is available.
      final sender = sendClipboard;
      if (sender != null && _sessionId != null) {
        sender(_sessionId!, text);
      }
      onEvent(ClipboardEvent(
        id: 0,
        sessionId: int.tryParse(sessionId) ?? 0,
        deviceId: deviceId,
        type: ClipboardType.text,
        payload: text,
        direction: 'out',
        createdAt: DateTime.now(),
      ));
    });
  }

  void stopWatching() {
    _watchTimer?.cancel();
    _watchTimer = null;
    _lastText = null;
    _sessionId = null;
  }

  /// Apply a clipboard update received from the session partner over the
  /// WebSocket. Updates _lastText first so the local watch timer does not echo
  /// the value back to the sender.
  Future<void> receiveRemote(String text) async {
    if (text.isEmpty || text == _lastText) return;
    _lastText = text;
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> syncText(String sessionId, int deviceId, String text, {bool isOutbound = true}) async {
    await _api.post('/sessions/$sessionId/clipboard', {
      'content': text,
      'type': 'text',
    });
  }

  Future<void> copyToRemote(String sessionId, int deviceId) async {
    final data = await Clipboard.getData('text/plain');
    if (data != null) {
      final text = data.text ?? '';
      await syncText(sessionId, deviceId, text, isOutbound: true);
      final sender = sendClipboard;
      if (sender != null && _sessionId != null) {
        sender(_sessionId!, text);
      }
    }
  }

  Future<void> pasteFromRemote(String sessionId, int deviceId, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    await syncText(sessionId, deviceId, text, isOutbound: false);
  }

  Future<List<ClipboardEvent>> getHistory(String sessionId, {int limit = 50}) async {
    final res = await _api.get('/sessions/$sessionId/clipboard');
    final list = res['clipboard'] as List<dynamic>? ?? [];
    return list.map((e) => ClipboardEvent.fromJson(e as Map<String, dynamic>)).toList();
  }
}