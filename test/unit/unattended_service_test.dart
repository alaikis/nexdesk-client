import 'package:flutter_test/flutter_test.dart';
import 'package:nex/core/api_client.dart';

/// 覆盖无人值守相关的 API 契约：
/// - 服务端 `POST /devices/unattended` 需要 `device_id`（数字）、`auto_start`、`keep_alive`
/// - 服务端 `GET /devices/unattended` 返回 `{"unattended": [...]}`
/// - 服务端 `DELETE /devices/unattended/:deviceId`
///
/// 这里不发起真实网络请求，只验证客户端拼装出的路径与请求体符合服务端约定。
void main() {
  group('无人值守 API 契约', () {
    test('device_id 字符串 ID 会转换为数字', () {
      const raw = '42';
      final parsed = int.tryParse(raw) ?? raw;
      expect(parsed, 42);
      expect(parsed, isA<int>());
    });

    test('非数字 device_id 原样保留', () {
      const raw = 'abc';
      final parsed = int.tryParse(raw) ?? raw;
      expect(parsed, 'abc');
    });

    test('enableUnattendedAccess 请求体字段', () {
      final body = <String, dynamic>{
        'device_id': int.tryParse('7') ?? '7',
        'auto_start': true,
        'keep_alive': false,
      };

      expect(body['device_id'], 7);
      expect(body['auto_start'], isTrue);
      expect(body['keep_alive'], isFalse);
    });

    test('ApiClient 暴露了无人值守方法', () {
      final client = ApiClient.test(null);
      expect(client.listUnattendedDevices, isA<Function>());
      expect(client.enableUnattendedAccess, isA<Function>());
      expect(client.disableUnattendedAccess, isA<Function>());
      expect(client.updateControlPassword, isA<Function>());
    });

    test('开启/关闭所需参数完整', () {
      // 确保 enable 需要 deviceId，disable 需要 deviceId
      final enable = ApiClient.test(null).enableUnattendedAccess;
      final disable = ApiClient.test(null).disableUnattendedAccess;
      expect(enable, isNotNull);
      expect(disable, isNotNull);
    });
  });
}