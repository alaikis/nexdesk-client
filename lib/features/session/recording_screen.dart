import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/local_recording_service.dart';
import '../../l10n/app_localizations.dart';

class RecordingScreen extends StatefulWidget {
  final String sessionId;
  const RecordingScreen({super.key, required this.sessionId});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final LocalRecordingService _recordingService = LocalRecordingService();
  bool _recording = false;
  int _duration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _recordingService.onRecordingStopped = () {
      if (mounted) setState(() => _recording = false);
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      await _recordingService.startRecording(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _recording = true;
        _duration = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) setState(() => _duration++);
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recordingFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _recordingService.stopRecording();
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessionRecording)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_recording) ...[
              const Icon(Icons.fiber_manual_record, color: Color(0xFFFF3B30), size: 48),
              const SizedBox(height: 16),
              Text(_formatDuration(_duration), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(l10n.recording, style: const TextStyle(color: Color(0xFF636366))),
            ] else ...[
              const Icon(Icons.play_circle_outline, size: 48, color: Color(0xFF8E8E93)),
              const SizedBox(height: 16),
              Text(l10n.notRecording, style: const TextStyle(color: Color(0xFF636366))),
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
