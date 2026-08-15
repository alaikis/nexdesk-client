import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/signaling_service.dart';
import '../../features/session/session_provider.dart';

class _AnsiSpan {
  final String text;
  final Color? color;
  final Color? background;
  final bool bold;
  final bool dim;
  final bool italic;
  final bool underline;

  _AnsiSpan({
    required this.text,
    this.color,
    this.background,
    this.bold = false,
    this.dim = false,
    this.italic = false,
    this.underline = false,
  });
}

const _ansiColors = {
  0: Color(0xFF000000),
  1: Color(0xFF800000),
  2: Color(0xFF008000),
  3: Color(0xFF808000),
  4: Color(0xFF000080),
  5: Color(0xFF800080),
  6: Color(0xFF008080),
  7: Color(0xFFC0C0C0),
  8: Color(0xFF808080),
  9: Color(0xFFFF0000),
  10: Color(0xFF00FF00),
  11: Color(0xFFFFFF00),
  12: Color(0xFF0000FF),
  13: Color(0xFFFF00FF),
  14: Color(0xFF00FFFF),
  15: Color(0xFFFFFFFF),
};

TextSpan _parseAnsi(String input) {
  final spans = <_AnsiSpan>[];
  final regex = RegExp(r'\x1b\[([0-9;]*)m');
  int start = 0;
  int currentColor = 7;
  int currentBg = 0;
  bool bold = false;
  bool dim = false;
  bool italic = false;
  bool underline = false;

  for (final match in regex.allMatches(input)) {
    if (match.start > start) {
      spans.add(_AnsiSpan(
        text: input.substring(start, match.start),
        color: _ansiColors[currentColor],
        background: _ansiColors[currentBg],
        bold: bold,
        dim: dim,
        italic: italic,
        underline: underline,
      ));
    }
    final codes = match.group(1)!.split(';').map(int.tryParse).whereType<int>().toList();
    if (codes.isEmpty) codes.add(0);
    for (final code in codes) {
      switch (code) {
        case 0:
          currentColor = 7;
          currentBg = 0;
          bold = false;
          dim = false;
          italic = false;
          underline = false;
          break;
        case 1:
          bold = true;
          break;
        case 2:
          dim = true;
          break;
        case 3:
          italic = true;
          break;
        case 4:
          underline = true;
          break;
        case 22:
          bold = false;
          dim = false;
          break;
        case 23:
          italic = false;
          break;
        case 24:
          underline = false;
          break;
        case 30:
        case 31:
        case 32:
        case 33:
        case 34:
        case 35:
        case 36:
        case 37:
          currentColor = code - 30;
          break;
        case 38:
          currentColor = 15;
          break;
        case 39:
          currentColor = 7;
          break;
        case 40:
        case 41:
        case 42:
        case 43:
        case 44:
        case 45:
        case 46:
        case 47:
          currentBg = code - 40;
          break;
        case 48:
          currentBg = 0;
          break;
        case 49:
          currentBg = 0;
          break;
        case 90:
        case 91:
        case 92:
        case 93:
        case 94:
        case 95:
        case 96:
        case 97:
          currentColor = code - 90 + 8;
          break;
        case 100:
        case 101:
        case 102:
        case 103:
        case 104:
        case 105:
        case 106:
        case 107:
          currentBg = code - 100 + 8;
          break;
      }
    }
    start = match.end;
  }
  if (start < input.length) {
    spans.add(_AnsiSpan(
      text: input.substring(start),
      color: _ansiColors[currentColor],
      background: _ansiColors[currentBg],
      bold: bold,
      dim: dim,
      italic: italic,
      underline: underline,
    ));
  }

  return TextSpan(
    children: spans.map((s) {
      final color = s.dim
          ? (s.color ?? const Color(0xFF000000)).withValues(alpha: 0.5)
          : s.color;
      return TextSpan(
        text: s.text,
        style: TextStyle(
          color: color,
          backgroundColor: s.background,
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.4,
          fontWeight: s.bold ? FontWeight.bold : FontWeight.normal,
          fontStyle: s.italic ? FontStyle.italic : FontStyle.normal,
          decoration: s.underline ? TextDecoration.underline : TextDecoration.none,
        ),
      );
    }).toList(),
  );
}

