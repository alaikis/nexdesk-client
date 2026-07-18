import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';
import '../../core/storage_service.dart';

class Device with ChangeNotifier {
  final String id;
  final String name;
  final String os;
  final bool online;
  final bool wolEnabled;

  Device({
    required this.id,
    required this.name,
    required this.os,
    required this.online,
    this.wolEnabled = false,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id']?.toString() ?? json['id'] as String,
      name: json['name'] as String? ?? 'Unknown',
      os: json['os'] as String? ?? 'unknown',
      online: json['online'] as bool? ?? false,
      wolEnabled: json['wol_enabled'] as bool? ?? false,
    );
  }
}

class DeviceProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<Device> _devices = [];
  List<Device> get devices => List.unmodifiable(_devices);

  Future<void> loadDevices() async {
    try {
      final list = await _api.listDevices();
      _devices = list.map((d) => Device.fromJson(d as Map<String, dynamic>)).toList();
      notifyListeners();
    } on ApiException catch (e) {
      debugPrint('Load devices failed: $e');
    }
  }

  Future<void> refresh() async {
    final deviceId = await StorageService.getString('device_id');
    if (deviceId == null) return;
    try {
      await _api.heartbeat(deviceId);
      await loadDevices();
    } on ApiException catch (e) {
      debugPrint('Heartbeat failed: $e');
    }
  }

  Future<bool> registerDevice(String name, String os) async {
    try {
      final res = await _api.registerDevice(name: name, os: os, pubkey: '');
      final device = Device.fromJson(res);
      _devices.add(device);
      await StorageService.setString('device_id', device.id);
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
