import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './signaling_service.dart';

class InputRelayService {
  final SignalingService _signaling;
  final String sessionId;
  final String targetDeviceId;
  final List<Map<String, dynamic>> _buffer = [];
  Timer? _flushTimer;
  bool _enabled = false;
  Size? _widgetSize;

  InputRelayService({
    required SignalingService signaling,
    required this.sessionId,
    required this.targetDeviceId,
  }) : _signaling = signaling;

  void updateSize(Size size) {
    _widgetSize = size;
  }

  void start() {
    _enabled = true;
    _buffer.clear();
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => _flush());
  }

  void stop() {
    _enabled = false;
    _flushTimer?.cancel();
    _flush();
  }

  void _flush() {
    if (_buffer.isEmpty) return;
    final events = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();
    _signaling.send(SignalingMessage(
      type: SignalingMessageType.inputEvent,
      to: targetDeviceId,
      sessionId: sessionId,
      payload: {'events': events},
    ));
  }

  void handlePointerEvent(PointerEvent event) {
    if (!_enabled || _widgetSize == null) return;
    final local = event.localPosition;
    final size = _widgetSize!;
    final x = local.dx / size.width;
    final y = local.dy / size.height;

    if (event is PointerDownEvent) {
      _buffer.add(_mouseEvent('mouseDown', x, y, _button(event.buttons), 1));
    } else if (event is PointerMoveEvent) {
      _buffer.add(_mouseEvent('mouseMove', x, y, -1, 0));
    } else if (event is PointerUpEvent) {
      _buffer.add(_mouseEvent('mouseUp', x, y, _button(event.buttons), 1));
    } else if (event is PointerScrollEvent) {
      _buffer.add({
        'kind': 'mouseWheel',
        'x': x,
        'y': y,
        'deltaX': event.scrollDelta.dx,
        'deltaY': event.scrollDelta.dy,
      });
    }
  }

  static int _button(int buttons) {
    if (buttons == 1 << (0 & 0x1F)) return 0;
    if (buttons == 1 << (1 & 0x1F)) return 1;
    return 2;
  }

  static Map<String, dynamic> _mouseEvent(String kind, double x, double y, int button, int action) {
    return {
      'kind': kind,
      'x': x,
      'y': y,
      'button': button,
      'action': action,
    };
  }

  void handleKeyEvent(KeyEvent event, int modifiers) {
    if (!_enabled) return;
    final kind = event is KeyDownEvent ? 'keyDown' : 'keyUp';
    _buffer.add({
      'kind': kind,
      'keyCode': event.physicalKey.usbHidUsage & 0xFFFF,
      'modifiers': modifiers,
    });
  }
}
