import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/devices/device_provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/session/session_provider.dart';
import '../../core/error_handler.dart';
import '../../widgets/nex_card.dart';
import '../../widgets/nex_button.dart';
import '../../widgets/nex_input.dart';
import '../../widgets/online_dot.dart';
import '../../widgets/sidebar.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> with ErrorHandler {
  int _selectedNav = 0;
  Timer? _refreshTimer;
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();
  String? _wakingDeviceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DeviceProvider>().loadDevices();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) context.read<DeviceProvider>().refresh();
    });
    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) context.read<DeviceProvider>().setFilter(_searchController.text);
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  Future<void> _wakeDevice(String deviceId) async {
    setState(() => _wakingDeviceId = deviceId);
    try {
      final ok = await context.read<DeviceProvider>().wakeDevice(deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Magic packet sent' : 'Failed to wake device')),
        );
      }
    } finally {
      if (mounted) setState(() => _wakingDeviceId = null);
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

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final devices = context.watch<DeviceProvider>();
    final currentDeviceId = context.watch<AuthProvider>().deviceId;
    final currentDevice = devices.devices.firstWhere(
      (d) => d.id == currentDeviceId,
      orElse: () => Device(id: '', name: '', os: '', online: false, code: ''),
    );

    return Scaffold(
      body: Row(
        children: [
          NexSidebar(
            selectedIndex: _selectedNav,
            onTap: (index) {
              setState(() => _selectedNav = index);
              if (index == 1) context.go('/sessions');
              if (index == 2) context.go('/settings');
            },
            onLogout: _logout,
            items: const [
              SidebarItem(icon: Icons.computer, label: 'Devices'),
              SidebarItem(icon: Icons.history, label: 'Sessions'),
              SidebarItem(icon: Icons.settings, label: 'Settings'),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: NexInput(
                          controller: _searchController,
                          hintText: 'Search devices...',
                          prefixIcon: Icons.search,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListenableBuilder(
                    listenable: devices,
                    builder: (context, _) {
                      if (devices.loading && devices.devices.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          if (currentDevice.id.isNotEmpty) ...[
                            _LocalDeviceCard(device: currentDevice, onCopy: _copyCode),
                            const SizedBox(height: 20),
                          ],
                          if (devices.onlineDevices.isNotEmpty) ...[
                            _SectionHeader(title: 'Online (${devices.onlineDevices.length})'),
                            const SizedBox(height: 8),
                            ...devices.onlineDevices.map((d) => _DeviceCard(
                                  device: d,
                                  onConnect: () => _startSession(d.id),
                                  onCopy: () => _copyCode(d.code),
                                  onWake: d.wolEnabled ? () => _wakeDevice(d.id) : null,
                                  wakingDeviceId: _wakingDeviceId,
                                )),
                            const SizedBox(height: 20),
                          ],
                          if (devices.offlineDevices.isNotEmpty) ...[
                            _SectionHeader(title: 'Offline (${devices.offlineDevices.length})'),
                            const SizedBox(height: 8),
                            ...devices.offlineDevices.map((d) => _DeviceCard(
                                  device: d,
                                  onConnect: () => _startSession(d.id),
                                  onCopy: () => _copyCode(d.code),
                                  onWake: d.wolEnabled ? () => _wakeDevice(d.id) : null,
                                  wakingDeviceId: _wakingDeviceId,
                                )),
                          ],
                          if (devices.devices.isEmpty)
                            _EmptyState(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant, letterSpacing: 0.5),
    );
  }
}

class _LocalDeviceCard extends StatelessWidget {
  final Device device;
  final ValueChanged<String> onCopy;
  const _LocalDeviceCard({required this.device, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return NexCard(
      color: cs.primaryContainer.withValues(alpha: 0.15),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.computer, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text('This Device', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Device Code', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: device.code.isEmpty ? null : () => onCopy(device.code),
                      child: Row(
                        children: [
                          Text(
                            device.code.isEmpty ? 'Not set' : device.code,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: cs.primary),
                          ),
                          if (device.code.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.copy, size: 14, color: cs.onSurfaceVariant),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Control Password', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(
                      device.hasControlPassword ? '••••••••' : 'Not set',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OnlineDot(isOnline: device.online),
              const SizedBox(width: 8),
              Text(device.name, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onConnect;
  final VoidCallback onCopy;
  final VoidCallback? onWake;
  final String? wakingDeviceId;

  const _DeviceCard({required this.device, required this.onConnect, required this.onCopy, this.onWake, this.wakingDeviceId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return NexCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
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
                Text(device.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(device.os, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (device.code.isNotEmpty) ...[
            GestureDetector(
              onTap: onCopy,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  device.code,
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ],
          OnlineDot(isOnline: device.online),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: onConnect,
            child: const Text('Connect'),
          ),
          if (onWake != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: wakingDeviceId == device.id ? null : onWake,
              tooltip: 'Wake',
                  icon: wakingDeviceId == device.id
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.power_settings_new, size: 18, color: cs.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onAdd;
  const _EmptyState({this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.devices_other, size: 48, color: cs.outline),
            const SizedBox(height: 16),
            Text('No devices yet', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
            const SizedBox(height: 16),
            NexButton(text: 'Add Device', fullWidth: false, onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}
