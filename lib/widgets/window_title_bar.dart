import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/app_theme.dart';
import 'litchi_logo.dart';

/// 自绘窗口标题栏（原生标题栏已在 main.dart 通过 TitleBarStyle.hidden 隐藏）。
///
/// 设计要点：
/// - 40px 高，底部一根发丝分隔线，与内容区自然分层
/// - 左侧品牌区：柔和主色底板 + 荔枝 Logo + 应用名
/// - 右侧窗口控制：最小化 / 最大化还原 / 关闭，悬停高亮、圆角过渡
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
    final background = wise.background;
    final iconColor = wise.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        final isMaximized = await windowManager.isMaximized();
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
            bottom: BorderSide(color: wise.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ] else ...[
              _BrandMark(logoSize: 18),
              const SizedBox(width: 10),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: wise.textPrimary,
                letterSpacing: 0.2,
                decoration: TextDecoration.none,
              ),
            ),
            const Spacer(),
            _WindowButton(
              icon: Icons.horizontal_rule_rounded,
              iconColor: iconColor,
              hoverBg: wise.surface,
              onTap: () => windowManager.minimize(),
            ),
            const SizedBox(width: 2),
            _WindowButton(
              icon: Icons.crop_square_rounded,
              iconSize: 13,
              iconColor: iconColor,
              hoverBg: wise.surface,
              onTap: () async {
                final isMaximized = await windowManager.isMaximized();
                if (isMaximized) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
            ),
            const SizedBox(width: 2),
            _WindowButton(
              icon: Icons.close_rounded,
              iconColor: iconColor,
              hoverBg: wise.error,
              hoverIconColor: wise.onPrimary,
              onTap: () async {
                await windowManager.hide();
              },
              isCloseButton: true,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

/// 品牌标记：主色柔光圆角底板 + 荔枝矢量 Logo。
class _BrandMark extends StatelessWidget {
  final double logoSize;

  const _BrandMark({this.logoSize = 18});

  @override
  Widget build(BuildContext context) {
    final wise = WiseTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: wise.primarySoft,
        borderRadius: BorderRadius.circular(wise.radius.medium),
      ),
      child: LitchiLogo(size: logoSize),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final Color hoverBg;
  final Color? hoverIconColor;
  final VoidCallback onTap;
  final bool isCloseButton;

  const _WindowButton({
    required this.icon,
    this.iconSize = 15,
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
    final wise = WiseTheme.of(context);
    final borderRadius = BorderRadius.circular(
      widget.isCloseButton ? wise.radius.medium : wise.radius.medium,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: WiseMotionTokens.fast,
          curve: WiseMotionTokens.defaultCurve,
          width: 40,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverBg : Colors.transparent,
            borderRadius: borderRadius,
          ),
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: _isHovered && widget.hoverIconColor != null
                ? widget.hoverIconColor
                : widget.iconColor,
          ),
        ),
      ),
    );
  }
}