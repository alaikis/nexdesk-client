import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/api_client.dart';
import 'pkce.dart';

class OidcSsoClient {
  final String passportBaseUrl;
  final String clientId;
  final String redirectUri;
  final String scopes;

  OidcSsoClient({
    required this.passportBaseUrl,
    required this.clientId,
    required this.redirectUri,
    this.scopes = 'openid profile email',
  });

  final http.Client _client = http.Client();

  Map<String, String> _pkce = {};

  /// 生成 PKCE 参数并返回 passport authorize URL
  String buildAuthorizeUrl() {
    final verifier = Pkce.generateCodeVerifier();
    final challenge = Pkce.generateCodeChallenge(verifier);
    final state = Pkce.generateState();
    final nonce = Pkce.generateNonce();

    _pkce = {
      'code_verifier': verifier,
      'state': state,
      'nonce': nonce,
    };

    final params = <String, String>{
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scopes,
      'state': state,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'nonce': nonce,
    };

    final query = Uri(queryParameters: params).query;
    return '$passportBaseUrl/oidc/authorize?$query';
  }

  /// 获取生成的 state (用于验证回调)
  String get expectedState => _pkce['state'] ?? '';

  /// 用 code + code_verifier 交换 token (PKCE，公共客户端无需 secret)
  Future<Map<String, dynamic>> exchangeCodeForToken(
    String code,
  ) async {
    final verifier = _pkce['code_verifier'];
    if (verifier == null) {
      throw ApiException(0, 'PKCE verifier not generated');
    }

    final tokenUrl = '$passportBaseUrl/oidc/token';
    final form = <String, String>{
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri,
      'client_id': clientId,
      'code_verifier': verifier,
    };

    final res = await _client
        .post(
          Uri.parse(tokenUrl),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: form,
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      final msg = err['error_description'] ?? err['error'] ?? 'Token exchange failed';
      throw ApiException(res.statusCode, msg.toString());
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    _pkce = {}; // 清除 PKCE 状态
    return data;
  }
}