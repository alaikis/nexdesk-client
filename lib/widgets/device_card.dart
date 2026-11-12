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
    final wise = WiseTheme.of(context);
    final primaryColor = wise.primary;
    final textPrimary = wise.textPrimary;
    final textSecondary = wise.textSecondary;
    final textTertiary = wise.textTertiary;
    final borderColor = wise.border;
    final surfaceColor = wise.backgroundSubtle;
    final cardColor = wise.card;
    final warningColor = wise.warning;

    final card = NexCard(
      margin: EdgeInsets.only(bottom: wise.spacing.md),
      padding: EdgeInsets.all(wise.spacing.lg),
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
                SizedBox(width: wise.spacing.xs),
              ],
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: wise.primaryTint,
                  borderRadius: BorderRadius.circular(wise.radius.sm),
                ),
                child: Icon(Icons.computer, size: 20, color: primaryColor),
              ),
              SizedBox(width: wise.spacing.md),
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
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        SizedBox(height: wise.spacing.xs),
                        Wrap(
                          spacing: wise.spacing.xs,
                          children: [
                            ...widget.device.tags.take(3).map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(wise.radius.full),
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
                                  borderRadius: BorderRadius.circular(wise.radius.full),
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
                          borderRadius: BorderRadius.circular(wise.radius.sm),
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
                    padding: EdgeInsets.symmetric(horizontal: wise.spacing.sm),
                    child: Text(
                      widget.device.code,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: WiseTypographyTokens.monoFamily,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
              OnlineDot(isOnline: widget.device.online),
              SizedBox(width: wise.spacing.md),
              NexButton(
                text: AppLocalizations.of(context)!.connect,
                onPressed: widget.onConnect,
                variant: NexButtonVariant.primary,
                size: NexButtonSize.small,
              ),
              if (widget.onWake != null) ...[
                SizedBox(width: wise.spacing.sm),
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
