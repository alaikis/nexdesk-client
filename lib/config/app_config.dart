class AppConfig {
  static const String defaultServerUrl = 'https://nex.hottol.com';
  static const String defaultApiBaseUrl = 'https://nex.hottol.com/api/v1';
  static const String defaultTurnUrl = 'turns:nex.hottol.com:3478';
  static const String defaultStunUrl = 'stun:stun.l.google.com:19302';

  static String serverUrl = defaultServerUrl;
  static String apiBaseUrl = defaultApiBaseUrl;
  static String turnUrl = defaultTurnUrl;
  static String stunUrl = defaultStunUrl;

  static void configure({
    String? serverUrl,
    String? apiBaseUrl,
    String? turnUrl,
    String? stunUrl,
  }) {
    if (serverUrl != null) {
      final uri = Uri.parse(serverUrl);
      if (uri.scheme != 'https') {
        throw ArgumentError('Server URL must use HTTPS. Got: $serverUrl');
      }
      AppConfig.serverUrl = serverUrl;
    }
    if (apiBaseUrl != null) {
      final uri = Uri.parse(apiBaseUrl);
      if (uri.scheme != 'https') {
        throw ArgumentError('API base URL must use HTTPS. Got: $apiBaseUrl');
      }
      AppConfig.apiBaseUrl = apiBaseUrl;
    }
    if (turnUrl != null) AppConfig.turnUrl = turnUrl;
    if (stunUrl != null) AppConfig.stunUrl = stunUrl;
  }

  static String get wsSignalUrl => '${serverUrl.replaceFirst('https', 'wss')}/ws/signal';
}
