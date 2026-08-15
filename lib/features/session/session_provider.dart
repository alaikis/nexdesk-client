import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../core/api_client.dart';
import '../../core/storage_service.dart';
import '../../core/signaling_service.dart';

enum ReconnectionState { connecting, connected, reconnecting, failed }

class Session with ChangeNotifier {
  final String id;
  final String controllerDeviceId;
  final String controlleeDeviceId;
  final String startedAt;
  String? endedAt;
  String status;
  bool relayUsed;
  bool privacyEnabled;

  Session({
    required this.id,
    required this.controllerDeviceId,
    required this.controlleeDeviceId,
    required this.startedAt,
    this.endedAt,
    this.status = 'active',
    this.relayUsed = false,
    this.privacyEnabled = false,
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
      privacyEnabled: json['privacy_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'controller_device_id': controllerDeviceId,
      'controllee_device_id': controlleeDeviceId,
      'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      'status': status,
      'relay_used': relayUsed,
      'privacy_enabled': privacyEnabled,
    };
  }
}

class SessionProvider with ChangeNotifier {
  static const _storageKey = 'nex_active_session';
  final ApiClient _api = ApiClient();

  Session? _activeSession;
  List<Session> _history = [];
  ReconnectionState _reconnectionState = ReconnectionState.connected;
  int _reconnectAttempts = 0;
  SignalingService? _signaling;

  Session? get activeSession => _activeSession;
  List<Session> get history => List.unmodifiable(_history);
  ReconnectionState get reconnectionState => _reconnectionState;
  int get reconnectAttempts => _reconnectAttempts;
  String? get activeSessionId => _activeSession?.id;
  bool get privacyEnabled => _activeSession?.privacyEnabled ?? false;

  void setSignalingService(SignalingService? service) {
    _signaling = service;
  }

  Future<void> togglePrivacy(bool enabled) async {
    final sessionId = _activeSession?.id;
    if (sessionId == null) return;

    if (_signaling != null) {
      _signaling!.sendPrivacy(sessionId, enabled);
    }

    try {
      await _api.setSessionPrivacy(sessionId, enabled);
    } on ApiException catch (e) {
      debugPrint('Set privacy failed: $e');
    }

    _activeSession?.privacyEnabled = enabled;
    await _persistSession();
    notifyListeners();
  }

  void setPrivacyEnabled(bool enabled) {
    if (_activeSession?.privacyEnabled != enabled) {
      _activeSession?.privacyEnabled = enabled;
      _persistSession();
      notifyListeners();
    }
  }

  SessionProvider() {
    _loadPersistedSession();
  }

  Future<void> _loadPersistedSession() async {
    try {
      final raw = await StorageService.getString(_storageKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _activeSession = Session.fromJson(json);
      notifyListeners();
    } catch (_) {
      // Ignore corrupt storage
    }
  }

  Future<void> _persistSession() async {
    if (_activeSession == null) {
      await StorageService.delete(_storageKey);
      return;
    }
    try {
      await StorageService.setString(_storageKey, jsonEncode(_activeSession!.toJson()));
    } catch (_) {
      // Swallow storage errors
    }
  }

  void setReconnectionState(ReconnectionState state, {int attempts = 0}) {
    _reconnectionState = state;
    _reconnectAttempts = attempts;
    notifyListeners();
  }

  void setActiveSession(Session? session) {
    _activeSession = session;
    _persistSession();
    notifyListeners();
  }

  Future<Session?> startSession(String controlleeDeviceId) async {
    try {
      final res = await _api.createSession(controlleeDeviceId);
      _activeSession = Session.fromJson(res);
      await _persistSession();
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
      await _persistSession();
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
