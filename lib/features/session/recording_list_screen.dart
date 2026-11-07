import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/session_recording.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/nex_card.dart';

class RecordingListScreen extends StatefulWidget {
  final String sessionId;
  const RecordingListScreen({super.key, required this.sessionId});

  @override
  State<RecordingListScreen> createState() => _RecordingListScreenState();
}

class _RecordingListScreenState extends State<RecordingListScreen> {
  final ApiClient _api = ApiClient();
  List<SessionRecording> _recordings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    try {
      final list = await _api.listRecordings(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _recordings = list.map((r) => SessionRecording.fromJson(r as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteRecording(int recordingId) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteRecording),
        content: Text(l10n.cannotBeUndone),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await _api.deleteRecording(recordingId);
    if (!mounted) return;
    setState(() {
      _recordings.removeWhere((r) => r.id == recordingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final backgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final textSecondary = isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73);
    final textTertiary = isDark ? const Color(0xFF636366) : const Color(0xFFAEAEB2);
    final errorColor = isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: Text(l10n.recordingsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _recordings.isEmpty
              ? Center(
                  child: Text(
                    l10n.noRecordingsYet,
                    style: TextStyle(fontSize: 15, color: textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _recordings.length,
                  itemBuilder: (context, index) {
                    final rec = _recordings[index];
                    final isRecording = rec.status == 'recording';
                    return NexCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      enableShadow: true,
                      enableHover: true,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            isRecording
                                ? Icons.fiber_manual_record
                                : Icons.play_circle_outline,
                            color: isRecording ? errorColor : primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recording #${rec.id}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${rec.createdAt.toLocal()}'.split('.')[0],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      rec.durationLabel,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textSecondary,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '· ${rec.fileSizeLabel}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteRecording(rec.id),
                            tooltip: l10n.delete,
                            icon: Icon(Icons.delete_outline, color: errorColor),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
