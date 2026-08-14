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
import '../../widgets/local_device_card.dart';
import '../../widgets/device_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/empty_state.dart';
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
    final auth = context.watch<AuthProvider>();
    final sessions = context.watch<SessionProvider>();
    final currentDeviceId = auth.deviceId;
    final currentDevice = devices.devices.firstWhere(
      (d) => d.id == currentDeviceId,
      orElse: () => Device(id: '', name: '', os: '', online: false, code: ''),
    );
    final onlineDevices = devices.onlineDevices;
    final recentSessions = sessions.history.take(3).toList();

    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: 24),
          if (currentDevice.id.isNotEmpty) ...[
            LocalDeviceCard(
              device: currentDevice,
              onCopy: _copyCode,
            ),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              Expanded(
                child: NexCard(
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
                            onTap: () {
                              if (onlineDevices.isNotEmpty) {
                                _startSession(onlineDevices.first.id);
                              }
                            },
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
              ),
              const SizedBox(width: 20),
              Expanded(
                child: NexCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Sessions', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 12),
                      if (recentSessions.isEmpty)
                        Text('No recent sessions', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
                      else
                        ...recentSessions.map((session) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Expanded(child: Text('${session.controllerDeviceId} → ${session.controlleeDeviceId}')),
                              Text(session.startedAt, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Online Devices', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/devices/list'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (onlineDevices.isEmpty)
            EmptyState(
              message: 'No online devices',
              buttonText: 'Refresh',
              onButtonPressed: () => devices.refresh(),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: onlineDevices.take(3).map((d) => SizedBox(
                width: 280,
                child: DeviceCard(
                  device: d,
                  onConnect: () => _startSession(d.id),
                  onCopy: () => _copyCode(d.code),
                  onWake: d.wolEnabled ? () => _wakeDevice(d.id) : null,
                  wakingDeviceId: _wakingDeviceId,
                ),
              )).toList(),
            ),
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
                    if (index == 3) context.go('/settings');
                  },
                  onLogout: _logout,
                  items: const [
                    SidebarItem(icon: Icons.computer, label: 'Devices'),
                    SidebarItem(icon: Icons.list, label: 'All Devices'),
                    SidebarItem(icon: Icons.history, label: 'Sessions'),
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
                if (index == 3) context.go('/settings');
              },
              items: const [
                BottomNavItem(icon: Icons.computer, label: 'Devices'),
                BottomNavItem(icon: Icons.list, label: 'All Devices'),
                BottomNavItem(icon: Icons.history, label: 'Sessions'),
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
