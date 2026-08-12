import 'dart:async';
import 'api_client.dart';

enum QualityProfile { auto, low, medium, high }

class AdaptiveBitrateController {
  static final AdaptiveBitrateController _instance = AdaptiveBitrateController._internal();
  factory AdaptiveBitrateController() => _instance;
  AdaptiveBitrateController._internal();

  Timer? _monitorTimer;
  String? _sessionId;
  final ApiClient _api = ApiClient();
  QualityProfile _currentProfile = QualityProfile.auto;
  int _consecutiveDegradeCount = 0;
  int _consecutiveUpgradeCount = 0;

  static const _degradeThreshold = 3;
  static const _upgradeThreshold = 5;
  static const _monitorInterval = Duration(seconds: 5);

  void start(String sessionId) {
    stop();
    _sessionId = sessionId;
    _monitorTimer = Timer.periodic(_monitorInterval, (_) => _checkAndAdjust(sessionId));
  }

  void stop() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  void setProfile(QualityProfile profile) {
    _currentProfile = profile;
    _consecutiveDegradeCount = 0;
    _consecutiveUpgradeCount = 0;
  }

  Future<void> _checkAndAdjust(String sessionId) async {
    try {
      final stats = await _getWebRtcStats();
      if (stats == null) return;

      final packetLoss = stats['packetLoss'] as double? ?? 0.0;
      final rtt = stats['rtt'] as int? ?? 0;
      final availableBandwidth = stats['availableBandwidth'] as int? ?? 0;

      if (packetLoss > 0.1 || rtt > 300) {
        _consecutiveDegradeCount++;
        _consecutiveUpgradeCount = 0;
        if (_consecutiveDegradeCount >= _degradeThreshold) {
          await _degradeQuality(sessionId);
        }
      } else if (packetLoss < 0.02 && rtt < 100 && availableBandwidth > 2000) {
        _consecutiveUpgradeCount++;
        _consecutiveDegradeCount = 0;
        if (_consecutiveUpgradeCount >= _upgradeThreshold) {
          await _upgradeQuality(sessionId);
        }
      } else {
        _consecutiveDegradeCount = 0;
        _consecutiveUpgradeCount = 0;
      }
    } catch (_) {
      // Ignore monitoring errors
    }
  }

  Future<Map<String, dynamic>?> _getWebRtcStats() async {
    if (_sessionId == null) return null;
    try {
      final res = await _api.get('/sessions/$_sessionId/webrtc-stats');
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<void> _degradeQuality(String sessionId) async {
    if (_currentProfile == QualityProfile.low) return;
    final newProfile = _currentProfile == QualityProfile.auto
        ? QualityProfile.low
        : QualityProfile.values[_currentProfile.index - 1];
    await _applyProfile(sessionId, newProfile);
  }

  Future<void> _upgradeQuality(String sessionId) async {
    if (_currentProfile == QualityProfile.high) return;
    final newProfile = _currentProfile == QualityProfile.auto
        ? QualityProfile.medium
        : QualityProfile.values[_currentProfile.index + 1];
    await _applyProfile(sessionId, newProfile);
  }

  Future<void> _applyProfile(String sessionId, QualityProfile profile) async {
    _currentProfile = profile;
    _consecutiveDegradeCount = 0;
    _consecutiveUpgradeCount = 0;
    await _api.post('/sessions/$sessionId/quality', {'profile': profile.name});
  }
}

class QualityService {
  static final QualityService _instance = QualityService._internal();
  factory QualityService() => _instance;
  QualityService._internal();

  final ApiClient _api = ApiClient();

  Future<QualityProfile> getProfile(String sessionId) async {
    final res = await _api.get('/sessions/$sessionId/quality');
    final profile = res['profile'] as String? ?? 'auto';
    return QualityProfile.values.firstWhere((p) => p.name == profile, orElse: () => QualityProfile.auto);
  }

  Future<void> setProfile(String sessionId, QualityProfile profile) async {
    await _api.post('/sessions/$sessionId/quality', {'profile': profile.name});
  }

  Map<String, dynamic> getWebRtcConstraints(QualityProfile profile) {
    switch (profile) {
      case QualityProfile.low:
        return {
          'video': {
            'width': {'ideal': 640},
            'height': {'ideal': 480},
            'frameRate': {'ideal': 15},
          },
        };
      case QualityProfile.medium:
        return {
          'video': {
            'width': {'ideal': 1280},
            'height': {'ideal': 720},
            'frameRate': {'ideal': 24},
          },
        };
      case QualityProfile.high:
        return {
          'video': {
            'width': {'ideal': 1920},
            'height': {'ideal': 1080},
            'frameRate': {'ideal': 60},
          },
        };
      case QualityProfile.auto:
        return {
          'video': {
            'width': {'ideal': 1280},
            'height': {'ideal': 720},
            'frameRate': {'ideal': 30},
          },
        };
    }
  }
}
