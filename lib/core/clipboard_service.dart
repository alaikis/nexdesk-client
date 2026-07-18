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
    return ClipboardEvent(
      id: json['id'] ?? json['id'] as int,
      sessionId: json['session_id'] ?? json['sessionId'] as int,
      deviceId: json['device_id'] ?? json['deviceId'] as int,
      type: ClipboardType.values.firstWhere((t) => t.name == (json['type'] ?? 'text'), orElse: () => ClipboardType.text),
      payload: json['payload'] as String?,
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

  void startWatching(String sessionId, int deviceId, Function(ClipboardEvent) onEvent) {
    // Platform channel required for native clipboard watching
  }

  Future<void> syncText(String sessionId, int deviceId, String text, {bool isOutbound = true}) async {
    await _api.post('/sessions/$sessionId/clipboard', {
      'device_id': deviceId,
      'type': 'text',
      'payload': text,
      'direction': isOutbound ? 'out' : 'in',
    });
  }

  Future<void> copyToRemote(String sessionId, int deviceId) async {
    final data = await Clipboard.getData('text/plain');
    if (data != null) {
      final text = data.text ?? '';
      await syncText(sessionId, deviceId, text, isOutbound: true);
    }
  }

  Future<void> pasteFromRemote(String sessionId, int deviceId, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    await syncText(sessionId, deviceId, text, isOutbound: false);
  }

  Future<List<ClipboardEvent>> getHistory(String sessionId, {int limit = 50}) async {
    final res = await _api.get('/sessions/$sessionId/clipboard');
    final list = res['events'] as List<dynamic>? ?? [];
    return list.map((e) => ClipboardEvent.fromJson(e as Map<String, dynamic>)).toList();
  }
}
