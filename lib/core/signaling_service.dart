import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

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
    return SignalingMessage(
      type: SignalingMessageType.fromString(json['type'] as String? ?? 'error'),
      to: json['to'] as String?,
      sessionId: json['session_id'] as String?,
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
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

  WebSocketChannel? _channel;
  final _controller = StreamController<SignalingMessage>.broadcast();
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _connected = false;

  SignalingService({
    required this.serverUrl,
    required this.token,
    required this.deviceId,
  });

  bool get isConnected => _connected;
  Stream<SignalingMessage> get messages => _controller.stream;

  Future<void> connect() async {
    final uri = Uri.parse('$serverUrl/ws/signal?token=$token&device_id=$deviceId');
    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _connected = true;
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      _startHeartbeat();
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final msg = SignalingMessage.fromJson(json);
      _controller.add(msg);
    } catch (e) {
      // ignore malformed messages
    }
  }

  void _onError(error) {
    _connected = false;
    _scheduleReconnect();
  }

  void _onDone() {
    _connected = false;
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
    _reconnectTimer = Timer(const Duration(seconds: 5), connect);
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
