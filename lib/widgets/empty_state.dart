import 'package:flutter/material.dart';
import 'nex_button.dart';
import '../l10n/app_localizations.dart';

class EmptyState extends StatelessWidget {
  final String? message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({super.key, this.message, this.buttonText, this.onButtonPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.devices_other, size: 48, color: cs.outline),
            const SizedBox(height: 16),
            Text(l10n.noDevicesYet, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
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
