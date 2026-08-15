import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';

class Share with ChangeNotifier {
  final int id;
  final int userId;
  final int deviceId;
  final String name;
  final String path;
  final bool isPublic;
  final DateTime createdAt;

  Share({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.name,
    required this.path,
    required this.isPublic,
    required this.createdAt,
  });

  factory Share.fromJson(Map<String, dynamic> json) {
    return Share(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      deviceId: json['device_id'] ?? 0,
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      isPublic: json['is_public'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class ShareFile with ChangeNotifier {
  final String name;
  final String path;
  final int size;
  final bool isDir;
  final String modified;

  ShareFile({
    required this.name,
    required this.path,
    required this.size,
    required this.isDir,
    required this.modified,
  });

  factory ShareFile.fromJson(Map<String, dynamic> json) {
    return ShareFile(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      size: json['size'] ?? 0,
      isDir: json['is_dir'] ?? false,
      modified: json['modified'] ?? '',
    );
  }
}

class ShareProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<Share> _shares = [];
  List<ShareFile> _currentFiles = [];
  bool _loading = false;
  String _currentPath = '/';
  int? _currentShareId;

  List<Share> get shares => List.unmodifiable(_shares);
  List<ShareFile> get currentFiles => List.unmodifiable(_currentFiles);
  bool get loading => _loading;
  String get currentPath => _currentPath;
  int? get currentShareId => _currentShareId;

  Future<void> loadShares() async {
    _loading = true;
    notifyListeners();
    try {
      final list = await _api.listShares();
      _shares = list.map((s) => Share.fromJson(s as Map<String, dynamic>)).toList();
    } on Exception catch (e) {
      debugPrint('Load shares failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createShare(String name, String path, int deviceId, bool isPublic) async {
    try {
      final res = await _api.createShare(name, path, deviceId, isPublic);
      final share = Share.fromJson(res);
      _shares.insert(0, share);
      notifyListeners();
      return true;
    } on Exception catch (e) {
      debugPrint('Create share failed: $e');
      return false;
    }
  }

  Future<bool> deleteShare(int shareId) async {
    try {
      await _api.deleteShare(shareId);
      _shares.removeWhere((s) => s.id == shareId);
      if (_currentShareId == shareId) {
        _currentFiles = [];
        _currentShareId = null;
        _currentPath = '/';
      }
      notifyListeners();
      return true;
    } on Exception catch (e) {
      debugPrint('Delete share failed: $e');
      return false;
    }
  }

  Future<bool> browseShare(int shareId, String path) async {
    _loading = true;
    _currentShareId = shareId;
    _currentPath = path;
    notifyListeners();
    try {
      final files = await _api.browseShare(shareId, path);
      _currentFiles = files.map((f) => ShareFile.fromJson(f as Map<String, dynamic>)).toList();
      return true;
    } on Exception catch (e) {
      debugPrint('Browse share failed: $e');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> getDownloadUrl(int shareId, String path) async {
    try {
      return await _api.getShareDownloadUrl(shareId, path);
    } on Exception catch (e) {
      debugPrint('Get download url failed: $e');
      return null;
    }
  }
}