class RemoteTerminalScreen extends StatefulWidget {
  final String sessionId;
  const RemoteTerminalScreen({super.key, required this.sessionId});

  @override
  State<RemoteTerminalScreen> createState() => _RemoteTerminalScreenState();
}

class _RemoteTerminalScreenState extends State<RemoteTerminalScreen> {
  SignalingService? _signaling;
  StreamSubscription<dynamic>? _terminalSub;
  final List<String> _lines = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _connected = false;
  String? _error;
  int _columns = 80;
  int _rows = 24;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void dispose() {
    _terminalSub?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _listen() {
    final sp = context.read<SessionProvider>();
    _signaling = sp.signalingService;
    if (_signaling == null) {
      setState(() => _error = 'Signaling not ready');
      return;
    }

    _terminalSub = _signaling!.messages.listen((msg) {
      if (msg.type != SignalingMessageType.remoteTerminal) return;
      if (msg.sessionId != widget.sessionId) return;
      final payload = Map<String, dynamic>.from(msg.payload);
      final action = payload['action'] as String? ?? '';

      switch (action) {
        case 'output':
          final data = payload['data'] as String? ?? '';
          if (mounted) {
            setState(() {
              _lines.add(data);
              if (_lines.length > 2000) {
                _lines.removeRange(0, _lines.length - 2000);
              }
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
              }
            });
          }
          break;
        case 'connected':
          if (mounted) {
            setState(() => _connected = true);
          }
          break;
        case 'disconnected':
          if (mounted) {
            setState(() => _connected = false);
          }
          break;
        case 'resize':
          final cols = payload['columns'] as int? ?? _columns;
          final rows = payload['rows'] as int? ?? _rows;
          if (mounted) {
            setState(() {
              _columns = cols;
              _rows = rows;
            });
          }
          break;
        case 'error':
          final err = payload['message'] as String? ?? 'Terminal error';
          if (mounted) {
            setState(() => _error = err);
          }
          break;
      }
    });
  }

  Future<void> _sendInput(String text) async {
    if (_signaling == null) return;
    final sp = context.read<SessionProvider>();
    final session = sp.activeSession;
    if (session == null) return;
    final target = _localDeviceIdIsController(session)
        ? session.controlleeDeviceId
        : session.controllerDeviceId;
    _signaling!.sendRemoteTerminal(target, widget.sessionId, {
      'action': 'input',
      'data': text,
      'from': _signaling!.deviceId,
    });
  }

  bool _localDeviceIdIsController(Session session) {
    return session.controllerDeviceId == _signaling?.deviceId;
  }

  Future<void> _requestTerminal() async {
    final sp = context.read<SessionProvider>();
    final session = sp.activeSession;
    if (session == null || _signaling == null) return;
    final target = _localDeviceIdIsController(session)
        ? session.controlleeDeviceId
        : session.controllerDeviceId;
    _signaling!.sendRemoteTerminal(target, widget.sessionId, {
      'action': 'start',
      'shell': _defaultShell(),
      'columns': _columns,
      'rows': _rows,
      'from': _signaling!.deviceId,
    });
  }

  String _defaultShell() {
    if (Theme.of(context).platform == TargetPlatform.windows) return 'cmd.exe';
    return 'bash';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Terminal'),
        actions: [
          IconButton(
            icon: Icon(_connected ? Icons.link : Icons.link_off),
            onPressed: _requestTerminal,
            tooltip: _connected ? 'Reconnect' : 'Connect',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              if (mounted) setState(() => _lines.clear());
            },
            tooltip: 'Clear',
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _requestTerminal,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: const Color(0xFF0C0C0C),
                    padding: const EdgeInsets.all(8),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _lines.length,
                      itemBuilder: (context, index) {
                        return RichText(text: _parseAnsi(_lines[index]));
                      },
                    ),
                  ),
                ),
                Container(
                  color: const Color(0xFF1C1C1E),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter command...',
                            hintStyle: TextStyle(color: Color(0xFF8E8E93), fontFamily: 'monospace'),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (value) {
                            if (value.isEmpty) return;
                            _sendInput('$value\n');
                            _inputController.clear();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, size: 18),
                        onPressed: () {
                          final value = _inputController.text;
                          if (value.isEmpty) return;
                          _sendInput('$value\n');
                          _inputController.clear();
                        },
                        tooltip: 'Send',
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
