import 'package:flutter/material.dart';
import '../features/devices/device_provider.dart';
import 'nex_card.dart';
import 'online_dot.dart';

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
    final cs = Theme.of(context).colorScheme;
    final card = NexCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderColor: widget.isSelected ? cs.primary : null,
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
                const SizedBox(width: 4),
              ],
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.computer, size: 20, color: cs.primary),
              ),
              const SizedBox(width: 12),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          border: OutlineInputBorder(borderSide: BorderSide(color: cs.outline)),
                        ),
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
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: cs.onSurface),
                        ),
                      ),
                      if (widget.device.tags.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: [
                            ...widget.device.tags.take(3).map((tag) => Chip(
                              label: Text(tag, style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer)),
                              backgroundColor: cs.primaryContainer,
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                            )),
                            if (widget.device.tags.length > 3)
                              Chip(
                                label: Text('+${widget.device.tags.length - 3}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                backgroundColor: cs.surfaceContainerHighest,
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(widget.device.os, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              if (widget.device.code.isNotEmpty) ...[
                GestureDetector(
                  onTap: widget.onCopy,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      widget.device.code,
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
              OnlineDot(isOnline: widget.device.online),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: widget.onConnect,
                child: const Text('Connect'),
              ),
              if (widget.onWake != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.wakingDeviceId == widget.device.id ? null : widget.onWake,
                  tooltip: 'Wake',
                  icon: widget.wakingDeviceId == widget.device.id
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.power_settings_new, size: 18, color: cs.primary),
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
                color: widget.device.favorite ? Colors.amber : cs.onSurfaceVariant,
              ),
              tooltip: widget.device.favorite ? 'Remove from favorites' : 'Add to favorites',
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
