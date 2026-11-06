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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final disabled = widget.onPressed == null || widget.loading;
    final isPrimary = widget.variant == NexButtonVariant.primary;
    final isDestructive = widget.variant == NexButtonVariant.destructive;

    Color backgroundColor;
    Color foregroundColor;

    if (disabled) {
      backgroundColor = colors.surfaceContainerHighest;
      foregroundColor = colors.onSurfaceVariant;
    } else if (isDestructive) {
      backgroundColor = _isHovered 
          ? const Color(0xFFD92E24) 
          : const Color(0xFFFF3B30);
      foregroundColor = Colors.white;
    } else if (isPrimary) {
      backgroundColor = _isHovered 
          ? const Color(0xFF0066CC) 
          : const Color(0xFF007AFF);
      foregroundColor = Colors.white;
    } else if (widget.variant == NexButtonVariant.secondary) {
      backgroundColor = _isHovered 
          ? const Color(0xFFE5E5EA) 
          : const Color(0xFFF2F2F7);
      foregroundColor = const Color(0xFF1D1D1F);
    } else if (widget.variant == NexButtonVariant.outline) {
      backgroundColor = Colors.transparent;
      foregroundColor = _isHovered 
          ? const Color(0xFF0066CC) 
          : const Color(0xFF007AFF);
    } else {
      backgroundColor = Colors.transparent;
      foregroundColor = colors.onSurface;
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          child: ElevatedButton(
            onPressed: disabled ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NexRadius.md),
                side: widget.variant == NexButtonVariant.outline 
                    ? BorderSide(color: disabled ? colors.outline : (isPrimary || isDestructive ? backgroundColor : const Color(0xFF007AFF)))
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
