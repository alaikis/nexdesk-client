import 'package:flutter_test/flutter_test.dart';
import 'package:nex/core/lan_discovery_service.dart';

/// P1（局域网发现）的纯逻辑不变量。
/// 不依赖真实网络：只验证报文编解码、私有网段判定、对端过期策略。
void main() {
  group('LanPeer 序列化', () {
    test('beacon 报文可往返', () {
      final peer = LanPeer(
        deviceId: '12',
        name: 'office-pc',
        ip: '192.168.1.20',
        port: LanDiscoveryService.defaultPort,
        platform: 'windows',
      );

      final restored = LanPeer.fromJson(peer.toJson());

      expect(restored.deviceId, '12');
      expect(restored.name, 'office-pc');
      expect(restored.ip, '192.168.1.20');
      expect(restored.port, 8618);
      expect(restored.platform, 'windows');
    });

    test('缺字段时给安全默认值', () {
      final peer = LanPeer.fromJson(<String, dynamic>{});
      expect(peer.deviceId, '');
      expect(peer.name, '');
      expect(peer.ip, '');
      expect(peer.port, 0);
    });

    test('lastSeen 默认取当前时间', () {
      final before = DateTime.now();
      final peer = LanPeer.fromJson(<String, dynamic>{'device_id': '1'});
      expect(
        peer.lastSeen.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });

  group('beacon 协议标识', () {
    test('protocol 与端口是固定常量', () {
      expect(LanDiscoveryService.protocol, 'nex-lan/1');
      expect(LanDiscoveryService.defaultPort, 8618);
    });
  });

  group('对端过期（peerTtl）', () {
    test('超过 ttl 的对端被过滤', () {
      const ttl = Duration(seconds: 12);
      final stale = LanPeer(
        deviceId: 'stale',
        name: 'old',
        ip: '10.0.0.9',
        port: 8618,
        platform: 'windows',
        lastSeen: DateTime.now().subtract(ttl + const Duration(seconds: 1)),
      );
      final fresh = LanPeer(
        deviceId: 'fresh',
        name: 'new',
        ip: '10.0.0.10',
        port: 8618,
        platform: 'windows',
      );

      final peers = [stale, fresh];
      final now = DateTime.now();
      final alive =
          peers.where((p) => now.difference(p.lastSeen) < ttl).toList();

      expect(alive.length, 1);
      expect(alive.single.deviceId, 'fresh');
    });
  });

  group('私有 IPv4 判定（用于挑选本机 LAN IP）', () {
    bool isPrivate(String ip) {
      final parts = ip.split('.');
      if (parts.length != 4) return false;
      final a = int.tryParse(parts[0]);
      final b = int.tryParse(parts[1]);
      if (a == null || b == null) return false;
      if (a == 10) return true;
      if (a == 172 && b >= 16 && b <= 31) return true;
      if (a == 192 && b == 168) return true;
      return false;
    }

    test('识别 RFC1918 私有段', () {
      expect(isPrivate('10.1.2.3'), isTrue);
      expect(isPrivate('172.16.0.1'), isTrue);
      expect(isPrivate('172.31.255.255'), isTrue);
      expect(isPrivate('192.168.1.20'), isTrue);
    });

    test('排除公网与非法地址', () {
      expect(isPrivate('8.8.8.8'), isFalse);
      expect(isPrivate('172.32.0.1'), isFalse);
      expect(isPrivate('127.0.0.1'), isFalse);
      expect(isPrivate('not-an-ip'), isFalse);
    });
  });

  group('发现服务生命周期', () {
    test('未启动时 peers 为空且 isRunning 为 false', () {
      final service = LanDiscoveryService();
      expect(service.isRunning, isFalse);
      expect(service.peers, isEmpty);
      expect(service.localIp, '');
    });

    test('stop 可重复调用', () async {
      final service = LanDiscoveryService();
      await service.stop();
      await service.stop();
      expect(service.isRunning, isFalse);
    });
  });
}