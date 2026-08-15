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
import '../../widgets/local_device_card.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/bottom_nav_bar.dart';

class ControlCenterScreen extends StatefulWidget {
  const ControlCenterScreen({super.key});

  @override
  State<ControlCenterScreen> createState() => _ControlCenterScreenState();
}

class _ControlCenterScreenState extends State<ControlCenterScreen> with ErrorHandler {
  int _selectedNav = 0;
  Timer? _refreshTimer;
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.deviceId != null) {
          context.read<DeviceProvider>().ensureControlPassword(auth.deviceId!);
        }
      }
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

  Future<void> _showConnectDialog() async {
    final codeController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect to Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the device code to connect:'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Device Code',
                hintText: 'e.g. ABC123',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, codeController.text.trim()),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final target = context.read<DeviceProvider>().devices.firstWhere(
        (d) => d.code.toLowerCase() == result.toLowerCase(),
        orElse: () => Device(id: '', name: '', os: '', online: false, code: ''),
      );
      if (target.id.isNotEmpty) {
        await _startSession(target.id);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device not found')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceProvider>();
    final auth = context.watch<AuthProvider>();
    final currentDeviceId = auth.deviceId;
    final currentDevice = devices.devices.firstWhere(
      (d) => d.id == currentDeviceId,
      orElse: () => Device(id: '', name: '', os: '', online: false, code: ''),
    );

    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentDevice.id.isNotEmpty) ...[
            LocalDeviceCard(
              device: currentDevice,
              onCopy: _copyCode,
            ),
            const SizedBox(height: 24),
          ],
          NexCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Actions', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.copy,
                      label: 'Copy Code',
                      onTap: () {
                        if (currentDevice.code.isNotEmpty) {
                          _copyCode(currentDevice.code);
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.connect_without_contact,
                      label: 'Connect',
                      onTap: () => _showConnectDialog(),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.history,
                      label: 'Sessions',
                      onTap: () => context.go('/sessions'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return Scaffold(
            body: Row(
              children: [
                NexSidebar(
                  selectedIndex: _selectedNav,
                  onTap: (index) {
                    setState(() => _selectedNav = index);
                    if (index == 1) context.go('/devices/list');
                    if (index == 2) context.go('/sessions');
                    if (index == 3) context.go('/shares');
                    if (index == 4) context.go('/settings');
                  },
                  onLogout: _logout,
                  items: const [
                    SidebarItem(icon: Icons.computer, label: 'Devices'),
                    SidebarItem(icon: Icons.list, label: 'All Devices'),
                    SidebarItem(icon: Icons.history, label: 'Sessions'),
                    SidebarItem(icon: Icons.folder_shared, label: 'Shares'),
                    SidebarItem(icon: Icons.settings, label: 'Settings'),
                  ],
                ),
                Expanded(child: content),
              ],
            ),
          );
        } else {
          return Scaffold(
            body: content,
            bottomNavigationBar: BottomNavBar(
              selectedIndex: _selectedNav,
              onTap: (index) {
                setState(() => _selectedNav = index);
                if (index == 1) context.go('/devices/list');
                if (index == 2) context.go('/sessions');
                if (index == 3) context.go('/shares');
                if (index == 4) context.go('/settings');
              },
              items: const [
                BottomNavItem(icon: Icons.computer, label: 'Devices'),
                BottomNavItem(icon: Icons.list, label: 'All Devices'),
                BottomNavItem(icon: Icons.history, label: 'Sessions'),
                BottomNavItem(icon: Icons.folder_shared, label: 'Shares'),
                BottomNavItem(icon: Icons.settings, label: 'Settings'),
              ],
            ),
          );
        }
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
