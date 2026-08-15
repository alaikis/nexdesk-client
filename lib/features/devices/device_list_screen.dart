import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/devices/device_provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/session/session_provider.dart';
import '../../core/error_handler.dart';
import '../../widgets/nex_input.dart';
import '../../widgets/local_device_card.dart';
import '../../widgets/device_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/empty_state.dart';
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
                            LocalDeviceCard(device: currentDevice, onCopy: _copyCode),
                            const SizedBox(height: 20),
                          ],
                          if (devices.onlineDevices.isNotEmpty) ...[
                            SectionHeader(title: 'Online (${devices.onlineDevices.length})'),
                            const SizedBox(height: 8),
                            ...devices.onlineDevices.map((d) => DeviceCard(
                                  device: d,
                                  onConnect: () => _startSession(d.id),
                                  onCopy: () => _copyCode(d.code),
                                  onWake: d.wolEnabled ? () => _wakeDevice(d.id) : null,
                                  wakingDeviceId: _wakingDeviceId,
                                )),
                            const SizedBox(height: 20),
                          ],
                          if (devices.offlineDevices.isNotEmpty) ...[
                            SectionHeader(title: 'Offline (${devices.offlineDevices.length})'),
                            const SizedBox(height: 8),
                            ...devices.offlineDevices.map((d) => DeviceCard(
                                  device: d,
                                  onConnect: () => _startSession(d.id),
                                  onCopy: () => _copyCode(d.code),
                                  onWake: d.wolEnabled ? () => _wakeDevice(d.id) : null,
                                  wakingDeviceId: _wakingDeviceId,
                                )),
                          ],
                          if (devices.devices.isEmpty)
                            EmptyState(),
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

