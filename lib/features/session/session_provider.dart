import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/api_client.dart';
import '../../core/storage_service.dart';
import '../../core/signaling_service.dart';
import '../../core/quality_service.dart';
import '../../widgets/floating_toolbar.dart';

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
  bool whiteboardEnabled;

  Session({
    required this.id,
    required this.controllerDeviceId,
    required this.controlleeDeviceId,
    required this.startedAt,
    this.endedAt,
    this.status = 'active',
    this.relayUsed = false,
    this.privacyEnabled = false,
    this.whiteboardEnabled = false,
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
      whiteboardEnabled: json['whiteboard_enabled'] as bool? ?? false,
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
      'whiteboard_enabled': whiteboardEnabled,
    };
  }
}

class SessionProvider with ChangeNotifier {
  static const _storageKey = 'nex_active_session';
  static const _toolbarModeKey = 'nex_toolbar_mode';
  static const _toolbarPosKey = 'nex_toolbar_pos';
  final ApiClient _api = ApiClient();

  Session? _activeSession;
  List<Session> _history = [];
  ReconnectionState _reconnectionState = ReconnectionState.connected;
  int _reconnectAttempts = 0;
  SignalingService? _signaling;
  ToolbarMode _toolbarMode = ToolbarMode.floating;
  Offset _toolbarPosition = const Offset(20, 300);
  final List<_FileUpload> _uploads = [];
  String? _lastUploadError;

  Session? get activeSession => _activeSession;
  List<Session> get history => List.unmodifiable(_history);
  ReconnectionState get reconnectionState => _reconnectionState;
  int get reconnectAttempts => _reconnectAttempts;
  String? get activeSessionId => _activeSession?.id;
  bool get privacyEnabled => _activeSession?.privacyEnabled ?? false;
  bool get whiteboardEnabled => _activeSession?.whiteboardEnabled ?? false;
  ToolbarMode get toolbarMode => _toolbarMode;
  Offset get toolbarPosition => _toolbarPosition;
  List<_FileUpload> get uploads => List.unmodifiable(_uploads);
  String? get lastUploadError => _lastUploadError;

  void setSignalingService(SignalingService? service) {
    _signaling = service;
  }

  Future<void> setToolbarMode(ToolbarMode mode) async {
    _toolbarMode = mode;
    await _persistToolbarMode();
    notifyListeners();
  }

  Future<void> setToolbarPosition(Offset position) async {
    _toolbarPosition = position;
    await _persistToolbarPosition();
    notifyListeners();
  }

  Future<void> toggleToolbarMode() async {
    final newMode = _toolbarMode == ToolbarMode.floating ? ToolbarMode.classic : ToolbarMode.floating;
    await setToolbarMode(newMode);
  }

  Future<void> _loadToolbarState() async {
    try {
      final modeRaw = await StorageService.getString(_toolbarModeKey);
      if (modeRaw == 'classic') {
        _toolbarMode = ToolbarMode.classic;
      }
      final posRaw = await StorageService.getString(_toolbarPosKey);
      if (posRaw != null) {
        final parts = posRaw.split(',');
        if (parts.length == 2) {
          final dx = double.tryParse(parts[0]);
          final dy = double.tryParse(parts[1]);
          if (dx != null && dy != null) {
            _toolbarPosition = Offset(dx, dy);
          }
        }
      }
    } catch (_) {
      // Ignore corrupt storage
    }
  }

  Future<void> _persistToolbarMode() async {
    try {
      await StorageService.setString(_toolbarModeKey, _toolbarMode == ToolbarMode.floating ? 'floating' : 'classic');
    } catch (_) {
      // Swallow storage errors
    }
  }

  Future<void> _persistToolbarPosition() async {
    try {
      await StorageService.setString(_toolbarPosKey, '${_toolbarPosition.dx},${_toolbarPosition.dy}');
    } catch (_) {
      // Swallow storage errors
    }
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

  QualityPreset _qualityPreset = QualityPreset.hd;

  QualityPreset get qualityPreset => _qualityPreset;

  Future<void> setQualityPreset(QualityPreset preset) async {
    _qualityPreset = preset;
    final sessionId = _activeSession?.id;
    if (sessionId != null && _signaling != null) {
      _signaling!.sendQualityPreset(sessionId, preset);
    }
    notifyListeners();
  }

  Map<String, dynamic> getQualityConstraints() {
    final config = QualityProfileConfig.presetValues[_qualityPreset] ?? QualityProfileConfig.hd;
    return {
      'video': {
        'width': {'ideal': config.width},
        'height': {'ideal': config.height},
        'frameRate': {'ideal': config.fps},
      },
    };
  }

  Future<void> toggleWhiteboard(bool enabled) async {
    _activeSession?.whiteboardEnabled = enabled;
    await _persistSession();
    notifyListeners();
  }

  SessionProvider() {
    _loadPersistedSession();
    _loadToolbarState();
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

  Future<void> sendFile(String filePath) async {
    final sessionId = _activeSession?.id;
    if (sessionId == null) return;
    final file = File(filePath);
    if (!await file.exists()) {
      _lastUploadError = 'File not found';
      notifyListeners();
      return;
    }
    final upload = _FileUpload(
      id: const Uuid().v4(),
      filePath: filePath,
      fileName: file.path.split(Platform.pathSeparator).last,
      size: await file.length(),
      progress: 0.0,
      status: _UploadStatus.uploading,
    );
    _uploads.add(upload);
    _lastUploadError = null;
    notifyListeners();
    try {
      await _api.uploadFile(sessionId, filePath, (sent, total) {
        upload.progress = total > 0 ? sent / total : 0.0;
        notifyListeners();
      });
      upload.status = _UploadStatus.done;
      upload.progress = 1.0;
    } on ApiException catch (e) {
      upload.status = _UploadStatus.failed;
      _lastUploadError = e.message;
    } catch (e) {
      upload.status = _UploadStatus.failed;
      _lastUploadError = e.toString();
    } finally {
      notifyListeners();
    }
  }
}

class _FileUpload {
  final String id;
  final String filePath;
  final String fileName;
  final int size;
  double progress;
  _UploadStatus status;
  _FileUpload({required this.id, required this.filePath, required this.fileName, required this.size, this.progress = 0.0, this.status = _UploadStatus.uploading});
}

enum _UploadStatus { uploading, done, failed }
