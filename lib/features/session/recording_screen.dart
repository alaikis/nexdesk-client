import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/local_recording_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class RecordingScreen extends StatefulWidget {
  final String sessionId;
  const RecordingScreen({super.key, required this.sessionId});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with SingleTickerProviderStateMixin {
  final LocalRecordingService _recordingService = LocalRecordingService();
  bool _recording = false;
  int _duration = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _recordingService.onRecordingStopped = () {
      if (mounted) {
        _pulseController.stop();
        setState(() => _recording = false);
      }
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
      _pulseController.repeat(reverse: true);
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
    _pulseController.stop();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final textSecondary = isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73);
    final errorColor = isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: Text(l10n.sessionRecording)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_recording) ...[
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: errorColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: errorColor.withValues(alpha: 0.3),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                _formatDuration(_duration),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.recording,
                style: TextStyle(fontSize: 15, color: textSecondary),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _stopRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: surfaceColor,
                  foregroundColor: errorColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(NexRadius.md),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop, color: errorColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.cancel,
                      style: TextStyle(
                        color: errorColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: _startRecording,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: errorColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fiber_manual_record,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.notRecording,
                style: TextStyle(fontSize: 15, color: textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
