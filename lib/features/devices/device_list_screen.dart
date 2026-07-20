import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/devices/device_provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/session/session_provider.dart';
import '../../core/error_handler.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> with ErrorHandler {
  final DeviceProvider _deviceProvider = DeviceProvider();
  bool _waking = false;

  @override
  void initState() {
    super.initState();
    _deviceProvider.loadDevices();
  }

  Future<void> _wakeDevice(String deviceId) async {
    setState(() => _waking = true);
    final ok = await _deviceProvider.wakeDevice(deviceId);
    if (mounted) {
      setState(() => _waking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Magic packet sent' : 'Failed to wake device')),
      );
    }
  }

  Future<void> _startSession(String deviceId) async {
    final sessionProvider = context.read<SessionProvider>();
    final res = await sessionProvider.startSession(deviceId);
    if (!mounted) return;
    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start session')),
      );
      return;
    }
    context.go('/session/${res.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          IconButton(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              await auth.logout();
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _deviceProvider,
        builder: (context, _) {
          final devices = _deviceProvider.devices;
          if (_deviceProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (devices.isEmpty) {
            return const Center(child: Text('No devices yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: _DeviceIcon(index: index),
                  title: Text(
                    device.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  subtitle: Text(
                    device.os,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusBadge(isOnline: device.online),
                      if (device.wolEnabled) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _waking ? null : () => _wakeDevice(device.id),
                          tooltip: 'Wake',
                          icon: const Icon(Icons.power_settings_new, color: Color(0xFF007AFF)),
                        ),
                      ],
                    ],
                  ),
                  onTap: () => _startSession(device.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        tooltip: 'Register new device (coming soon)',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _DeviceIcon extends StatelessWidget {
  final int index;
  const _DeviceIcon({required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF007AFF),
      const Color(0xFFAF52DE),
      const Color(0xFF34C759),
    ];
    final icons = [
      Icons.computer,
      Icons.laptop_mac,
      Icons.smartphone,
    ];
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors[index % colors.length].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icons[index % icons.length], color: colors[index % colors.length], size: 20),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOnline;
  const _StatusBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF34C759).withValues(alpha: 0.12) : const Color(0xFF8E8E93).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: isOnline ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
