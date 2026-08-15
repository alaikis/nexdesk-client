import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/devices/device_provider.dart';
import '../../features/screen_wall/screen_wall_provider.dart';
import '../../core/webrtc_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/nex_button.dart';
import '../../l10n/app_localizations.dart';

class ScreenWallScreen extends StatefulWidget {
  const ScreenWallScreen({super.key});

  @override
  State<ScreenWallScreen> createState() => _ScreenWallScreenState();
}

class _ScreenWallScreenState extends State<ScreenWallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DeviceProvider>().loadDevices();
        context.read<ScreenWallProvider>().connectWallStreams();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallProvider = context.watch<ScreenWallProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final wallDevices = wallProvider.selectedDeviceIds
        .map((id) => deviceProvider.devices.firstWhere(
              (d) => d.id == id,
              orElse: () => Device(id: id, name: 'Unknown', os: '', online: false),
            ))
        .toList();

    final gridSize = wallProvider.gridSize;
    final totalCells = gridSize * gridSize;
    final displayDevices = wallDevices.take(totalCells).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenWallTitle),
        actions: [
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 2, label: Text(l10n.grid2x2)),
              ButtonSegment(value: 3, label: Text(l10n.grid3x3)),
              ButtonSegment(value: 4, label: Text(l10n.grid4x4)),
            ],
            selected: {gridSize},
            onSelectionChanged: (Set<int> selection) {
              wallProvider.setGridSize(selection.first);
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: wallProvider.refreshing ? null : () => wallProvider.refresh(),
            icon: wallProvider.refreshing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            tooltip: l10n.refresh,
          ),
          IconButton(
            onPressed: _showDeviceSelectionDialog,
            icon: const Icon(Icons.add),
            tooltip: l10n.addDevices,
          ),
        ],
      ),
      body: wallDevices.isEmpty
          ? Center(
              child: EmptyState(
                message: l10n.noDevicesInWall,
                buttonText: l10n.addDevices,
                onButtonPressed: _showDeviceSelectionDialog,
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 16 / 9,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                if (index < displayDevices.length) {
                  return _WallCell(device: displayDevices[index]);
                }
                return _EmptyCell();
              },
            ),
    );
  }

  Future<void> _showDeviceSelectionDialog() async {
    final deviceProvider = context.read<DeviceProvider>();
    final wallProvider = context.read<ScreenWallProvider>();
    final devices = deviceProvider.devices;

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selected = Set<String>.from(wallProvider.selectedDeviceIds);
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10n.selectDevices),
            content: SizedBox(
              width: double.maxFinite,
              child: devices.isEmpty
                  ? Text(l10n.noDevicesAvailable)
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final isSelected = selected.contains(device.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selected.add(device.id);
                              } else {
                                selected.remove(device.id);
                              }
                            });
                          },
                          title: Text(device.name),
                          subtitle: Text(device.online ? l10n.onlineStatus : l10n.offlineStatus),
                          secondary: Icon(
                            device.online ? Icons.wifi : Icons.wifi_off,
                            color: device.online ? const Color(0xFF34C759) : Theme.of(context).colorScheme.error,
                            size: 18,
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(onPressed: () => context.pop(), child: Text(l10n.cancel)),
              FilledButton(
                onPressed: () => context.pop(selected),
                child: Text(l10n.done),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      final currentIds = wallProvider.selectedDeviceIds.toSet();
      final toAdd = result.difference(currentIds);
      final toRemove = currentIds.difference(result);

      for (final id in toAdd) {
        wallProvider.addDevice(id);
      }
      for (final id in toRemove) {
        wallProvider.removeDevice(id);
      }

      wallProvider.connectWallStreams();
    }
  }
}

class _WallCell extends StatefulWidget {
  final Device device;

  const _WallCell({required this.device});

  @override
  State<_WallCell> createState() => _WallCellState();
}

class _WallCellState extends State<_WallCell> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final wallProvider = context.watch<ScreenWallProvider>();
    final wallStream = wallProvider.getWallStream(widget.device.id);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
        color: cs.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (wallStream != null && wallStream.remoteStream != null)
              RTCVideoView(wallStream.renderer)
            else if (wallStream != null && wallStream.failed)
              _buildErrorPlaceholder(cs, l10n)
            else
              _buildWaitingPlaceholder(cs, l10n),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.device.online ? Icons.wifi : Icons.wifi_off,
                      size: 14,
                      color: widget.device.online ? const Color(0xFF34C759) : cs.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.device.name,
                      style: TextStyle(fontSize: 12, color: cs.onSurface, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => context.read<ScreenWallProvider>().removeDevice(widget.device.id),
                icon: Icon(Icons.close, size: 16, color: cs.onSurfaceVariant),
                style: IconButton.styleFrom(
                  backgroundColor: cs.surface.withValues(alpha: 0.85),
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingPlaceholder(ColorScheme cs, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.desktop_windows_outlined, size: 36, color: cs.outline),
          const SizedBox(height: 8),
          Text(
            l10n.waitingForStream,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(ColorScheme cs, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 36, color: cs.error),
          const SizedBox(height: 8),
          Text(
            l10n.connectionFailed,
            style: TextStyle(fontSize: 12, color: cs.error),
          ),
        ],
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Center(
        child: Icon(Icons.add_outlined, size: 32, color: cs.outline),
      ),
    );
  }
}
