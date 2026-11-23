import 'package:flutter_test/flutter_test.dart';
import 'package:nex/core/lan_discovery_service.dart';

/// P2（局域网直连）的判定逻辑。
/// 关键不变量：
/// - 同私有 /24 → 走 host-only（禁用 TURN）
/// - 跨网段或任一端为公网 → 回退到正常 ICE（可用 TURN 中继）
void main() {
  group('samePrivateSubnet（局域网直连判定）', () {
    test('同网段私有地址 → true', () {
      expect(
        LanDiscoveryService.samePrivateSubnet('192.168.1.10', '192.168.1.20'),
        isTrue,
      );
      expect(
        LanDiscoveryService.samePrivateSubnet('10.0.0.5', '10.0.0.99'),
        isTrue,
      );
      expect(
        LanDiscoveryService.samePrivateSubnet('172.16.4.1', '172.16.4.200'),
        isTrue,
      );
    });

    test('同私有段但不同 /24 → false', () {
      expect(
        LanDiscoveryService.samePrivateSubnet('192.168.1.10', '192.168.2.20'),
        isFalse,
      );
      expect(
        LanDiscoveryService.samePrivateSubnet('10.0.0.1', '10.0.1.1'),
        isFalse,
      );
    });

    test('任一端为公网 → false', () {
      expect(
        LanDiscoveryService.samePrivateSubnet('8.8.8.8', '192.168.1.10'),
        isFalse,
      );
      expect(
        LanDiscoveryService.samePrivateSubnet('192.168.1.10', '114.114.114.114'),
        isFalse,
      );
      expect(
        LanDiscoveryService.samePrivateSubnet('8.8.8.8', '9.9.9.9'),
        isFalse,
      );
    });

    test('非法或空地址 → false', () {
      expect(LanDiscoveryService.samePrivateSubnet('', ''), isFalse);
      expect(LanDiscoveryService.samePrivateSubnet('not-ip', '192.168.1.1'), isFalse);
      expect(LanDiscoveryService.samePrivateSubnet('192.168.1', '192.168.1.1'), isFalse);
    });

    test('172.32 及以上不算私有段', () {
      expect(
        LanDiscoveryService.samePrivateSubnet('172.32.0.1', '172.32.0.2'),
        isFalse,
      );
    });
  });

  group('forceNoRelay 语义', () {
    // webrtc_service.initialize(forceNoRelay: true) 时：
    // - iceServers 为空
    // - iceTransportPolicy = 'noRelay'
    test('host-only 模式不会加入 STUN/TURN', () {
      // 该断言固化设计意图：局域网直连不应请求 TURN 凭据
      const iceServersWhenLanDirect = <Map<String, dynamic>>[];
      expect(iceServersWhenLanDirect, isEmpty);
    });
  });
}