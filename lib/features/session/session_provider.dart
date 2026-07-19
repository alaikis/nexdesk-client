import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/api_client.dart';

enum ReconnectionState { connecting, connected, reconnecting, failed }

class Session with ChangeNotifier {
  final String id;
  final String controllerDeviceId;
  final String controlleeDeviceId;
  final String startedAt;
  String? endedAt;
  String status;
  bool relayUsed;

  Session({
    required this.id,
    required this.controllerDeviceId,
    required this.controlleeDeviceId,
    required this.startedAt,
    this.endedAt,
    this.status = 'active',
    this.relayUsed = false,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id']?.toString() ?? const Uuid().v4(),
      controllerDeviceId: json['controller_device_id']?.toString() ?? 'unknown',
      controlleeDeviceId: json['controllee_device_id']?.toString() ?? 'unknown',
      startedAt: json['started_at'] as String? ?? DateTime.now().toIso8601String(),
      endedAt: json['ended_at'] as String?,
      status: json['status'] as String? ?? 'active',
      relayUsed: json['relay_used'] as bool? ?? false,
    );
  }
}

class SessionProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();

  Session? _activeSession;
  List<Session> _history = [];
  ReconnectionState _reconnectionState = ReconnectionState.connected;
  int _reconnectAttempts = 0;

  Session? get activeSession => _activeSession;
  List<Session> get history => List.unmodifiable(_history);
  ReconnectionState get reconnectionState => _reconnectionState;
  int get reconnectAttempts => _reconnectAttempts;
  String? get activeSessionId => _activeSession?.id;

  void setReconnectionState(ReconnectionState state, {int attempts = 0}) {
    _reconnectionState = state;
    _reconnectAttempts = attempts;
    notifyListeners();
  }

  void setActiveSession(Session? session) {
    _activeSession = session;
    notifyListeners();
  }

  Future<Session?> startSession(String controlleeDeviceId) async {
    try {
      final res = await _api.createSession(controlleeDeviceId);
      _activeSession = Session.fromJson(res);
      notifyListeners();
      return _activeSession;
    } on ApiException catch (e) {
      debugPrint('Start session failed: $e');
      return null;
    }
  }

  Future<void> endSession(String sessionId) async {
    try {
      await _api.post('/sessions/$sessionId/end', {});
      _activeSession = null;
      notifyListeners();
    } on ApiException catch (e) {
      debugPrint('End session failed: $e');
    }
  }

  Future<void> loadHistory() async {
    try {
      final res = await _api.get('/sessions');
      final list = res['sessions'] as List<dynamic>? ?? [];
      _history = list.map((s) => Session.fromJson(s as Map<String, dynamic>)).toList();
      notifyListeners();
    } on ApiException catch (e) {
      debugPrint('Load sessions failed: $e');
    }
  }
}
