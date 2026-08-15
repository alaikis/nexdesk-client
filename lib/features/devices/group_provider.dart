import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';
import '../../core/storage_service.dart';

class Group {
  final int id;
  final String name;
  final int deviceCount;

  Group({
    required this.id,
    required this.name,
    required this.deviceCount,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? 'Unnamed',
      deviceCount: json['device_count'] is int
          ? json['device_count'] as int
          : int.tryParse((json['device_count'] ?? 0).toString()) ?? 0,
    );
  }
}

class GroupProvider with ChangeNotifier {
  static const _cacheKey = 'cached_groups';
  final ApiClient _api = ApiClient();

  List<Group> _groups = [];
  bool _loading = false;
  String? _selectedGroupId;

  List<Group> get groups => List.unmodifiable(_groups);
  bool get loading => _loading;
  String? get selectedGroupId => _selectedGroupId;
  bool get hasSelection => _selectedGroupId != null;

  Future<void> loadGroups() async {
    _loading = true;
    notifyListeners();
    try {
      final list = await _api.listGroups();
      _groups = list.map((g) => Group.fromJson(g as Map<String, dynamic>)).toList();
      await _cacheGroups(_groups);
    } on ApiException catch (e) {
      debugPrint('Load groups failed: $e');
      if (_groups.isEmpty) {
        _groups = await _loadCachedGroups();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createGroup(String name) async {
    try {
      final res = await _api.createGroup(name);
      final group = Group.fromJson(res);
      _groups.add(group);
      await _cacheGroups(_groups);
      notifyListeners();
    } on ApiException catch (e) {
      debugPrint('Create group failed: $e');
      rethrow;
    }
  }

  Future<void> renameGroup(int groupId, String name) async {
    try {
      await _api.renameGroup(groupId, name);
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index >= 0) {
        _groups[index] = Group(id: groupId, name: name, deviceCount: _groups[index].deviceCount);
        await _cacheGroups(_groups);
        notifyListeners();
      }
    } on ApiException catch (e) {
      debugPrint('Rename group failed: $e');
      rethrow;
    }
  }

  Future<void> deleteGroup(int groupId) async {
    try {
      await _api.deleteGroup(groupId);
      _groups.removeWhere((g) => g.id == groupId);
      if (_selectedGroupId == '$groupId') _selectedGroupId = null;
      await _cacheGroups(_groups);
      notifyListeners();
    } on ApiException catch (e) {
      debugPrint('Delete group failed: $e');
      rethrow;
    }
  }

  Future<void> assignDevice(int deviceId, int groupId) async {
    try {
      await _api.addDeviceToGroup(deviceId, groupId);
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index >= 0) {
        _groups[index] = Group(
          id: _groups[index].id,
          name: _groups[index].name,
          deviceCount: _groups[index].deviceCount + 1,
        );
        notifyListeners();
      }
    } on ApiException catch (e) {
      debugPrint('Assign device failed: $e');
      rethrow;
    }
  }

  Future<void> unassignDevice(int deviceId) async {
    try {
      await _api.removeDeviceFromGroup(deviceId);
      for (var i = 0; i < _groups.length; i++) {
        if (_groups[i].deviceCount > 0) {
          _groups[i] = Group(
            id: _groups[i].id,
            name: _groups[i].name,
            deviceCount: _groups[i].deviceCount - 1,
          );
        }
      }
      notifyListeners();
    } on ApiException catch (e) {
      debugPrint('Unassign device failed: $e');
      rethrow;
    }
  }

  void selectGroup(String? groupId) {
    _selectedGroupId = groupId;
    notifyListeners();
  }

  Future<List<Group>> _loadCachedGroups() async {
    try {
      final raw = await StorageService.getString(_cacheKey);
      if (raw == null) return [];
      final List<dynamic> list = jsonDecode(raw);
      return list.map((g) => Group.fromJson(g as Map<String, dynamic>)).toList();
    } on Exception catch (_) {
      return [];
    }
  }

  Future<void> _cacheGroups(List<Group> groups) async {
    try {
      final json = groups.map((g) => {
        'id': g.id,
        'name': g.name,
        'device_count': g.deviceCount,
      }).toList();
      await StorageService.setString(_cacheKey, jsonEncode(json));
    } on Exception catch (_) {
      debugPrint('Failed to cache groups');
    }
  }
}
