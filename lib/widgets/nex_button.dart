import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NexButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  final Widget? icon;
  final NexButtonVariant variant;
  final NexButtonSize size;

  const NexButton({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.fullWidth = false,
    this.icon,
    this.variant = NexButtonVariant.primary,
    this.size = NexButtonSize.medium,
  });

  @override
  State<NexButton> createState() => _NexButtonState();
}

class _NexButtonState extends State<NexButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final wise = WiseTheme.of(context);
    final disabled = widget.onPressed == null || widget.loading;

    final primaryColor = wise.primary;
    final primaryHover = wise.primaryHover;
    final destructiveColor = wise.error;
    final destructiveHover = wise.error;
    final surfaceColor = wise.surface;
    final surfaceHover = wise.backgroundSubtle;
    final borderColor = wise.border;
    final textPrimary = wise.textPrimary;
    final textSecondary = wise.textSecondary;
    final onPrimary = wise.onPrimary;

    Color backgroundColor;
    Color foregroundColor;
    Color? borderSideColor;

    if (disabled) {
      backgroundColor = surfaceHover;
      foregroundColor = textSecondary;
    } else if (widget.variant == NexButtonVariant.destructive) {
      backgroundColor = _isHovered ? destructiveHover : destructiveColor;
      foregroundColor = onPrimary;
    } else if (widget.variant == NexButtonVariant.primary) {
      backgroundColor = _isHovered ? primaryHover : primaryColor;
      foregroundColor = onPrimary;
    } else if (widget.variant == NexButtonVariant.secondary) {
      backgroundColor = _isHovered ? surfaceHover : surfaceColor;
      foregroundColor = textPrimary;
    } else if (widget.variant == NexButtonVariant.outline) {
      backgroundColor = Colors.transparent;
      foregroundColor = primaryColor;
      borderSideColor = borderColor;
    } else {
      backgroundColor = _isHovered ? surfaceColor : Colors.transparent;
      foregroundColor = textPrimary;
    }

    final height = widget.size == NexButtonSize.small ? 36.0
        : widget.size == NexButtonSize.large ? 52.0
        : 44.0;

    final horizontalPadding = widget.size == NexButtonSize.small ? 16.0
        : widget.size == NexButtonSize.large ? 24.0
        : 20.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: SizedBox(
        width: widget.fullWidth ? double.infinity : null,
        height: height,
        child: Listener(
          onPointerDown: (_) => setState(() => _isPressed = true),
          onPointerUp: (_) => setState(() => _isPressed = false),
          onPointerCancel: (_) => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed && !disabled ? 0.97 : 1.0,
            duration: WiseMotionTokens.fast,
            curve: WiseMotionTokens.defaultCurve,
            child: ElevatedButton(
              onPressed: disabled ? null : widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(wise.radius.medium),
                  side: widget.variant == NexButtonVariant.outline && !disabled && borderSideColor != null
                      ? BorderSide(color: borderSideColor)
                      : BorderSide.none,
                ),
                textStyle: TextStyle(
                  fontSize: widget.size == NexButtonSize.small ? 13
                      : widget.size == NexButtonSize.large ? 17
                      : 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: widget.loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foregroundColor,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          widget.icon!,
                          const SizedBox(width: 8),
                        ],
                        Text(widget.text),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

enum NexButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
}

enum NexButtonSize {
  small,
  medium,
  large,
}
