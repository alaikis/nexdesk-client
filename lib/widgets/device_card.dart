import 'package:flutter/material.dart';
import '../features/devices/device_provider.dart';
import '../theme/app_theme.dart';
import 'nex_button.dart';
import 'nex_card.dart';
import 'online_dot.dart';
import '../l10n/app_localizations.dart';

class DeviceCard extends StatefulWidget {
  final Device device;
  final VoidCallback onConnect;
  final VoidCallback onCopy;
  final VoidCallback? onWake;
  final String? wakingDeviceId;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleFavorite;
  final ValueChanged<String>? onRename;
  final bool inSelectionMode;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onConnect,
    required this.onCopy,
    this.onWake,
    this.wakingDeviceId,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.onToggleFavorite,
    this.onRename,
    this.inSelectionMode = false,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool _isRenaming = false;
  final TextEditingController _renameController = TextEditingController();

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFFE34234) : const Color(0xFFE34234);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? const Color(0xFFA8A29E) : const Color(0xFF6B6560);
    final textTertiary = isDark ? const Color(0xFF78716C) : const Color(0xFF9C958D);
    final borderColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0D9CE);
    final surfaceColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final warningColor = isDark ? const Color(0xFFD4AF37) : const Color(0xFFD4AF37);

    final card = NexCard(
      margin: const EdgeInsets.only(bottom: NexSpacing.md),
      padding: const EdgeInsets.all(NexSpacing.lg),
      color: cardColor,
      borderColor: widget.isSelected ? primaryColor : borderColor,
      enableShadow: true,
      enableHover: true,
      child: Stack(
        children: [
          Row(
            children: [
              if (widget.inSelectionMode) ...[
                Checkbox(
                  value: widget.isSelected,
                  onChanged: null,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: NexSpacing.xs),
              ],
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(NexRadius.sm),
                ),
                child: Icon(Icons.computer, size: 20, color: primaryColor),
              ),
              const SizedBox(width: NexSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isRenaming) ...[
                      TextField(
                        controller: _renameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: NexSpacing.sm, vertical: 4),
                          border: OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
                        ),
                        style: TextStyle(fontSize: 15, color: textPrimary),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            widget.onRename?.call(value.trim());
                          }
                          setState(() => _isRenaming = false);
                        },
                      ),
                    ] else ...[
                      GestureDetector(
                        onLongPress: widget.onRename != null
                            ? () {
                                _renameController.text = widget.device.name;
                                setState(() => _isRenaming = true);
                              }
                            : null,
                        child: Text(
                          widget.device.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      if (widget.device.tags.isNotEmpty) ...[
                        const SizedBox(height: NexSpacing.xs),
                        Wrap(
                          spacing: NexSpacing.xs,
                          children: [
                            ...widget.device.tags.take(3).map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(NexRadius.full),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            )),
                            if (widget.device.tags.length > 3)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(NexRadius.full),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.moreTags(widget.device.tags.length - 3),
                                  style: TextStyle(fontSize: 11, color: textTertiary),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(NexRadius.sm),
                        ),
                        child: Text(
                          widget.device.os,
                          style: TextStyle(fontSize: 13, color: textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.device.code.isNotEmpty) ...[
                GestureDetector(
                  onTap: widget.onCopy,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: NexSpacing.sm),
                    child: Text(
                      widget.device.code,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
              OnlineDot(isOnline: widget.device.online),
              const SizedBox(width: NexSpacing.md),
              NexButton(
                text: AppLocalizations.of(context)!.connect,
                onPressed: widget.onConnect,
                variant: NexButtonVariant.primary,
                size: NexButtonSize.small,
              ),
              if (widget.onWake != null) ...[
                const SizedBox(width: NexSpacing.sm),
                IconButton(
                  onPressed: widget.wakingDeviceId == widget.device.id ? null : widget.onWake,
                  tooltip: AppLocalizations.of(context)!.wakeDevice,
                  icon: widget.wakingDeviceId == widget.device.id
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.power_settings_new, size: 18, color: primaryColor),
                ),
              ],
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              onPressed: widget.onToggleFavorite,
              icon: Icon(
                widget.device.favorite ? Icons.star : Icons.star_border,
                size: 18,
                color: widget.device.favorite ? warningColor : textTertiary,
              ),
              tooltip: widget.device.favorite ? AppLocalizations.of(context)!.removeFromFavoritesTooltip : AppLocalizations.of(context)!.addToFavoritesTooltip,
            ),
          ),
        ],
      ),
    );
    if (widget.onTap != null && widget.onLongPress != null) {
      return GestureDetector(onTap: widget.onTap, onLongPress: widget.onLongPress, child: card);
    }
    if (widget.onTap != null) {
      return GestureDetector(onTap: widget.onTap, child: card);
    }
    if (widget.onLongPress != null) {
      return GestureDetector(onLongPress: widget.onLongPress, child: card);
    }
    return card;
  }
}
