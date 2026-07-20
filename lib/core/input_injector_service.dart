import 'dart:async';
import 'package:flutter/services.dart';
import 'screen_capture_service.dart';
import 'storage_service.dart';
import 'signaling_service.dart';
import '../features/session/session_provider.dart';
import '../config/app_config.dart';

class InputInjectorService {
  static final InputInjectorService _instance = InputInjectorService._internal();
  factory InputInjectorService() => _instance;
  InputInjectorService._internal();

  SignalingService? _signaling;
  String? _deviceId;
  SessionProvider? _sessionProvider;
  bool _initialized = false;

  Future<void> init(SessionProvider sessionProvider) async {
    if (_initialized) return;
    _deviceId = await StorageService.getString('device_id');
    _sessionProvider = sessionProvider;
    _initialized = true;
  }

  Future<void> start() async {
    if (_signaling != null) return;
    final token = await StorageService.getString('jwt_token') ?? '';
    final deviceId = _deviceId ?? '';
    if (token.isEmpty || deviceId.isEmpty) return;

    _signaling = SignalingService(
      serverUrl: AppConfig.wsSignalUrl,
      token: token,
      deviceId: deviceId,
      onInputEvent: _handleInputEvent,
    );
    await _signaling!.connect();
  }

  void stop() {
    _signaling?.disconnect();
    _signaling = null;
  }

  Future<void> _handleInputEvent(Map<String, dynamic> event) async {
    if (_deviceId == null || _sessionProvider == null) return;
    final session = _sessionProvider!.activeSession;
    if (session == null) return;
    if (session.controlleeDeviceId != _deviceId) return;

    try {
      await ScreenCaptureService.injectInputEvent(event);
    } on PlatformException catch (_) {
      // injection not supported on this platform
    }
  }
}
