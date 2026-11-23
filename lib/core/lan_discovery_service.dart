import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 局域网发现的单个对端。
class LanPeer {
  final String deviceId;
  String name;
  String ip;
  final int port;
  final String platform;
  DateTime lastSeen;

  LanPeer({
    required this.deviceId,
    required this.name,
    required this.ip,
    required this.port,
    required this.platform,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  factory LanPeer.fromJson(Map<String, dynamic> json) {
    return LanPeer(
      deviceId: (json['device_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      ip: (json['ip'] ?? '').toString(),
      port: (json['port'] as num?)?.toInt() ?? 0,
      platform: (json['platform'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'name': name,
        'ip': ip,
        'port': port,
        'platform': platform,
      };
}

/// 局域网发现（UDP 广播 beacon）。
///
/// 设计取舍：
/// - 不引入 mDNS 依赖（`multicast_dns` / `bonsoir` / `nsd` 都需新增包与平台声明），
///   改用 UDP 广播实现：零依赖、行为可控、便于排错。
/// - 每 [beaconInterval] 广播一次本机存在；收到对端 beacon 即更新 [peers]。
/// - [peerTtl] 内未再收到 beacon 的对端会被剔除。
/// - 若防火墙拦截 UDP 入站需放行 [defaultPort]（安装包已加规则）。
class LanDiscoveryService {
  LanDiscoveryService({this.port = defaultPort});

  static const int defaultPort = 8618;
  static const String protocol = 'nex-lan/1';

  final int port;
  final Duration beaconInterval = const Duration(seconds: 3);
  final Duration peerTtl = const Duration(seconds: 12);

  RawDatagramSocket? _socket;
  Timer? _beaconTimer;
  Timer? _pruneTimer;
  final Map<String, LanPeer> _peers = {};
  final StreamController<List<LanPeer>> _peerController =
      StreamController<List<LanPeer>>.broadcast();

  String _deviceId = '';
  String _name = '';
  String _localIp = '';
  bool _running = false;

  /// 已发现的局域网对端（不含本机），按名称排序。
  List<LanPeer> get peers {
    final now = DateTime.now();
    final list = _peers.values
        .where((p) => now.difference(p.lastSeen) < peerTtl)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return List<LanPeer>.unmodifiable(list);
  }

  bool get isRunning => _running;

  /// 本机当前使用的局域网 IPv4。
  String get localIp => _localIp;

  /// 对端列表变化流。
  Stream<List<LanPeer>> get onPeers => _peerController.stream;

  /// 本机优先使用的局域网 IPv4（用于注册到服务端、生成 host 候选）。
  static Future<String?> localIpv4() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final itf in interfaces) {
        for (final addr in itf.addresses) {
          if (_isPrivateIpv4(addr.address)) return addr.address;
        }
      }
      return null;
    } catch (e) {
      debugPrint('LanDiscovery: localIpv4 failed: $e');
      return null;
    }
  }

  static bool _isPrivateIpv4(String ip) {
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

  /// 两个地址是否在同一私有 /24 网段（局域网直连判定的最常用口径）。
  static bool samePrivateSubnet(String a, String b) {
    final pa = a.split('.');
    final pb = b.split('.');
    if (pa.length != 4 || pb.length != 4) return false;
    if (!_isPrivateIpv4(a) || !_isPrivateIpv4(b)) return false;
    for (var i = 0; i < 3; i++) {
      if (pa[i] != pb[i]) return false;
    }
    return true;
  }

  Future<void> start({required String deviceId, required String name}) async {
    if (_running) return;
    _deviceId = deviceId;
    _name = name;
    _localIp = await localIpv4() ?? '';

    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
        reuseAddress: true,
        reusePort: true,
      );
      socket.broadcastEnabled = true;
      socket.listen(_onDatagram, onError: (Object e) {
        debugPrint('LanDiscovery: socket error: $e');
      });
      _socket = socket;
      _running = true;
      debugPrint('LanDiscovery: listening on udp/$port ip=$_localIp');
    } catch (e) {
      debugPrint('LanDiscovery: bind failed: $e');
      return;
    }

    _sendBeacon();
    _beaconTimer = Timer.periodic(beaconInterval, (_) => _sendBeacon());
    _pruneTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final now = DateTime.now();
      final before = _peers.length;
      _peers.removeWhere((_, p) => now.difference(p.lastSeen) >= peerTtl);
      if (_peers.length != before) _emit();
    });
  }

  void _sendBeacon() {
    final socket = _socket;
    if (socket == null) return;
    final payload = jsonEncode({
      'protocol': protocol,
      'device_id': _deviceId,
      'name': _name,
      'ip': _localIp,
      'port': port,
      'platform': defaultTargetPlatform.name,
    });
    try {
      socket.send(
        utf8.encode(payload),
        InternetAddress('255.255.255.255'),
        port,
      );
    } catch (e) {
      debugPrint('LanDiscovery: beacon send failed: $e');
    }
  }

  void _onDatagram(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final socket = _socket;
    if (socket == null) return;

    final datagram = socket.receive();
    if (datagram == null) return;

    try {
      final json =
          jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
      if (json['protocol'] != protocol) return;

      final deviceId = (json['device_id'] ?? '').toString();
      // 忽略本机自己的 beacon
      if (deviceId.isEmpty || deviceId == _deviceId) return;

      final peer = LanPeer.fromJson(json);
      // 上报的 ip 为空时用报文来源地址兜底
      if (peer.ip.isEmpty) {
        peer.ip = datagram.address.address;
      }

      final existing = _peers[deviceId];
      if (existing != null) {
        existing.lastSeen = DateTime.now();
        existing.name = peer.name;
        existing.ip = peer.ip;
      } else {
        _peers[deviceId] = peer;
      }
      _emit();
    } catch (_) {
      // 非本协议报文，忽略
    }
  }

  void _emit() {
    if (!_peerController.isClosed) {
      _peerController.add(peers);
    }
  }

  Future<void> stop() async {
    _beaconTimer?.cancel();
    _pruneTimer?.cancel();
    _beaconTimer = null;
    _pruneTimer = null;
    _socket?.close();
    _socket = null;
    _peers.clear();
    _running = false;
  }

  Future<void> dispose() async {
    await stop();
    await _peerController.close();
  }
}