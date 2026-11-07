import 'package:flutter/material.dart';
import '../../core/signaling_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class ChatPanel extends StatefulWidget {
  final SignalingService signaling;
  final String targetDeviceId;
  final void Function(ChatMessage message)? onChatMessageCallback;

  const ChatPanel({
    super.key,
    required this.signaling,
    required this.targetDeviceId,
    this.onChatMessageCallback,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.signaling.onChatMessage = _onMessage;
  }

  void _onMessage(ChatMessage message) {
    if (!mounted) return;
    setState(() {
      _messages.add(message);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.signaling.sendChatMessage(widget.targetDeviceId, text);
    _controller.clear();
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    widget.signaling.onChatMessage = null;
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final textTertiary = isDark ? const Color(0xFF636366) : const Color(0xFFAEAEB2);
    final borderColor = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(NexRadius.lg)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: NexSpacing.sm, bottom: NexSpacing.sm),
              decoration: BoxDecoration(
                color: textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NexSpacing.lg, vertical: NexSpacing.md),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 18, color: primaryColor),
                const SizedBox(width: NexSpacing.sm),
                Text(l10n.chatTitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: NexSpacing.md, vertical: NexSpacing.sm),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final isMe = msg.from == widget.signaling.deviceId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: NexSpacing.sm),
                  child: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: NexSpacing.md, vertical: NexSpacing.sm),
                            decoration: BoxDecoration(
                              color: isMe ? primaryColor : surfaceColor,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(NexRadius.md),
                                topRight: const Radius.circular(NexRadius.md),
                                bottomLeft: isMe ? const Radius.circular(NexRadius.md) : const Radius.circular(4),
                                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(NexRadius.md),
                              ),
                            ),
                            child: Text(
                              msg.content,
                              style: TextStyle(
                                color: isMe ? Colors.white : textPrimary,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(msg.timestamp),
                            style: TextStyle(fontSize: 11, color: textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: borderColor),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(NexSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(NexRadius.md),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(fontSize: 15, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: l10n.typeMessage,
                          hintStyle: TextStyle(fontSize: 15, color: textTertiary),
                          contentPadding: const EdgeInsets.symmetric(horizontal: NexSpacing.md, vertical: NexSpacing.md),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: NexSpacing.sm),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Material(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(NexRadius.md),
                      child: InkWell(
                        onTap: _send,
                        borderRadius: BorderRadius.circular(NexRadius.md),
                        child: const Icon(Icons.send, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
