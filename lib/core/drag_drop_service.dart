import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum DragDropStatus { idle, dragging, done, failed }

class DragDropEvent {
  final List<String> files;
  final int totalSize;
  DragDropEvent({required this.files, required this.totalSize});
}

class DragDropService {
  static const MethodChannel _channel = MethodChannel('nex.flutter/drag_drop');
  static final DragDropService _instance = DragDropService._internal();
  factory DragDropService() => _instance;
  DragDropService._internal();

  final _controller = StreamController<DragDropEvent>.broadcast();
  Stream<DragDropEvent> get onDrop => _controller.stream;
  final _statusController = StreamController<DragDropStatus>.broadcast();
  Stream<DragDropStatus> get onStatusChange => _statusController.stream;

  bool _listening = false;

  Future<void> startListening() async {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler(_handleMethodCall);
    try {
      await _channel.invokeMethod('startListening');
    } catch (_) {}
  }

  Future<void> stopListening() async {
    if (!_listening) return;
    _listening = false;
    try {
      await _channel.invokeMethod('stopListening');
    } catch (_) {}
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onFilesDropped':
        final args = call.arguments as Map<dynamic, dynamic>;
        final files = (args['files'] as List<dynamic>).map((e) => e.toString()).toList();
        final totalSize = (args['totalSize'] as int?) ?? 0;
        _controller.add(DragDropEvent(files: files, totalSize: totalSize));
        break;
      case 'onDragEnter':
        _statusController.add(DragDropStatus.dragging);
        break;
      case 'onDragLeave':
        _statusController.add(DragDropStatus.idle);
        break;
    }
    return null;
  }

  void dispose() {
    _controller.close();
    _statusController.close();
  }
}
