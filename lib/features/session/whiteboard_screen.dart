import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/signaling_service.dart';
import '../../widgets/nex_card.dart';
import '../../widgets/nex_button.dart';
import '../../theme/app_theme.dart';

class WhiteboardScreen extends StatefulWidget {
  final SignalingService signaling;
  final String sessionId;
  final String localDeviceId;
  final void Function(Map<String, dynamic> event)? onRemoteEvent;

  const WhiteboardScreen({
    super.key,
    required this.signaling,
    required this.sessionId,
    required this.localDeviceId,
    this.onRemoteEvent,
  });

  @override
  State<WhiteboardScreen> createState() => WhiteboardScreenState();
}

class WhiteboardScreenState extends State<WhiteboardScreen> {
  final List<_Stroke> _strokes = [];
  final List<_Stroke> _undoStack = [];
  _Tool _tool = _Tool.pen;
  Color _color = const Color(0xFF007AFF);
  double _size = 4.0;
  bool _eraserUsed = false;

  final List<_Stroke> _remoteStrokes = [];
  final Map<String, Color> _userColors = {};

  static const _maxUndo = 20;
  static const _defaultColors = <Color>[
    Color(0xFF007AFF),
    Color(0xFFFF3B30),
    Color(0xFF34C759),
    Color(0xFFFF9500),
    Color(0xFFAF52DE),
  ];

