import '../../core/api_client.dart';
import '../../core/storage_service.dart';

class DeviceManager {
  final ApiClient _api = ApiClient();

  // Get favorite device IDs from local storage
  Future<Set<int>> getFavoriteIds() async {
    final ids = await StorageService.getStringList('favorite_devices');
    return ids.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();
  }

  // Toggle device favorite status
  Future<void> toggleFavorite(int deviceId) async {
    final favorites = await getFavoriteIds();
    if (favorites.contains(deviceId)) {
      favorites.remove(deviceId);
    } else {
      favorites.add(deviceId);
    }
    await StorageService.setStringList(
      'favorite_devices',
      favorites.map((e) => e.toString()).toList(),
    );
  }

  // Check if device is favorite
  Future<bool> isFavorite(int deviceId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(deviceId);
  }

  // Get recently connected device IDs
  Future<List<int>> getRecentDeviceIds() async {
    final ids = await StorageService.getStringList('recent_devices');
    return ids.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList();
  }

  // Add device to recent list
  Future<void> addRecentDevice(int deviceId) async {
    final recents = await getRecentDeviceIds();
    recents.remove(deviceId);
    recents.insert(0, deviceId);
    // Keep only last 10
    if (recents.length > 10) recents.removeLast();
    await StorageService.setStringList(
      'recent_devices',
      recents.map((e) => e.toString()).toList(),
    );
  }

  // Search devices by name/OS/tag
  Future<List<Map<String, dynamic>>> searchDevices(String query) async {
    final res = await _api.get('/devices');
    final devices = (res['devices'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (query.isEmpty) return devices;

    final q = query.toLowerCase();
    return devices.where((d) {
      final name = (d['name'] as String? ?? '').toLowerCase();
      final os = (d['os'] as String? ?? '').toLowerCase();
      final tags = (d['tags'] as String? ?? '').toLowerCase();
      return name.contains(q) || os.contains(q) || tags.contains(q);
    }).toList();
  }

  // Get device tags
  Future<List<String>> getDeviceTags(int deviceId) async {
    final res = await _api.get('/devices/$deviceId/tags');
    return (res['tags'] as List<dynamic>?)?.cast<String>() ?? [];
  }

  // Set device tags
  Future<void> setDeviceTags(int deviceId, List<String> tags) async {
    await _api.post('/devices/$deviceId/tags', {'tags': tags});
  }
}
