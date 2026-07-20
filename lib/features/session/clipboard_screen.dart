import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/clipboard_service.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to remote')),
    );
  }

  Future<void> _pasteFromRemote(String text) async {
    await _clipboardService.pasteFromRemote(widget.sessionId, widget.deviceId, text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pasted from remote')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clipboard')),
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
                          label: const Text('Copy to Remote'),
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
                                title: const Text('Paste text'),
                                content: TextField(
                                  controller: controller,
                                  maxLines: 5,
                                  decoration: const InputDecoration(labelText: 'Text'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, controller.text),
                                    child: const Text('Paste'),
                                  ),
                                ],
                              ),
                            );
                            if (text != null && text.isNotEmpty) {
                              await _pasteFromRemote(text);
                            }
                          },
                          icon: const Icon(Icons.paste),
                          label: const Text('Paste from Remote'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _history.isEmpty
                      ? const Center(child: Text('No clipboard history'))
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
