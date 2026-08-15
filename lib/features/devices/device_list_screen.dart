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
  Device? _selectedDevice;

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

  void _selectDevice(Device device) {
    setState(() => _selectedDevice = device);
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
              if (index == 2) context.go('/shares');
              if (index == 3) context.go('/settings');
            },
            onLogout: _logout,
            items: const [
              SidebarItem(icon: Icons.computer, label: 'Devices'),
              SidebarItem(icon: Icons.history, label: 'Sessions'),
              SidebarItem(icon: Icons.folder_shared, label: 'Shares'),
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
                      final isSelected = (Device d) => _selectedDevice != null && d.id == _selectedDevice!.id;
                      return Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ListView(
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
                                        isSelected: isSelected(d),
                                        onTap: () => _selectDevice(d),
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
                                        isSelected: isSelected(d),
                                        onTap: () => _selectDevice(d),
                                      )),
                                ],
                                if (devices.devices.isEmpty)
                                  EmptyState(),
                              ],
                            ),
                          ),
                          if (_selectedDevice != null)
                            Expanded(
                              flex: 2,
                              child: _DeviceDetailPanel(
                                device: _selectedDevice!,
                                onConnect: () => _startSession(_selectedDevice!.id),
                                onCopy: () => _copyCode(_selectedDevice!.code),
                                onWake: _selectedDevice!.wolEnabled ? () => _wakeDevice(_selectedDevice!.id) : null,
                                onClose: () => setState(() => _selectedDevice = null),
                              ),
                            ),
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

class _DeviceDetailPanel extends StatelessWidget {
  final Device device;
  final VoidCallback onConnect;
  final VoidCallback onCopy;
  final VoidCallback? onWake;
  final VoidCallback onClose;

  const _DeviceDetailPanel({
    required this.device,
    required this.onConnect,
    required this.onCopy,
    this.onWake,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.computer, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(device.name, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 15)),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DetailRow(label: 'OS', value: device.os),
                const SizedBox(height: 12),
                _DetailRow(label: 'Status', value: device.online ? 'Online' : 'Offline'),
                const SizedBox(height: 12),
                _DetailRow(label: 'Device Code', value: device.code.isEmpty ? 'Not set' : device.code),
                const SizedBox(height: 24),
                Text('Actions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.connect_without_contact,
                  label: 'Connect',
                  onTap: onConnect,
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  icon: Icons.copy,
                  label: 'Copy Code',
                  onTap: onCopy,
                ),
                if (onWake != null) ...[
                  const SizedBox(height: 8),
                  _ActionButton(
                    icon: Icons.power_settings_new,
                    label: 'Wake Device',
                    onTap: onWake,
                  ),
                ],
                const SizedBox(height: 8),
                _ActionButton(
                  icon: Icons.restart_alt,
                  label: 'Restart',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Restart command sent')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  icon: Icons.share,
                  label: 'Share Files',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File sharing coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}
