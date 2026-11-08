import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NexCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final bool enableShadow;
  final bool enableHover;

  const NexCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
    this.enableShadow = false,
    this.enableHover = false,
  });

  @override
  State<NexCard> createState() => _NexCardState();
}

class _NexCardState extends State<NexCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final backgroundColor = widget.color ?? colors.surface;
    final borderColorValue = widget.borderColor ?? (isDark 
        ? const Color(0xFF3A3A3A) 
        : const Color(0xFFE0D9CE));

    List<BoxShadow>? boxShadow;
    if (widget.enableShadow) {
      if (_isHovered && widget.enableHover) {
        boxShadow = isDark 
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ];
      } else {
        boxShadow = isDark 
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ];
      }
    }

    Widget cardContent = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(NexRadius.lg),
        border: Border.all(color: borderColorValue),
        boxShadow: boxShadow,
      ),
      child: Padding(
        padding: widget.padding ?? EdgeInsets.all(NexSpacing.lg),
        child: widget.child,
      ),
    );

    if (widget.onTap != null || widget.enableHover) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            child: cardContent,
          ),
        ),
      );
    }

    return cardContent;
  }
}
