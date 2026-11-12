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
    final wise = WiseTheme.of(context);
    final primaryColor = wise.primary;
    final cardColor = wise.card;
    final surfaceColor = wise.surface;
    final textPrimary = wise.textPrimary;
    final textTertiary = wise.textTertiary;
    final borderColor = wise.border;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(wise.radius.lg)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: EdgeInsets.only(top: wise.spacing.sm, bottom: wise.spacing.sm),
              decoration: BoxDecoration(
                color: textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: wise.spacing.lg, vertical: wise.spacing.md),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 18, color: primaryColor),
                SizedBox(width: wise.spacing.sm),
                Text(l10n.chatTitle, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: wise.spacing.md, vertical: wise.spacing.sm),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final isMe = msg.from == widget.signaling.deviceId;
                return Padding(
                  padding: EdgeInsets.only(bottom: wise.spacing.sm),
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
                            padding: EdgeInsets.symmetric(horizontal: wise.spacing.md, vertical: wise.spacing.sm),
                            decoration: BoxDecoration(
                              color: isMe ? primaryColor : surfaceColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(wise.radius.medium),
                                topRight: Radius.circular(wise.radius.medium),
                                bottomLeft: isMe ? Radius.circular(wise.radius.medium) : const Radius.circular(4),
                                bottomRight: isMe ? const Radius.circular(4) : Radius.circular(wise.radius.medium),
                              ),
                            ),
                            child: Text(
                              msg.content,
                              style: TextStyle(
                                color: isMe ? wise.onPrimary : textPrimary,
                                fontSize: 15,
                                height: 1.53,
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
              padding: EdgeInsets.all(wise.spacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(wise.radius.medium),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(fontSize: 15, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: l10n.typeMessage,
                          hintStyle: TextStyle(fontSize: 15, color: textTertiary),
                          contentPadding: EdgeInsets.symmetric(horizontal: wise.spacing.md, vertical: wise.spacing.md),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  SizedBox(width: wise.spacing.sm),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Material(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(wise.radius.medium),
                      child: InkWell(
                        onTap: _send,
                        borderRadius: BorderRadius.circular(wise.radius.medium),
                        child: Icon(Icons.send, size: 20, color: wise.onPrimary),
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
