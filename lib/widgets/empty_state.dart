import 'package:flutter/material.dart';
import 'nex_button.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String? title;
  final String? message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    this.icon,
    this.title,
    this.message,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    final textSecondary = isDark ? const Color(0xFFA8A29E) : const Color(0xFF6B6560);
    final textTertiary = isDark ? const Color(0xFF78716C) : const Color(0xFF9C958D);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.devices_other, 
              size: 48, 
              color: textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? l10n.noDevicesYet,
              style: TextStyle(
                color: textSecondary, 
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                style: TextStyle(
                  color: textTertiary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 16),
              NexButton(text: buttonText!, fullWidth: false, onPressed: onButtonPressed),
            ],
          ],
        ),
      ),
    );
  }
}
