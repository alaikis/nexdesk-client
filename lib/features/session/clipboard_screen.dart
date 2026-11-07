import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/clipboard_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final backgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final textSecondary = isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73);
    final successColor = isDark ? const Color(0xFF30D158) : const Color(0xFF34C759);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: Text(l10n.clipboardTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.copyToRemote,
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _copyToRemote,
                        icon: Icon(Icons.copy, color: primaryColor, size: 18),
                        label: Text(
                          l10n.copyToRemote,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () async {
                          final controller = TextEditingController();
                          final text = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l10n.pasteText),
                              content: TextField(
                                controller: controller,
                                maxLines: 5,
                                style: TextStyle(fontSize: 15, color: textPrimary),
                                decoration: InputDecoration(
                                  labelText: l10n.textLabel,
                                  filled: true,
                                  fillColor: surfaceColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(NexRadius.md),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(NexRadius.md),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(NexRadius.md),
                                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                                  ),
                                ),
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
                        icon: Icon(Icons.paste, color: primaryColor, size: 18),
                        label: Text(
                          l10n.pasteFromRemote,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _history.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noClipboardHistory,
                            style: TextStyle(fontSize: 15, color: textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final event = _history[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(NexRadius.md),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    event.type == ClipboardType.text
                                        ? Icons.text_fields
                                        : Icons.image,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.payload ?? '[binary]',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: textPrimary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${event.direction} · ${event.createdAt.toString().substring(0, 19)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      if (event.payload != null) {
                                        _pasteFromRemote(event.payload!);
                                      }
                                    },
                                    icon: Icon(Icons.copy, color: primaryColor, size: 18),
                                    tooltip: l10n.copyToRemote,
                                  ),
                                ],
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
