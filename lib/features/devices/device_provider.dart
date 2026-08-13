import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';
import '../../core/storage_service.dart';
import '../../core/secure_storage_service.dart';

class Device with ChangeNotifier {
  final String id;
  final String name;
  final String os;
  final bool online;
  final bool wolEnabled;
  final String code;
  final bool hasControlPassword;

  Device({
    required this.id,
    required this.name,
    required this.os,
    required this.online,
    this.wolEnabled = false,
    this.code = '',
    this.hasControlPassword = false,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id']?.toString() ?? json['id'] as String,
      name: json['name'] as String? ?? 'Unknown',
      os: json['os'] as String? ?? 'unknown',
      online: json['online'] as bool? ?? false,
      wolEnabled: json['wol_enabled'] as bool? ?? false,
      code: json['code'] as String? ?? '',
      hasControlPassword: json['control_password'] is bool
          ? json['control_password'] as bool
          : (json['control_password'] as String?)?.isNotEmpty ?? false,
    );
  }
}

class DeviceProvider with ChangeNotifier {
  static const _cacheKey = 'cached_devices';
  final ApiClient _api = ApiClient();

  List<Device> _devices = [];
  bool _loading = false;
  String _filter = '';
  List<Device> get devices => List.unmodifiable(_devices);
  bool get loading => _loading;
  String get filter => _filter;
  List<Device> get filteredDevices {
    if (_filter.isEmpty) return _devices;
    final q = _filter.toLowerCase();
    return _devices.where((d) =>
      d.name.toLowerCase().contains(q) ||
      d.os.toLowerCase().contains(q) ||
      d.code.toLowerCase().contains(q)
    ).toList();
  }
  List<Device> get onlineDevices => filteredDevices.where((d) => d.online).toList();
  List<Device> get offlineDevices => filteredDevices.where((d) => !d.online).toList();

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  Future<void> loadDevices() async {
    _loading = true;
    notifyListeners();
    try {
      final list = await _api.listDevices();
      _devices = list.map((d) => Device.fromJson(d as Map<String, dynamic>)).toList();
      await _cacheDevices(_devices);
    } on ApiException catch (e) {
      debugPrint('Load devices failed: $e');
      if (_devices.isEmpty) {
        _devices = await _loadCachedDevices();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final deviceId = await SecureStorageService.getString('device_id');
    if (deviceId == null) return;
    try {
      await _api.heartbeat(deviceId);
      await loadDevices();
    } on ApiException catch (e) {
      debugPrint('Heartbeat failed: $e');
    }
  }

  Future<List<Device>> _loadCachedDevices() async {
    try {
      final raw = await StorageService.getString(_cacheKey);
      if (raw == null) return [];
      final List<dynamic> list = jsonDecode(raw);
      return list.map((d) => Device.fromJson(d as Map<String, dynamic>)).toList();
    } on Exception catch (_) {
      return [];
    }
  }

  Future<void> _cacheDevices(List<Device> devices) async {
    try {
      final json = devices.map((d) => {
        'id': d.id,
        'name': d.name,
        'os': d.os,
        'online': d.online,
        'wol_enabled': d.wolEnabled,
        'code': d.code,
        'control_password': d.hasControlPassword,
      }).toList();
      await StorageService.setString(_cacheKey, jsonEncode(json));
    } on Exception catch (_) {
      debugPrint('Failed to cache devices');
    }
  }

  Future<bool> registerDevice(String name, String os) async {
    try {
      final res = await _api.registerDevice(name: name, os: os, pubkey: '');
      final device = Device.fromJson(res);
      _devices.add(device);
      await SecureStorageService.setString('device_id', device.id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      debugPrint('Register device failed: $e');
      return false;
    }
  }

  Future<bool> wakeDevice(String deviceId) async {
    final id = int.tryParse(deviceId);
    if (id == null) return false;
    return await _api.wakeDevice(id);
  }
}