  @override
  void initState() {
    super.initState();
    _color = _userColorFor(widget.localDeviceId);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: true,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(color: cs.surface.withOpacity(0.9)),
              ),
            ),
            CustomPaint(
              painter: _WhiteboardPainter(
                strokes: _strokes,
                remoteStrokes: _remoteStrokes,
                userColors: _userColors,
              ),
              size: Size.infinite,
            ),
            _buildToolbar(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(ColorScheme cs) {
    final selectedTool = _tool;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Center(
        child: NexCard(
          padding: const EdgeInsets.symmetric(horizontal: NexSpacing.lg, vertical: NexSpacing.md),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToolButton(
                  icon: Icons.edit,
                  label: 'Pen',
                  selected: selectedTool == _Tool.pen,
                  onTap: () => setState(() => _tool = _Tool.pen),
                ),
                const SizedBox(width: NexSpacing.sm),
                _ToolButton(
                  icon: Icons.backspace,
                  label: 'Eraser',
                  selected: selectedTool == _Tool.eraser,
                  onTap: () => setState(() => _tool = _Tool.eraser),
                ),
                const SizedBox(width: NexSpacing.sm),
                ..._defaultColors.map(
                  (c) => GestureDetector(
                    onTap: () => setState(() {
                      _tool = _Tool.pen;
                      _color = c;
                      _eraserUsed = false;
                    }),
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color.value == c.value && selectedTool == _Tool.pen
                              ? cs.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: NexSpacing.sm),
                SizedBox(
                  width: 120,
                  child: Row(
                    children: [
                      const Icon(Icons.line_weight, size: 18, color: Colors.white70),
                      Expanded(
                        child: Slider(
                          value: _size,
                          min: 1,
                          max: 20,
                          divisions: 19,
                          label: _size.round().toString(),
                          onChanged: (v) => setState(() => _size = v),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: NexSpacing.sm),
                _ToolButton(
                  icon: Icons.undo,
                  label: 'Undo',
                  selected: false,
                  onTap: _undo,
                ),
                const SizedBox(width: NexSpacing.sm),
                _ToolButton(
                  icon: Icons.delete_outline,
                  label: 'Clear',
                  selected: false,
                  destructive: true,
                  onTap: _clearAll,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final point = details.localPosition;
    _startStroke(point);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final point = details.localPosition;
    _appendPoint(point);
  }

  void _onPanEnd(DragEndDetails details) {
    _endStroke();
  }

  void _startStroke(Offset point) {
    final stroke = _Stroke(
      points: [point],
      color: _tool == _Tool.eraser ? Colors.transparent : _color,
      size: _size,
      tool: _tool,
      userId: widget.localDeviceId,
    );
    setState(() {
      _strokes.add(stroke);
      _undoStack.clear();
      if (_undoStack.length > _maxUndo) {
        _undoStack.removeAt(0);
      }
    });
    _sendEvent('draw', {
      'action': 'draw',
      'x': point.dx,
      'y': point.dy,
      'color': _tool == _Tool.eraser ? 'transparent' : _color.toHex(),
      'size': _size,
      'user_id': widget.localDeviceId,
      'stroke_start': true,
    });
  }

  void _appendPoint(Offset point) {
    if (_strokes.isEmpty) return;
    final last = _strokes.last;
    if (last.userId != widget.localDeviceId) return;
    setState(() {
      last.points.add(point);
    });
    _sendEvent('draw', {
      'action': 'draw',
      'x': point.dx,
      'y': point.dy,
      'color': _tool == _Tool.eraser ? 'transparent' : _color.toHex(),
      'size': _size,
      'user_id': widget.localDeviceId,
      'stroke_start': false,
    });
  }

  void _endStroke() {
    if (_strokes.isEmpty) return;
    _sendEvent('draw', {
      'action': 'draw',
      'stroke_end': true,
      'user_id': widget.localDeviceId,
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    final last = _strokes.removeLast();
    _undoStack.add(last);
    if (_undoStack.length > _maxUndo) {
      _undoStack.removeAt(0);
    }
    setState(() {});
    _sendEvent('erase', {
      'action': 'erase',
      'user_id': widget.localDeviceId,
    });
  }

  void _clearAll() {
    setState(() {
      _strokes.clear();
      _remoteStrokes.clear();
    });
    _sendEvent('clear', {
      'action': 'clear',
      'user_id': widget.localDeviceId,
    });
  }

  void _sendEvent(String action, Map<String, dynamic> payload) {
    widget.signaling.sendWhiteboard(widget.sessionId, payload);
  }

  void handleRemoteEvent(Map<String, dynamic> event) {
    final action = event['action'] as String? ?? 'draw';
    final userId = event['user_id'] as String? ?? 'remote';
    final colorHex = event['color'] as String?;
    final size = (event['size'] as num?)?.toDouble() ?? 4.0;
    final x = (event['x'] as num?)?.toDouble();
    final y = (event['y'] as num?)?.toDouble();

    Color? color;
    if (colorHex != null && colorHex != 'transparent') {
      color = _parseColor(colorHex);
    }

    if (action == 'clear') {
      setState(() {
        _remoteStrokes.clear();
      });
      return;
    }

    if (action == 'erase') {
      if (_remoteStrokes.isNotEmpty) {
        setState(() {
          _remoteStrokes.removeLast();
        });
      }
      return;
    }

    if (x == null || y == null) return;

    final userColor = _userColorFor(userId);
    setState(() {
      if (_remoteStrokes.isEmpty || _remoteStrokes.last.userId != userId) {
        _remoteStrokes.add(_Stroke(
          points: [Offset(x, y)],
          color: color ?? userColor,
          size: size,
          tool: color == null ? _Tool.eraser : _Tool.pen,
          userId: userId,
        ));
      } else {
        final last = _remoteStrokes.last;
        last.points.add(Offset(x, y));
      }
    });
  }

  Color _userColorFor(String userId) {
    if (_userColors.containsKey(userId)) {
      return _userColors[userId]!;
    }
    final hash = userId.hashCode;
    final index = (hash & 0x7fffffff) % _defaultColors.length;
    final color = _defaultColors[index];
    _userColors[userId] = color;
    return color;
  }

  Color? _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) {
      buffer.write('FF');
      buffer.write(hex.replaceFirst('#', ''));
    } else if (hex.length == 8) {
      buffer.write(hex.replaceFirst('#', ''));
    } else {
      return null;
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

enum _Tool { pen, eraser }

class _Stroke {
  final List<Offset> points;
  final Color color;
  final double size;
  final _Tool tool;
  final String userId;

  _Stroke({
    required this.points,
    required this.color,
    required this.size,
    required this.tool,
    required this.userId,
  });
}

class _WhiteboardPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final List<_Stroke> remoteStrokes;
  final Map<String, Color> userColors;

  _WhiteboardPainter({
    required this.strokes,
    required this.remoteStrokes,
    required this.userColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      _paintStroke(canvas, s);
    }
    for (final s in remoteStrokes) {
      _paintStroke(canvas, s);
    }
  }

  void _paintStroke(Canvas canvas, _Stroke s) {
    if (s.points.isEmpty) return;
    if (s.tool == _Tool.eraser) {
      final eraser = Paint()
        ..color = Colors.white
        ..strokeWidth = s.size * 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = BlendMode.dstOut;
      _drawPath(canvas, s.points, eraser);
      return;
    }
    final paint = Paint()
      ..color = s.color
      ..strokeWidth = s.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    _drawPath(canvas, s.points, paint);
  }

  void _drawPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length == 1) {
      final p = points.first;
      canvas.drawCircle(p, paint.strokeWidth / 2, paint);
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    if (points.length > 1) {
      final last = points.last;
      path.lineTo(last.dx, last.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.remoteStrokes != remoteStrokes ||
        oldDelegate.userColors != userColors;
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool destructive;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: NexSpacing.md, vertical: NexSpacing.sm),
        decoration: BoxDecoration(
          color: destructive
              ? cs.errorContainer
              : selected
                  ? cs.primaryContainer
                  : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(NexRadius.md),
          border: Border.all(
            color: destructive ? cs.error : selected ? cs.primary : cs.outline,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: destructive
                  ? cs.onErrorContainer
                  : selected
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: destructive
                    ? cs.onErrorContainer
                    : selected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _ColorHex on Color {
  String toHex() {
    final r = (red >> 0) & 0xFF;
    final g = (green >> 0) & 0xFF;
    final b = (blue >> 0) & 0xFF;
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }
}
