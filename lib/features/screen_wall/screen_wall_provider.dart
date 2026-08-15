import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';
import '../../core/webrtc_service.dart';

class ScreenWallProvider with ChangeNotifier {
  static const int _maxDevices = 16;
  final ApiClient _api = ApiClient();
  final WebRtcService _webrtc = WebRtcService();

  final List<String> _selectedDeviceIds = [];
  int _gridSize = 2;
  bool _autoRefresh = true;
  Timer? _autoRefreshTimer;
  bool _refreshing = false;

  List<String> get selectedDeviceIds => List.unmodifiable(_selectedDeviceIds);
  int get gridSize => _gridSize;
  bool get autoRefresh => _autoRefresh;
  bool get refreshing => _refreshing;
  int get deviceCount => _selectedDeviceIds.length;

  ScreenWallProvider() {
    _startAutoRefresh();
  }

  void addDevice(String deviceId) {
    if (_selectedDeviceIds.length >= _maxDevices) return;
    if (_selectedDeviceIds.contains(deviceId)) return;
    _selectedDeviceIds.add(deviceId);
    notifyListeners();
  }

  void removeDevice(String deviceId) {
    _selectedDeviceIds.remove(deviceId);
    _webrtc.closeWallStream(deviceId);
    notifyListeners();
  }

  void setGridSize(int size) {
    if (size < 2) size = 2;
    if (size > 4) size = 4;
    _gridSize = size;
    notifyListeners();
  }

  void toggleAutoRefresh() {
    _autoRefresh = !_autoRefresh;
    if (_autoRefresh) {
      _startAutoRefresh();
    } else {
      _autoRefreshTimer?.cancel();
    }
    notifyListeners();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => refresh());
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();
    try {
      await _api.listDevices();
    } catch (e) {
      debugPrint('Screen wall refresh failed: $e');
    } finally {
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<void> connectWallStreams() async {
    for (final deviceId in _selectedDeviceIds) {
      try {
        await _webrtc.createWallStream(deviceId);
      } catch (e) {
        debugPrint('Failed to create wall stream for $deviceId: $e');
      }
    }
    notifyListeners();
  }

  Future<void> disconnectAll() async {
    for (final deviceId in List.from(_selectedDeviceIds)) {
      await _webrtc.closeWallStream(deviceId);
    }
    notifyListeners();
  }

  List<dynamic> get wallStreams => _webrtc.wallStreams;

  ScreenWallStream? getWallStream(String deviceId) => _webrtc.getWallStream(deviceId);

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _webrtc.dispose();
    super.dispose();
  }
}
