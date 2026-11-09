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
    final wise = WiseTheme.of(context);
    final colors = Theme.of(context).colorScheme;

    final backgroundColor = widget.color ?? colors.surface;
    final borderColorValue = widget.borderColor ?? wise.border;

    List<BoxShadow>? boxShadow;
    if (widget.enableShadow) {
      boxShadow = (_isHovered && widget.enableHover) ? wise.shadows.md : wise.shadows.sm;
    }

    Widget cardContent = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(wise.radius.lg),
        border: Border.all(color: borderColorValue),
        boxShadow: boxShadow,
      ),
      child: Padding(
        padding: widget.padding ?? EdgeInsets.all(wise.spacing.lg),
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
            duration: WiseMotionTokens.normal,
            curve: WiseMotionTokens.defaultCurve,
            child: cardContent,
          ),
        ),
      );
    }

    return cardContent;
  }
}
