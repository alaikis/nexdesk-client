import 'package:flutter/material.dart';
import '../core/storage_service.dart';
import '../theme/app_theme.dart';

enum ToolbarMode { floating, classic }

enum ToolbarGroup { display, audio, files, tools, end }

class ToolbarAction {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final ToolbarGroup group;
  final bool isActive;

  const ToolbarAction({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    required this.group,
    this.isActive = false,
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

// Always-dark floating overlay palette. The container is #1C1C1E regardless of
// the surrounding theme, so sub-colors use dark-mode Wise values.
const _containerColor = Color(0xFF1C1C1E);
const _iconInactive = Color(0xFF98989D);
const _hoverColor = Color(0xFF38383A);
const _dividerColor = Color(0xFF38383A);
const _labelColor = Color(0xFF98989D);
const _dragHandleColor = Color(0xFF636366);
const _destructiveColor = Color(0xFFFF453A);
const _destructiveTint = Color(0x20FF453A);

class _FloatingToolbarState extends State<FloatingToolbar> {
  static const _posKey = 'nex_toolbar_pos';
  static const _modeKey = 'nex_toolbar_mode';
  static const _fabSize = 48.0;

  Offset _position = const Offset(20, 300);
  bool _expanded = false;
  bool _dragging = false;
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

  void _handleModeToggle() {
    widget.onToggleMode();
    _persistMode();
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _dragging = true;
      _scale = _expanded ? 0.98 : 0.92;
      _opacity = _expanded ? 0.92 : 0.85;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _position = Offset(
        _position.dx + details.delta.dx,
        _position.dy + details.delta.dy,
      );
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

  void _toggleExpand() {
    if (_dragging) return;
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
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
    final fabLeft =
        isRtl ? null : (MediaQuery.of(context).size.width - _position.dx - _fabSize);
    final fabTop = _position.dy;

    return Positioned(
      right: fabRight,
      left: fabLeft,
      top: fabTop,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _opacity,
        child: Transform.scale(
          scale: _scale,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: isRtl ? Alignment.topLeft : Alignment.topRight,
            child: _expanded
                ? _buildExpandedPanel(context, groups, groupLabels)
                : _buildCollapsedButton(),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedButton() {
    return GestureDetector(
      onLongPress: _handleModeToggle,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Container(
        width: _fabSize,
        height: _fabSize,
        decoration: BoxDecoration(
          color: _containerColor,
          borderRadius: BorderRadius.circular(NexRadius.md),
          boxShadow: WiseShadows.md,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(NexRadius.md),
            child: const Center(
              child: Icon(Icons.apps, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedPanel(
    BuildContext context,
    Map<ToolbarGroup, List<ToolbarAction>> groups,
    Map<ToolbarGroup, String> groupLabels,
  ) {
    final media = MediaQuery.of(context).size;
    final panelWidth = (media.width * 0.7).clamp(200.0, 320.0);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: panelWidth),
      child: Container(
        decoration: BoxDecoration(
          color: _containerColor,
          borderRadius: BorderRadius.circular(NexRadius.md),
          boxShadow: WiseShadows.md,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDragHandle(),
            _buildHeader(),
            Container(height: 1, color: _dividerColor),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: media.height * 0.45),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildGroupWidgets(groups, groupLabels),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < 5; i++)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: const BoxDecoration(
                  color: _dragHandleColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.layers_outlined,
            tooltip: 'Switch to classic toolbar',
            onTap: _handleModeToggle,
            isActive: true,
          ),
          const Spacer(),
          _ToolbarButton(
            icon: Icons.expand_less,
            tooltip: 'Collapse',
            onTap: _toggleExpand,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupWidgets(
    Map<ToolbarGroup, List<ToolbarAction>> groups,
    Map<ToolbarGroup, String> groupLabels,
  ) {
    final widgets = <Widget>[];
    final entries = groups.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (i > 0) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Container(height: 1, color: _dividerColor),
        ));
      }
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        child: Text(
          (groupLabels[entry.key] ?? '').toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _labelColor,
            letterSpacing: 0.8,
          ),
        ),
      ));
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final action in entry.value)
              _ToolbarButton(
                icon: action.icon,
                tooltip: action.tooltip,
                onTap: () {
                  action.onTap();
                  if (mounted) setState(() => _expanded = false);
                },
                isActive: action.isActive,
                isDestructive: entry.key == ToolbarGroup.end,
              ),
          ],
        ),
      ));
    }
    return widgets;
  }
}

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDestructive;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
    this.isDestructive = false,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final primaryTint =
        isDark ? const Color(0x200A84FF) : const Color(0x20007AFF);

    final Color bgColor;
    final Color iconColor;
    if (widget.isDestructive) {
      bgColor = _destructiveTint;
      iconColor = _destructiveColor;
    } else if (widget.isActive) {
      bgColor = primaryTint;
      iconColor = primaryColor;
    } else if (_hovered || _pressed) {
      bgColor = _hoverColor;
      iconColor = _iconInactive;
    } else {
      bgColor = Colors.transparent;
      iconColor = _iconInactive;
    }

    return Semantics(
      label: widget.tooltip,
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(NexRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}
