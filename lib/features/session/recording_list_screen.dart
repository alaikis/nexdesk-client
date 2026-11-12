import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/session_recording.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
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
    final wise = WiseTheme.of(context);
    final primaryColor = wise.primary;
    final backgroundColor = wise.background;
    final textPrimary = wise.textPrimary;
    final textSecondary = wise.textSecondary;
    final textTertiary = wise.textTertiary;
    final errorColor = wise.error;

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
                                     fontWeight: FontWeight.w600,
                                     color: textPrimary,
                                     height: 1.53,
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
                                      '路 ${rec.fileSizeLabel}',
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
