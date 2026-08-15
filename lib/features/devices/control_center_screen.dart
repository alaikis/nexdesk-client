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
import '../../l10n/app_localizations.dart';

enum ConnectMode { control, file, view, collab }

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
  final TextEditingController _connectController = TextEditingController();
  ConnectMode _connectMode = ConnectMode.control;

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
          context.read<DeviceProvider>().ensureControlPassword(auth.deviceId!).then((_) {
            if (mounted) context.read<DeviceProvider>().loadDevices();
          });
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
    final l10n = AppLocalizations.of(context)!;
    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToStartSession)),
      );
      return;
    }
    context.go('/session/${res.id}');
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.copied), duration: const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _showConnectDialog() async {
    _connectController.clear();
    final devices = context.read<DeviceProvider>().devices;
    final recent = devices.take(5).toList();
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.connect),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _connectController,
                decoration: InputDecoration(
                  labelText: l10n.deviceCodeLabel,
                  hintText: l10n.enterCode,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              SegmentedButton<ConnectMode>(
                segments: [
                  ButtonSegment(value: ConnectMode.control, label: Text(l10n.connectModeControl), icon: Icon(Icons.computer, size: 16)),
                  ButtonSegment(value: ConnectMode.file, label: Text(l10n.connectModeFile), icon: Icon(Icons.folder_open, size: 16)),
                  ButtonSegment(value: ConnectMode.view, label: Text(l10n.connectModeView), icon: Icon(Icons.visibility, size: 16)),
                  ButtonSegment(value: ConnectMode.collab, label: Text(l10n.connectModeCollab), icon: Icon(Icons.people, size: 16)),
                ],
                selected: {_connectMode},
                onSelectionChanged: (Set<ConnectMode> selection) {
                  setDialogState(() => _connectMode = selection.first);
                },
              ),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(l10n.recent, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recent.map((d) => ActionChip(
                    label: Text(d.code, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      Navigator.pop(context, d.code);
                    },
                  )).toList(),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(context, _connectController.text.trim()),
              child: Text(l10n.connect),
            ),
          ],
        ),
      ),
    );
    if (result != null && result.isNotEmpty) {
      final target = context.read<DeviceProvider>().devices.firstWhere(
        (d) => d.code.toLowerCase() == result.toLowerCase(),
        orElse: () => Device(id: '', name: '', os: '', online: false, code: '', favorite: false, tags: const []),
      );
      if (target.id.isNotEmpty) {
        await _startSession(target.id);
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deviceNotFound)),
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
      orElse: () => Device(id: '', name: '', os: '', online: false, code: '', favorite: false, tags: const []),
    );
    final l10n = AppLocalizations.of(context)!;

    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentDevice.id.isNotEmpty) ...[
            LocalDeviceCard(
              device: currentDevice,
              onCopy: _copyCode,
            ),
            const SizedBox(height: 16),
          ],
          NexCard(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.connect_without_contact, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(l10n.quickConnect, style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showConnectDialog(),
                        icon: const Icon(Icons.computer, size: 18),
                        label: Text(l10n.control),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showConnectDialog(),
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: Text(l10n.files),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showConnectDialog(),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: Text(l10n.view),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NexCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.thisDevice, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                _InfoRow(label: l10n.clientIdLabel, value: auth.deviceId ?? l10n.notSet),
                const SizedBox(height: 8),
                _InfoRow(label: l10n.controlPasswordLabel, value: currentDevice.hasControlPassword ? l10n.set : l10n.notSet),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                    if (index == 1) context.go('/screen-wall');
                    if (index == 2) context.go('/devices/list');
                    if (index == 3) context.go('/sessions');
                    if (index == 4) context.go('/shares');
                    if (index == 5) context.go('/settings');
                  },
                  onLogout: _logout,
                  items: [
                    SidebarItem(icon: Icons.computer, label: l10n.devices),
                    SidebarItem(icon: Icons.grid_view, label: l10n.screenWall),
                    SidebarItem(icon: Icons.list, label: l10n.allDevices),
                    SidebarItem(icon: Icons.history, label: l10n.sessions),
                    SidebarItem(icon: Icons.folder_shared, label: l10n.shares),
                    SidebarItem(icon: Icons.settings, label: l10n.settings),
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
                if (index == 1) context.go('/screen-wall');
                if (index == 2) context.go('/devices/list');
                if (index == 3) context.go('/sessions');
                if (index == 4) context.go('/shares');
                if (index == 5) context.go('/settings');
              },
              items: [
                BottomNavItem(icon: Icons.computer, label: l10n.devices),
                BottomNavItem(icon: Icons.grid_view, label: l10n.screenWall),
                BottomNavItem(icon: Icons.list, label: l10n.allDevices),
                BottomNavItem(icon: Icons.history, label: l10n.sessions),
                BottomNavItem(icon: Icons.folder_shared, label: l10n.shares),
                BottomNavItem(icon: Icons.settings, label: l10n.settings),
              ],
            ),
          );
        }
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
