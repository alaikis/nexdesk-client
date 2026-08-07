import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/storage_service.dart';
import '../../core/log_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  http.Client? _client;

  ApiClient.test(this._client);

  String? _token;
  String? _refreshToken;

  String? get token => _token;
  String? get refreshToken => _refreshToken;

  Future<void> init() async {
    _token = await StorageService.getString('jwt_token');
    _refreshToken = await StorageService.getString('jwt_refresh_token');
  }

  Future<void> _saveAuth(String? token, String? refresh) async {
    _token = token;
    _refreshToken = refresh;
    if (token != null) {
      await StorageService.setString('jwt_token', token);
    } else {
      await StorageService.delete('jwt_token');
    }
    if (refresh != null) {
      await StorageService.setString('jwt_refresh_token', refresh);
    } else {
      await StorageService.delete('jwt_refresh_token');
    }
  }

  Future<bool> _tryRefreshToken() async {
    if (_refreshToken == null) return false;
    try {
      final res = await _request('POST', '/auth/refresh', body: {'refresh_token': _refreshToken});
      final newToken = res['token'] as String?;
      final newRefresh = res['refresh_token'] as String? ?? _refreshToken;
      if (newToken != null) {
        await _saveAuth(newToken, newRefresh);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>> get(String path) async {
    return _request('GET', path);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    return _request('POST', path, body: body);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    return _request('PATCH', path, body: body);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    return _request('DELETE', path);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (_refreshToken != null) {
      headers['X-Refresh-Token'] = _refreshToken!;
    }

    late http.Response response;
    final client = _client ?? http.Client();
    switch (method) {
      case 'GET':
        response = await client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await client.post(uri, headers: headers, body: _encode(body));
        break;
      case 'PATCH':
        response = await client.patch(uri, headers: headers, body: _encode(body));
        break;
      case 'DELETE':
        response = await client.delete(uri, headers: headers);
        break;
      default:
        throw ArgumentError('Unsupported method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final refreshed = response.headers['x-access-token'];
      if (refreshed != null && refreshed.isNotEmpty) {
        _token = refreshed;
        await StorageService.setString('jwt_token', refreshed);
      }
      LogService().debug('HTTP $method $path -> ${response.statusCode}');
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401 && _refreshToken != null) {
      if (await _tryRefreshToken()) {
        final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
        final newHeaders = <String, String>{'Content-Type': 'application/json'};
        if (_token != null) newHeaders['Authorization'] = 'Bearer $_token';
        if (_refreshToken != null) newHeaders['X-Refresh-Token'] = _refreshToken!;
        final client2 = _client ?? http.Client();
        http.Response retryResponse;
        switch (method) {
          case 'GET':
            retryResponse = await client2.get(uri, headers: newHeaders);
            break;
          case 'POST':
            retryResponse = await client2.post(uri, headers: newHeaders, body: _encode(body));
            break;
          case 'PATCH':
            retryResponse = await client2.patch(uri, headers: newHeaders, body: _encode(body));
            break;
          case 'DELETE':
            retryResponse = await client2.delete(uri, headers: newHeaders);
            break;
          default:
            throw ArgumentError('Unsupported method: $method');
        }
        if (retryResponse.statusCode >= 200 && retryResponse.statusCode < 300) {
          if (retryResponse.body.isEmpty) return {};
          return jsonDecode(retryResponse.body) as Map<String, dynamic>;
        }
      }
      await _saveAuth(null, null);
    }
    LogService().warning('HTTP $method $path -> ${response.statusCode}: ${response.body}');
    String? msg;
    try {
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      msg = map['message'] as String? ?? map['error'] as String?;
    } catch (_) {}
    throw ApiException(response.statusCode, msg ?? 'Request failed');
  }

  String? _encode(Map<String, dynamic>? body) {
    if (body == null) return null;
    return jsonEncode(body);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final res = await post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
    });
    final token = res['token'] as String?;
    final refresh = res['refresh_token'] as String?;
    if (token != null) {
      await _saveAuth(token, refresh);
    }
    return res;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await post('/auth/login', {
      'email': email,
      'password': password,
    });
    final token = res['token'] as String?;
    final refresh = res['refresh_token'] as String?;
    if (token != null) {
      await _saveAuth(token, refresh);
    }
    return res;
  }

  Future<void> logout() async {
    await _saveAuth(null, null);
  }

  Future<Map<String, dynamic>> registerDevice({
    required String name,
    required String os,
    required String pubkey,
    String? fingerprint,
  }) async {
    final deviceId = await StorageService.getString('device_id');
    final body = <String, dynamic>{
      'name': name,
      'os': os,
      'pubkey': pubkey,
    };
    if (deviceId != null) body['id'] = deviceId;
    if (fingerprint != null) body['fingerprint'] = fingerprint;
    return post('/devices', body);
  }

  Future<List<dynamic>> listDevices() async {
    final res = await get('/devices');
    return res['devices'] as List<dynamic>;
  }

  Future<void> heartbeat(String deviceId) async {
    await post('/devices/$deviceId/heartbeat', {});
  }

  Future<List<dynamic>> searchDevices(String query) async {
    final res = await get('/devices/search?q=${Uri.encodeQueryComponent(query)}');
    return res['devices'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getDevice(String deviceId) async {
    return get('/devices/$deviceId');
  }

  Future<Map<String, dynamic>> toggleFavorite(String deviceId) async {
    return patch('/devices/$deviceId/favorite', {});
  }

  Future<List<dynamic>> getFavorites() async {
    final res = await get('/devices/favorites');
    return res['devices'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> createSession(String controlleeDeviceId) async {
    final controllerId = await StorageService.getString('device_id');
    if (controllerId == null) throw ApiException(400, 'Missing local device id');
    return post('/sessions', {
      'controller_device_id': controllerId,
      'controllee_device_id': controlleeDeviceId,
    });
  }

  Future<Map<String, dynamic>> getTurnCredential() async {
    return get('/turn/credential');
  }

  Future<Map<String, dynamic>> getRelease(String platform) async {
    final res = await get('/public/releases/latest?platform=$platform');
    return res;
  }

  Future<bool> wakeDevice(int deviceId) async {
    final res = await post('/devices/$deviceId/wol', {});
    return res['ok'] == true;
  }

  Future<Map<String, dynamic>> startRecording(String sessionId) async {
    return post('/sessions/$sessionId/recordings/start', {});
  }

  Future<Map<String, dynamic>> stopRecording(String sessionId) async {
    return post('/sessions/$sessionId/recordings/stop', {});
  }

  Future<List<dynamic>> listRecordings(String sessionId) async {
    final res = await get('/sessions/$sessionId/recordings');
    if (res['recordings'] is List) {
      return res['recordings'] as List<dynamic>;
    }
    if (res['id'] != null) {
      return [res];
    }
    return [];
  }

  Future<void> deleteRecording(int recordingId) async {
    await delete('/recordings/$recordingId');
  }

  Future<Map<String, dynamic>> setupTOTP() async {
    return post('/auth/2fa/setup', {});
  }

  Future<bool> verifyTOTP(String tempToken, String code) async {
    final res = await post('/auth/2fa/verify', {
      'temp_token': tempToken,
      'code': code,
    });
    final token = res['token'] as String?;
    final refresh = res['refresh_token'] as String?;
    if (token != null) {
      await _saveAuth(token, refresh);
    }
    return token != null;
  }

  Future<bool> enableTOTP() async {
    final res = await post('/auth/2fa/enable', {});
    return res['enabled'] == true || res['ok'] == true;
  }

  Future<bool> disableTOTP() async {
    final res = await post('/auth/2fa/disable', {});
    return res['ok'] == true;
  }

  Future<bool> is2FAEnabled() async {
    final res = await get('/auth/2fa/status');
    return res['enabled'] == true;
  }

  Future<void> cancelTransfer(int transferId) async {
    await post('/files/$transferId/cancel', {});
  }

  Future<Map<String, dynamic>> getSession(String sessionId) async {
    return get('/sessions/$sessionId');
  }

  Future<List<dynamic>> getSessionMessages(String sessionId) async {
    final res = await get('/sessions/$sessionId/messages');
    return res['messages'] as List<dynamic>;
  }

  Future<void> setSessionPassword(String sessionId, String password) async {
    await post('/sessions/$sessionId/password', {'password': password});
  }
}
