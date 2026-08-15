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
        title: const Text('Screen Wall'),
        actions: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 2, label: Text('2×2')),
              ButtonSegment(value: 3, label: Text('3×3')),
              ButtonSegment(value: 4, label: Text('4×4')),
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
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _showDeviceSelectionDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add Devices',
          ),
        ],
      ),
      body: wallDevices.isEmpty
          ? Center(
              child: EmptyState(
                message: 'No devices in screen wall',
                buttonText: 'Add Devices',
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
          return AlertDialog(
            title: const Text('Select Devices'),
            content: SizedBox(
              width: double.maxFinite,
              child: devices.isEmpty
                  ? const Text('No devices available')
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
                          subtitle: Text(device.online ? 'Online' : 'Offline'),
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
              TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => context.pop(selected),
                child: const Text('Done'),
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

class _WallCell extends StatelessWidget {
  final Device device;

  const _WallCell({required this.device});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final wallProvider = context.watch<ScreenWallProvider>();
    final wallStream = wallProvider.getWallStream(device.id);

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
              _buildErrorPlaceholder(cs)
            else
              _buildWaitingPlaceholder(cs),
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
                      device.online ? Icons.wifi : Icons.wifi_off,
                      size: 14,
                      color: device.online ? const Color(0xFF34C759) : cs.error,
                    ),
                    const SizedBox(width: 4),
                  Text(
                    device.name,
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
                onPressed: () => context.read<ScreenWallProvider>().removeDevice(device.id),
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

  Widget _buildWaitingPlaceholder(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.desktop_windows_outlined, size: 36, color: cs.outline),
          const SizedBox(height: 8),
          Text(
            'Waiting for stream...',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 36, color: cs.error),
          const SizedBox(height: 8),
          Text(
            'Connection failed',
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
