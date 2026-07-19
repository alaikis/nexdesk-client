import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/api_client.dart';

void main() {
  group('ApiClient', () {
    test('throws ApiException on 404 with message', () async {
      final client = ApiClient.test(_FakeClient((_) {
        return _mockResponse('{"message":"not found"}', 404);
      }));
      try {
        await client.get('/devices');
        fail('expected ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 404);
        expect(e.message, 'not found');
      }
    });

    test('throws ApiException on 500 with empty body', () async {
      final client = ApiClient.test(_FakeClient((_) {
        return _mockResponse('', 500);
      }));
      try {
        await client.get('/devices');
        fail('expected ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 500);
        expect(e.message, 'Request failed');
      }
    });

    test('wakeDevice returns true when api returns ok', () async {
      final client = ApiClient.test(_FakeClient((_) {
        return _mockResponse('{"ok":true}', 200);
      }));
      final ok = await client.wakeDevice(42);
      expect(ok, true);
    });

    test('listDevices parses devices array', () async {
      final client = ApiClient.test(_FakeClient((_) {
        return _mockResponse('{"devices":[{"id":1,"name":"d1"}]}', 200);
      }));
      final list = await client.listDevices();
      expect(list.length, 1);
      expect(list.first['name'], 'd1');
    });
  });
}

Future<http.StreamedResponse> _mockResponse(String body, int status) async {
  final stream = Stream.value(Uint8List.fromList(utf8.encode(body)));
  return http.StreamedResponse(stream, status);
}

class _FakeClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request) _handler;
  _FakeClient(this._handler);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _handler(request);
}
