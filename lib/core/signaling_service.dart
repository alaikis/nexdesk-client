import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
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
  inputEvent,
  chatMessage,
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

/// Chat message model
class ChatMessage {
  final String from;
  final String content;
  final int timestamp;

  ChatMessage({required this.from, required this.content, required this.timestamp});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      from: json['from'] as String? ?? '',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'from': from,
    'content': content,
    'timestamp': timestamp,
  };
}

class SignalingService {
  final String serverUrl;
  final String token;
  final String deviceId;
  final void Function(bool connected)? onConnectionChanged;
  final void Function(String sessionId)? onSessionResume;
  final void Function(String sessionId)? onPasswordRequired;
  final void Function(Map<String, dynamic> event)? onInputEvent;
  final void Function(Uint8List publicKey, String fromDevice)? onKeyExchange;
  void Function(ChatMessage message)? onChatMessage;
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
    this.onInputEvent,
    this.onKeyExchange,
    this.onChatMessage,
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
      } else if (msg.type == SignalingMessageType.inputEvent) {
        final events = msg.payload['events'];
        if (events is List) {
          for (final ev in events) {
            onInputEvent?.call(ev as Map<String, dynamic>);
          }
        }
      } else if (msg.type == SignalingMessageType.keyExchange) {
        final pk = msg.payload['public_key'];
        final fromDevice = msg.payload['from_device'] as String?;
        if (pk is String && fromDevice != null) {
          try {
            final publicKey = base64Decode(pk);
            onKeyExchange?.call(Uint8List.fromList(publicKey), fromDevice);
          } catch (e) {
            LogService().warning('Failed to decode key exchange public key: $e');
          }
        }
      } else if (msg.type == SignalingMessageType.chatMessage) {
        final from = msg.payload['from'] as String?;
        final content = msg.payload['content'] as String?;
        final timestamp = msg.payload['timestamp'] as int? ?? 0;
        if (from != null && content != null) {
          onChatMessage?.call(ChatMessage(from: from, content: content, timestamp: timestamp));
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

  /// Send E2EE public key to remote device
  void sendKeyExchange(Uint8List publicKey, String toDevice) {
    send(SignalingMessage(
      type: SignalingMessageType.keyExchange,
      to: toDevice,
      payload: {
        'public_key': base64Encode(publicKey),
        'from_device': deviceId,
      },
    ));
  }

  /// Send chat message to remote device
  void sendChatMessage(String toDevice, String content) {
    send(SignalingMessage(
      type: SignalingMessageType.chatMessage,
      to: toDevice,
      payload: {
        'from': deviceId,
        'content': content,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    ));
  }

  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _connected = false;
    await _controller.close();
  }
}
