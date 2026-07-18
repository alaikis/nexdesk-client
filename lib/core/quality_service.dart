import 'api_client.dart';

enum QualityProfile { auto, low, medium, high }

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
