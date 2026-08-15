import 'package:flutter/material.dart';
import '../../core/storage_service.dart';

enum ToolbarMode { floating, classic }

enum ToolbarGroup { display, audio, files, tools, end }

class ToolbarAction {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final ToolbarGroup group;

  const ToolbarAction({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    required this.group,
  });
}

class FloatingToolbar extends StatefulWidget {
  final List<ToolbarAction> actions;
  final VoidCallback onToggleMode;

  const FloatingToolbar({
    super.key,
    required this.actions,
    required this.onToggleMode,
  });

  @override
  State<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<FloatingToolbar> {
  static const _posKey = 'nex_toolbar_pos';
  static const _modeKey = 'nex_toolbar_mode';
  static const _fabSize = 56.0;
  static const _dragThreshold = 8.0;

  Offset _position = const Offset(20, 300);
  bool _expanded = false;
  bool _dragging = false;
  double _dragOffset = 0.0;
  double _scale = 1.0;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final posStr = await StorageService.getString(_posKey);
    final modeStr = await StorageService.getString(_modeKey);
    if (posStr != null) {
      final parts = posStr.split(',');
      if (parts.length == 2) {
        final dx = double.tryParse(parts[0]) ?? 20;
        final dy = double.tryParse(parts[1]) ?? 300;
        if (mounted) {
          setState(() => _position = Offset(dx, dy));
        }
      }
    }
    if (modeStr == 'classic' && mounted) {
      widget.onToggleMode();
    }
  }

  Future<void> _persistPosition() async {
    await StorageService.setString(_posKey, '${_position.dx},${_position.dy}');
  }

  Future<void> _persistMode() async {
    await StorageService.setString(_modeKey, 'floating');
  }

  void _handlePanStart(DragStartDetails details) {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }
    setState(() {
      _dragging = true;
      _scale = 0.92;
      _opacity = 0.85;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _position = Offset(
        _position.dx + details.delta.dx,
        _position.dy + details.delta.dy,
      );
      _dragOffset += details.delta.distance;
    });
  }

  Future<void> _handlePanEnd(DragEndDetails details) async {
    setState(() {
      _dragging = false;
      _scale = 1.0;
      _opacity = 1.0;
    });

    final media = MediaQuery.of(context).size;
    final clamped = Offset(
      _position.dx.clamp(0.0, media.width - _fabSize),
      _position.dy.clamp(0.0, media.height - _fabSize),
    );
    setState(() => _position = clamped);
    await _persistPosition();
  }

  void _handleLongPress() {
    widget.onToggleMode();
    _persistMode();
  }

  void _toggleExpand() {
    if (_dragging) return;
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groups = <ToolbarGroup, List<ToolbarAction>>{};
    for (final a in widget.actions) {
      groups.putIfAbsent(a.group, () => []).add(a);
    }

    final groupLabels = <ToolbarGroup, String>{
      ToolbarGroup.display: 'Display',
      ToolbarGroup.audio: 'Audio',
      ToolbarGroup.files: 'Files',
      ToolbarGroup.tools: 'Tools',
      ToolbarGroup.end: 'End',
    };

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final fabRight = isRtl ? null : _position.dx;
    final fabLeft = isRtl ? null : (MediaQuery.of(context).size.width - _position.dx - _fabSize);
    final fabTop = _position.dy;

    return Positioned(
      right: fabRight,
      left: fabLeft,
      top: fabTop,
      child: GestureDetector(
        onLongPress: _handleLongPress,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _opacity,
          child: Transform.scale(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_expanded)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.55,
                        maxHeight: MediaQuery.of(context).size.height * 0.55,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final entry in groups.entries) ...[
                              Padding(
                                padding: const EdgeInsets.only(right: 12, top: 8),
                                child: Text(
                                  groupLabels[entry.key] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurfaceVariant,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              for (final action in entry.value)
                                _ToolbarButton(
                                  icon: action.icon,
                                  label: action.label,
                                  tooltip: action.tooltip,
                                  onTap: () {
                                    action.onTap();
                                    if (mounted) setState(() => _expanded = false);
                                  },
                                  destructive: entry.key == ToolbarGroup.end,
                                ),
                              const SizedBox(height: 4),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Semantics(
                  label: _expanded ? 'Close toolbar menu' : 'Open toolbar menu',
                  child: FloatingActionButton(
                    heroTag: 'floating_toolbar_fab',
                    mini: false,
                    onPressed: _toggleExpand,
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    elevation: 4,
                    child: Icon(_expanded ? Icons.close : Icons.menu),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final bool destructive;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: destructive ? cs.errorContainer : cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: destructive ? cs.error : cs.outline,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: destructive ? cs.onErrorContainer : cs.onSurface,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: destructive ? cs.onErrorContainer : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
