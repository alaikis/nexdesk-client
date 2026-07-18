import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/signaling_service.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  @override
  Widget build(BuildContext context) {
    final signaling = SignalingService(
      serverUrl: 'ws://localhost:3000',
      token: 'demo-token',
      deviceId: 'device-1',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          IconButton(
            onPressed: signaling.connect,
            icon: const Icon(Icons.wifi),
          ),
          IconButton(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (context, index) {
          final isOnline = index == 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: _DeviceIcon(index: index),
              title: Text(
                index == 0 ? 'Workstation' : index == 1 ? 'MacBook Pro' : 'iPhone 15',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: Text(
                index == 0 ? 'Windows 11 · x86_64' : index == 1 ? 'macOS 15 · arm64' : 'iOS 18 · arm64',
                style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
              ),
              trailing: _StatusBadge(isOnline: isOnline),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: register new device
        },
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
        color: colors[index].withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icons[index], color: colors[index], size: 20),
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
        color: isOnline ? const Color(0xFF34C759).withOpacity(0.12) : const Color(0xFF8E8E93).withOpacity(0.12),
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
