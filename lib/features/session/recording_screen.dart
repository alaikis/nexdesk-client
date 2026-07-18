import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class RecordingScreen extends StatefulWidget {
  final String sessionId;
  const RecordingScreen({super.key, required this.sessionId});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final ApiClient _api = ApiClient();
  bool _recording = false;
  int _duration = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    await _api.startRecording(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _recording = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _duration++);
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _api.stopRecording(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _recording = false;
    });
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Recording')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_recording) ...[
              const Icon(Icons.fiber_manual_record, color: Color(0xFFFF3B30), size: 48),
              const SizedBox(height: 16),
              Text(_formatDuration(_duration), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Recording...', style: TextStyle(color: Color(0xFF636366))),
            ] else ...[
              const Icon(Icons.play_circle_outline, size: 48, color: Color(0xFF8E8E93)),
              const SizedBox(height: 16),
              const Text('Not recording', style: TextStyle(color: Color(0xFF636366))),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _recording ? _stopRecording : _startRecording,
        backgroundColor: _recording ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
        child: Icon(_recording ? Icons.stop : Icons.fiber_manual_record, color: Colors.white),
      ),
    );
  }
}
