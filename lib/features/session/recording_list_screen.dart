import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/session_recording.dart';
import '../../l10n/app_localizations.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recordingsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _recordings.isEmpty
              ? Center(child: Text(l10n.noRecordingsYet))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _recordings.length,
                  itemBuilder: (context, index) {
                    final rec = _recordings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          rec.status == 'recording'
                              ? Icons.fiber_manual_record
                              : Icons.play_circle_outline,
                          color: rec.statusColor,
                        ),
                        title: Text('Recording #${rec.id}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${rec.createdAt.toLocal()}'.split('.')[0]),
                            const SizedBox(height: 4),
                            Text('${rec.durationLabel} · ${rec.fileSizeLabel}'),
                          ],
                        ),
                        trailing: IconButton(
                          onPressed: () => _deleteRecording(rec.id),
                          tooltip: l10n.delete,
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
