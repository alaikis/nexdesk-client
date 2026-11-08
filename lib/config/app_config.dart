class AppConfig {
  static const String defaultServerUrl = 'https://nex.hottol.com';
  static const String defaultApiBaseUrl = 'https://nex.hottol.com/api/v1';
  static const String defaultTurnUrl = 'turns:nex.hottol.com:3478';
  static const String defaultStunUrl = 'stun:stun.l.google.com:19302';

  // Passport OIDC SSO 配置（confidential 客户端，PKCE + client_secret 由云端持有）
  static const String passportBaseUrl = 'https://passport.alaikis.com';
  static const String passportClientId = '8755679';
  // client_secret 由服务端持有，客户端不接触
  // 本地回调端口（保留用于本地开发直连调试）
  static const int ssoCallbackPort = 8443;

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

  /// 本地 SSO 回调 URL
  static String get ssoCallbackUrl => 'http://127.0.0.1:$ssoCallbackPort/callback';
}
