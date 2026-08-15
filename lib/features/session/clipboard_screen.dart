import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/clipboard_service.dart';
import '../../l10n/app_localizations.dart';

class ClipboardScreen extends StatefulWidget {
  final String sessionId;
  final int deviceId;
  const ClipboardScreen({super.key, required this.sessionId, required this.deviceId});

  @override
  State<ClipboardScreen> createState() => _ClipboardScreenState();
}

class _ClipboardScreenState extends State<ClipboardScreen> {
  final ClipboardService _clipboardService = ClipboardService();
  List<ClipboardEvent> _history = [];
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _clipboardService.startWatching(widget.sessionId, widget.deviceId, (event) {
      if (!mounted) return;
      setState(() => _history.insert(0, event));
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadHistory());
  }

  @override
  void dispose() {
    _clipboardService.stopWatching();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final events = await _clipboardService.getHistory(widget.sessionId);
    setState(() {
      _history = events;
      _loading = false;
    });
  }

  Future<void> _copyToRemote() async {
    await _clipboardService.copyToRemote(widget.sessionId, widget.deviceId);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copiedToRemote)),
    );
  }

  Future<void> _pasteFromRemote(String text) async {
    await _clipboardService.pasteFromRemote(widget.sessionId, widget.deviceId, text);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.pastedFromRemote)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.clipboardTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _copyToRemote,
                          icon: const Icon(Icons.copy),
                          label: Text(l10n.copyToRemote),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final controller = TextEditingController();
                            final text = await showDialog<String>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l10n.pasteText),
                                content: TextField(
                                  controller: controller,
                                  maxLines: 5,
                                  decoration: InputDecoration(labelText: l10n.textLabel),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(l10n.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, controller.text),
                                    child: Text(l10n.paste),
                                  ),
                                ],
                              ),
                            );
                            if (text != null && text.isNotEmpty) {
                              await _pasteFromRemote(text);
                            }
                          },
                          icon: const Icon(Icons.paste),
                          label: Text(l10n.pasteFromRemote),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _history.isEmpty
                      ? Center(child: Text(l10n.noClipboardHistory))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final event = _history[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  event.type == ClipboardType.text
                                      ? Icons.text_fields
                                      : Icons.image,
                                  color: const Color(0xFF007AFF),
                                ),
                                title: Text(event.payload ?? '[binary]'),
                                subtitle: Text('${event.direction} · ${event.createdAt.toString().substring(0, 19)}'),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
