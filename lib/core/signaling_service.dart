import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'log_service.dart';

enum SignalingMessageType {
  hello,
  ping,
  pong,
  callOffer,
  callAnswer,
  ice,
  callReject,
  callEnd,
  keyExchange,
  resumeSession,
  error;

  factory SignalingMessageType.fromString(String value) {
    return SignalingMessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SignalingMessageType.error,
    );
  }
}

class SignalingMessage {
  final SignalingMessageType type;
  final Map<String, dynamic> payload;
  final String? to;
  final String? sessionId;

  SignalingMessage({
    required this.type,
    this.to,
    this.sessionId,
    this.payload = const {},
  });

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    final type = SignalingMessageType.fromString(json['type'] as String? ?? 'error');
    final to = json['to'] as String?;
    final sessionId = json['session_id'] as String?;
    final payload = Map<String, dynamic>.from(json);
    payload.remove('type');
    payload.remove('to');
    payload.remove('session_id');
    return SignalingMessage(
      type: type,
      to: to,
      sessionId: sessionId,
      payload: payload,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (to != null) 'to': to,
      if (sessionId != null) 'session_id': sessionId,
      ...payload,
    };
  }
}

class SignalingService {
  final String serverUrl;
  final String token;
  final String deviceId;
  final void Function(bool connected)? onConnectionChanged;
  final void Function(String sessionId)? onSessionResume;
  final void Function(String sessionId)? onPasswordRequired;
  final void Function(int attempts)? onReconnectAttempts;
  final void Function(int attempts)? onReconnectFailed;

  WebSocketChannel? _channel;
  final _controller = StreamController<SignalingMessage>.broadcast();
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _connected = false;
  int _reconnectAttempts = 0;
  final int _maxDelay = 30;
  static const int _maxReconnectAttempts = 5;
  String? _activeSessionId;
  final Random _random = Random();

  SignalingService({
    required this.serverUrl,
    required this.token,
    required this.deviceId,
    this.onConnectionChanged,
    this.onSessionResume,
    this.onPasswordRequired,
    this.onReconnectAttempts,
    this.onReconnectFailed,
  });

  bool get isConnected => _connected;
  Stream<SignalingMessage> get messages => _controller.stream;

  Future<void> connect() async {
    final uri = Uri.parse('$serverUrl/ws/signal?token=$token&device_id=$deviceId');
    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _connected = true;
      _reconnectAttempts = 0;
      LogService().info('Signaling connected');
      if (_activeSessionId != null) {
        onSessionResume?.call(_activeSessionId!);
      }
      onConnectionChanged?.call(true);
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      _startHeartbeat();
    } catch (e) {
      LogService().warning('Signaling connect failed: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final msg = SignalingMessage.fromJson(json);
      if (msg.type == SignalingMessageType.resumeSession && msg.sessionId != null) {
        final status = msg.payload['status'] as String?;
        if (status == 'session_invalid') {
          LogService().warning('Session invalid, clearing session');
          _activeSessionId = null;
          onSessionResume?.call('__session_invalid__');
        } else {
          onSessionResume?.call(msg.sessionId!);
        }
      } else if (msg.type == SignalingMessageType.error) {
        final error = msg.payload['error'] as String?;
        if (error == 'password_required' && msg.sessionId != null) {
          onPasswordRequired?.call(msg.sessionId!);
        }
      }
      _controller.add(msg);
    } catch (e) {
      // ignore malformed messages
    }
  }

  void _onError(Object? error) {
    _connected = false;
    LogService().warning('Signaling error: $error');
    onConnectionChanged?.call(false);
    _scheduleReconnect();
  }

  void _onDone() {
    _connected = false;
    LogService().info('Signaling connection closed');
    onConnectionChanged?.call(false);
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      send(SignalingMessage(type: SignalingMessageType.ping));
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      onReconnectFailed?.call(_reconnectAttempts);
      return;
    }
    final delay = min(1 << _reconnectAttempts, _maxDelay);
    final jitter = _random.nextInt(500);
    onReconnectAttempts?.call(_reconnectAttempts);
    _reconnectAttempts++;
    _reconnectTimer = Timer(Duration(seconds: delay, milliseconds: jitter), connect);
  }

  void setActiveSession(String sessionId) {
    _activeSessionId = sessionId;
  }

  void send(SignalingMessage message) {
    if (_channel != null && _connected) {
      _channel!.sink.add(jsonEncode(message.toJson()));
    }
  }

  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _connected = false;
    await _controller.close();
  }
}
