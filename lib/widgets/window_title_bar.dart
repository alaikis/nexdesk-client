import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowTitleBar extends StatelessWidget {
  final String title;
  final Widget? leading;

  const WindowTitleBar({
    super.key,
    this.title = 'LitchiViewer',
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFFA8A29E) : const Color(0xFF6B6560);
    final hoverBg = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF2F2F7);
    final closeHoverBg = isDark ? const Color(0xFFE81123) : const Color(0xFFE81123);

    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        bool isMaximized = await windowManager.isMaximized();
        if (isMaximized) {
          windowManager.unmaximize();
        } else {
          windowManager.maximize();
        }
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0D9CE),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 8),
            ] else ...[
              const SizedBox(width: 12),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFE34234),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.desktop_windows,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
            const Spacer(),
            _WindowButton(
              icon: Icons.horizontal_rule,
              iconColor: iconColor,
              hoverBg: hoverBg,
              onTap: () => windowManager.minimize(),
            ),
            _WindowButton(
              icon: Icons.crop_square,
              iconColor: iconColor,
              hoverBg: hoverBg,
              onTap: () async {
                bool isMaximized = await windowManager.isMaximized();
                if (isMaximized) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
            ),
            _WindowButton(
              icon: Icons.close,
              iconColor: iconColor,
              hoverBg: closeHoverBg,
              hoverIconColor: Colors.white,
              onTap: () async {
                await windowManager.hide();
              },
              isCloseButton: true,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color hoverBg;
  final Color? hoverIconColor;
  final VoidCallback onTap;
  final bool isCloseButton;

  const _WindowButton({
    required this.icon,
    required this.iconColor,
    required this.hoverBg,
    this.hoverIconColor,
    required this.onTap,
    this.isCloseButton = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 46,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverBg : Colors.transparent,
            borderRadius: widget.isCloseButton 
                ? const BorderRadius.only(topRight: Radius.circular(0))
                : BorderRadius.circular(0),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _isHovered && widget.hoverIconColor != null
                ? widget.hoverIconColor
                : widget.iconColor,
          ),
        ),
      ),
    );
  }
}