import 'package:flutter/material.dart';

class NexButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;
  final Widget? icon;

  const NexButton({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.fullWidth = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onPressed == null || loading;
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 44,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? cs.surfaceContainerHighest : cs.primary,
          foregroundColor: disabled ? cs.onSurfaceVariant : cs.onPrimary,
        ),
        child: loading
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(text),
                ],
              ),
      ),
    );
  }
}
