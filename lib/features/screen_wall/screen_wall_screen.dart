import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/devices/device_provider.dart';
import '../../features/screen_wall/screen_wall_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

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

  NexColors _colors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const NexColors.dark() : const NexColors.light();
  }

  @override
  Widget build(BuildContext context) {
    final wallProvider = context.watch<ScreenWallProvider>();
    final deviceProvider = context.watch<DeviceProvider>();
    final l10n = AppLocalizations.of(context)!;
    final c = _colors(context);

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
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.screenWallTitle,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          _GridPillSelector(
            gridSize: gridSize,
            onChanged: wallProvider.setGridSize,
            colors: c,
            l10n: l10n,
          ),
          SizedBox(width: NexSpacing.sm),
          IconButton(
            onPressed: wallProvider.refreshing ? null : () => wallProvider.refresh(),
            icon: wallProvider.refreshing
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c.primary))
                : Icon(Icons.refresh, color: c.textSecondary),
            tooltip: l10n.refresh,
          ),
          IconButton(
            onPressed: _showDeviceSelectionDialog,
            icon: Icon(Icons.add, color: c.primary),
            tooltip: l10n.addDevices,
          ),
        ],
      ),
      body: wallDevices.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_outlined, size: 48, color: c.textTertiary),
                  SizedBox(height: NexSpacing.md),
                  Text(l10n.noDevicesInWall, style: TextStyle(fontSize: 15, color: c.textSecondary)),
                  SizedBox(height: NexSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: _showDeviceSelectionDialog,
                    icon: Icon(Icons.add, size: 18),
                    label: Text(l10n.addDevices),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(NexSpacing.md),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                  crossAxisSpacing: NexSpacing.md,
                  mainAxisSpacing: NexSpacing.md,
                  childAspectRatio: 16 / 9,
                ),
                itemCount: totalCells,
                itemBuilder: (context, index) {
                  if (index < displayDevices.length) {
                    return _WallCell(device: displayDevices[index]);
                  }
                  return _EmptyCell(onTap: _showDeviceSelectionDialog);
                },
              ),
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
          final dc = _colors(context);
          return AlertDialog(
            backgroundColor: dc.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NexRadius.lg),
              side: BorderSide(color: dc.border),
            ),
            title: Text(l10n.selectDevices, style: TextStyle(color: dc.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
            content: SizedBox(
              width: double.maxFinite,
              child: devices.isEmpty
                  ? Text(l10n.noDevicesAvailable, style: TextStyle(color: dc.textSecondary))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final isSelected = selected.contains(device.id);
                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexRadius.sm)),
                          selectedTileColor: dc.primary.withValues(alpha: 0.08),
                          selected: isSelected,
                          onTap: () {
                            setDialogState(() {
                              if (isSelected) {
                                selected.remove(device.id);
                              } else {
                                selected.add(device.id);
                              }
                            });
                          },
                          leading: Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? dc.primary : dc.textTertiary,
                            size: 22,
                          ),
                          title: Text(device.name, style: TextStyle(color: dc.textPrimary, fontSize: 15)),
                          subtitle: Text(
                            device.online ? l10n.onlineStatus : l10n.offlineStatus,
                            style: TextStyle(color: dc.textSecondary, fontSize: 13),
                          ),
                          trailing: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: device.online ? dc.online : dc.error,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.cancel, style: TextStyle(color: dc.textSecondary)),
              ),
              FilledButton(
                onPressed: () => context.pop(selected),
                style: FilledButton.styleFrom(
                  backgroundColor: dc.primary,
                  foregroundColor: dc.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NexRadius.md)),
                ),
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

class _GridPillSelector extends StatelessWidget {
  final int gridSize;
  final ValueChanged<int> onChanged;
  final NexColors colors;
  final AppLocalizations l10n;

  const _GridPillSelector({
    required this.gridSize,
    required this.onChanged,
    required this.colors,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final segments = [
      (2, l10n.grid2x2),
      (3, l10n.grid3x3),
      (4, l10n.grid4x4),
    ];

    return Container(
      padding: EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(NexRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: segments.map((seg) {
          final isSelected = seg.$1 == gridSize;
          return GestureDetector(
            onTap: () => onChanged(seg.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                seg.$2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? colors.onPrimary : colors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WallCell extends StatefulWidget {
  final Device device;

  const _WallCell({required this.device});

  @override
  State<_WallCell> createState() => _WallCellState();
}

class _WallCellState extends State<_WallCell> {
  NexColors _colors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const NexColors.dark() : const NexColors.light();
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors(context);
    final wallProvider = context.watch<ScreenWallProvider>();
    final wallStream = wallProvider.getWallStream(widget.device.id);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NexRadius.md),
        border: Border.all(color: c.border),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NexRadius.md),
        child: Stack(
          children: [
            if (wallStream != null && wallStream.remoteStream != null)
              RTCVideoView(wallStream.renderer)
            else if (wallStream != null && wallStream.failed)
              _buildErrorPlaceholder(c, l10n)
            else
              _buildWaitingPlaceholder(c, l10n),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: NexSpacing.sm, vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0x99000000),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.device.online ? c.online : c.error,
                      ),
                    ),
                    SizedBox(width: NexSpacing.xs + 2),
                    Expanded(
                      child: Text(
                        widget.device.name,
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => context.read<ScreenWallProvider>().removeDevice(widget.device.id),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0x99000000),
                    borderRadius: BorderRadius.circular(NexRadius.sm),
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingPlaceholder(NexColors c, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.desktop_windows_outlined, size: 36, color: Colors.white.withValues(alpha: 0.4)),
          SizedBox(height: NexSpacing.sm),
          Text(
            l10n.waitingForStream,
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(NexColors c, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 36, color: c.error),
          SizedBox(height: NexSpacing.sm),
          Text(
            l10n.connectionFailed,
            style: TextStyle(fontSize: 12, color: c.error),
          ),
        ],
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  final VoidCallback? onTap;

  const _EmptyCell({this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? const NexColors.dark() : const NexColors.light();

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: c.border,
          radius: NexRadius.md,
          dashWidth: 6,
          dashGap: 4,
          strokeWidth: 1.5,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NexRadius.md),
            color: c.surface,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_outlined, size: 28, color: c.primary),
                SizedBox(height: NexSpacing.xs),
                Text(
                  'Add',
                  style: TextStyle(fontSize: 12, color: c.primary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    this.dashWidth = 6,
    this.dashGap = 4,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, end),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap;
  }
}
