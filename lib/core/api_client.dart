import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/storage_service.dart';

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

  String? _token;

  String? get token => _token;

  Future<void> init() async {
    _token = await StorageService.getString('jwt_token');
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

    late http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers, body: _encode(body));
        break;
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: _encode(body));
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw ArgumentError('Unsupported method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
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
    return post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
    });
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await post('/auth/login', {
      'email': email,
      'password': password,
    });
    _token = res['token'] as String?;
    if (_token != null) {
      await StorageService.setString('jwt_token', _token!);
    }
    return res;
  }

  Future<void> logout() async {
    await StorageService.delete('jwt_token');
    _token = null;
  }

  Future<Map<String, dynamic>> registerDevice({
    required String name,
    required String os,
    required String pubkey,
    String? fingerprint,
  }) async {
    final deviceId = await StorageService.getString('device_id');
    return post('/devices', {
      if (deviceId != null) 'id': deviceId,
      'name': name,
      'os': os,
      'pubkey': pubkey,
      if (fingerprint != null) 'fingerprint': fingerprint,
    });
  }

  Future<List<dynamic>> listDevices() async {
    final res = await get('/devices');
    return res['devices'] as List<dynamic>;
  }

  Future<void> heartbeat(String deviceId) async {
    await post('/devices/$deviceId/heartbeat', {});
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
}
