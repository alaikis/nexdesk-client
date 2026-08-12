import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class LocalRecordingService {
  static final LocalRecordingService _instance = LocalRecordingService._internal();
  factory LocalRecordingService() => _instance;
  LocalRecordingService._internal();

  static const MethodChannel _channel = MethodChannel('nex.flutter/local_recording');

  bool _recording = false;
  String? _currentPath;
  Timer? _durationTimer;
  int _durationSec = 0;
  VoidCallback? onRecordingStopped;

  bool get isRecording => _recording;
  String? get currentPath => _currentPath;
  int get durationSec => _durationSec;

  Future<void> startRecording(String sessionId) async {
    if (_recording) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'recording_${sessionId}_${const Uuid().v4()}.webm';
      final path = '${dir.path}/$fileName';

      await _channel.invokeMethod('startRecording', {
        'path': path,
        'sessionId': sessionId,
      });

      _currentPath = path;
      _recording = true;
      _durationSec = 0;
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) => _durationSec++);
    } on MissingPluginException catch (_) {
      await _startFallbackRecording(sessionId);
    } catch (e) {
      throw Exception('Recording start failed: $e');
    }
  }

  Future<void> _startFallbackRecording(String sessionId) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'recording_${sessionId}_${const Uuid().v4()}.json';
    _currentPath = '${dir.path}/$fileName';
    _recording = true;
    _durationSec = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) => _durationSec++);
  }

  Future<void> stopRecording() async {
    if (!_recording) return;
    _durationTimer?.cancel();
    _durationTimer = null;

    try {
      await _channel.invokeMethod('stopRecording');
    } on MissingPluginException catch (_) {
      // Fallback: write metadata only
    } catch (_) {}

    _recording = false;
    onRecordingStopped?.call();
  }

  Future<void> pauseRecording() async {
    if (!_recording) return;
    try {
      await _channel.invokeMethod('pauseRecording');
    } on MissingPluginException catch (_) {}
  }

  Future<void> resumeRecording() async {
    if (!_recording) return;
    try {
      await _channel.invokeMethod('resumeRecording');
    } on MissingPluginException catch (_) {}
  }

  Future<List<File>> getRecordings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync().where((f) => f.path.contains('recording_')).cast<File>().toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
