import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/app_theme.dart';

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
    final wise = WiseTheme.of(context);
    final iconColor = wise.textSecondary;
    final hoverBg = wise.backgroundSubtle;
    final closeHoverBg = wise.error;
    final background = wise.background;
    final border = wise.border;

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
          color: background,
          border: Border(
            bottom: BorderSide(
              color: border,
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
                  color: wise.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  Icons.desktop_windows,
                  color: wise.onPrimary,
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
                color: wise.textPrimary,
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
              hoverIconColor: wise.onPrimary,
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
          duration: WiseMotionTokens.fast,
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
