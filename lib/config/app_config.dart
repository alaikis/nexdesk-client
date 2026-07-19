class AppConfig {
  static const String defaultServerUrl = 'https://nex.hottol.com';
  static const String defaultApiBaseUrl = 'https://nex.hottol.com/api/v1';
  static const String defaultTurnUrl = 'turn:nex.hottol.com:3478';
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
    if (serverUrl != null) AppConfig.serverUrl = serverUrl;
    if (apiBaseUrl != null) AppConfig.apiBaseUrl = apiBaseUrl;
    if (turnUrl != null) AppConfig.turnUrl = turnUrl;
    if (stunUrl != null) AppConfig.stunUrl = stunUrl;
  }

  static String get wsSignalUrl => '${serverUrl.replaceFirst('https', 'wss')}/ws/signal';
}
