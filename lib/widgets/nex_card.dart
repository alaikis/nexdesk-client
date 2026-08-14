import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NexCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  const NexCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: color ?? cs.surface,
          borderRadius: BorderRadius.circular(NexRadius.lg),
          border: Border.all(color: borderColor ?? cs.outline),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(NexSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}
