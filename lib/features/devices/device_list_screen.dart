import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/devices/device_provider.dart';
import '../../features/devices/group_provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/session/session_provider.dart';
import '../../core/error_handler.dart';
import '../../core/api_client.dart';
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
  List<Device> _groupDevices = [];
  bool _groupDevicesLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DeviceProvider>().loadDevices();
      if (mounted) context.read<GroupProvider>().loadGroups();
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

  bool _isSelected(Device device) {
    return _selectedDevice != null && device.id == _selectedDevice!.id;
  }

  Future<void> _selectGroup(String? groupId) async {
    final groupProvider = context.read<GroupProvider>();
    groupProvider.selectGroup(groupId);
    if (groupId == null) {
      setState(() {
        _groupDevices = [];
      });
      return;
    }
    setState(() => _groupDevicesLoading = true);
    try {
      final gid = int.tryParse(groupId) ?? 0;
      final list = await ApiClient().getGroupDevices(gid);
      setState(() {
        _groupDevices = list.map((d) => Device.fromJson(d as Map<String, dynamic>)).toList();
        _groupDevicesLoading = false;
      });
    } on ApiException catch (e) {
      debugPrint('Load group devices failed: $e');
      setState(() => _groupDevicesLoading = false);
    }
  }

  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Group'),
        content: NexInput(controller: nameController, hintText: 'Group name'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              context.pop(nameController.text.trim());
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      try {
        await context.read<GroupProvider>().createGroup(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Group "$result" created')),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create group: $e')),
          );
        }
      }
    }
  }

  Future<void> _showRenameGroupDialog(Group group) async {
    final nameController = TextEditingController(text: group.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Group'),
        content: NexInput(controller: nameController, hintText: 'Group name'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              context.pop(nameController.text.trim());
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      try {
        await context.read<GroupProvider>().renameGroup(group.id, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Group renamed to "$result"')),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to rename group: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDeleteGroupDialog(Group group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete "${group.name}"?'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => context.pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await context.read<GroupProvider>().deleteGroup(group.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Group "${group.name}" deleted')),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete group: $e')),
          );
        }
      }
    }
  }

  Future<void> _showAssignDeviceDialog(Device device) async {
    final groupProvider = context.read<GroupProvider>();
    if (groupProvider.groups.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No groups available. Create one first.')),
        );
      }
      return;
    }
    final selected = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${device.name} to group'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: groupProvider.groups.length,
            itemBuilder: (context, index) {
              final group = groupProvider.groups[index];
              return ListTile(
                title: Text(group.name),
                trailing: Text('${group.deviceCount} devices'),
                onTap: () => context.pop(group.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        ],
      ),
    );
    if (selected != null && mounted) {
      try {
        final deviceId = int.tryParse(device.id);
        if (deviceId == null) return;
        await groupProvider.assignDevice(deviceId, selected);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${device.name} added to group')),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add to group: $e')),
          );
        }
      }
    }
  }

  Future<void> _showUnassignDeviceDialog(Device device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from group'),
        content: Text('Remove ${device.name} from its group?'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        final deviceId = int.tryParse(device.id);
        if (deviceId == null) return;
        await context.read<GroupProvider>().unassignDevice(deviceId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${device.name} removed from group')),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove from group: $e')),
          );
        }
      }
    }
  }

  void _showDeviceContextMenu(Device device) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Add to group'),
              onTap: () {
                context.pop();
                _showAssignDeviceDialog(device);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_remove),
              title: const Text('Remove from group'),
              onTap: () {
                context.pop();
                _showUnassignDeviceDialog(device);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceProvider>();
    final groups = context.watch<GroupProvider>();

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
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.groups, size: 20),
                        tooltip: 'Group management',
                        onSelected: (value) {
                          if (value == 'create') {
                            _showCreateGroupDialog();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'create', child: Text('Create group')),
                          const PopupMenuDivider(),
                          if (groups.groups.isNotEmpty)
                            ...groups.groups.map((g) => PopupMenuItem(
                                  value: 'rename_${g.id}',
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(g.name)),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 16),
                                        onPressed: () {
                                          context.pop();
                                          _showRenameGroupDialog(g);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 16),
                                        onPressed: () {
                                          context.pop();
                                          _showDeleteGroupDialog(g);
                                        },
                                      ),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ],
                  ),
                ),
                if (groups.groups.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: groups.selectedGroupId == null,
                          onSelected: (_) => _selectGroup(null),
                        ),
                        const FilterChip(
                          label: Text('Ungrouped'),
                          selected: false,
                          onSelected: null,
                        ),
                        ...groups.groups.map((g) => FilterChip(
                              label: Text(g.name),
                              selected: groups.selectedGroupId == '${g.id}',
                              onSelected: (_) => _selectGroup('${g.id}'),
                            )),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListenableBuilder(
                    listenable: devices,
                    builder: (context, _) {
                      return ListenableBuilder(
                        listenable: groups,
                        builder: (context, _) {
                          if (groups.selectedGroupId == null && devices.loading && devices.devices.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (groups.selectedGroupId != null && _groupDevicesLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return _buildDeviceList(devices, groups);
                        },
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

  Widget _buildDeviceList(DeviceProvider devices, GroupProvider groups) {
    final currentDeviceId = context.read<AuthProvider>().deviceId;
    final currentDevice = devices.devices.firstWhere(
      (d) => d.id == currentDeviceId,
      orElse: () => Device(id: '', name: '', os: '', online: false, code: ''),
    );

    final displayDevices = groups.selectedGroupId == null
        ? devices.filteredDevices
        : _groupDevices;
    final displayOnline = displayDevices.where((d) => d.online).toList();
    final displayOffline = displayDevices.where((d) => !d.online).toList();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              if (groups.selectedGroupId == null && currentDevice.id.isNotEmpty) ...[
                LocalDeviceCard(device: currentDevice, onCopy: _copyCode),
                const SizedBox(height: 20),
              ],
              if (displayOnline.isNotEmpty) ...[
                SectionHeader(title: 'Online (${displayOnline.length})'),
                const SizedBox(height: 8),
                ...displayOnline.map((d) => DeviceCard(
                      device: d,
                      onConnect: () => _startSession(d.id),
                      onCopy: () => _copyCode(d.code),
                      onWake: d.wolEnabled ? () => _wakeDevice(d.id) : null,
                      wakingDeviceId: _wakingDeviceId,
                      isSelected: _isSelected(d),
                      onTap: () => _selectDevice(d),
                      onLongPress: () => _showDeviceContextMenu(d),
                    )),
                const SizedBox(height: 20),
              ],
              if (displayOffline.isNotEmpty) ...[
                SectionHeader(title: 'Offline (${displayOffline.length})'),
                const SizedBox(height: 8),
                ...displayOffline.map((d) => DeviceCard(
                      device: d,
                      onConnect: () => _startSession(d.id),
                      onCopy: () => _copyCode(d.code),
                      onWake: d.wolEnabled ? () => _wakeDevice(d.id) : null,
                      wakingDeviceId: _wakingDeviceId,
                      isSelected: _isSelected(d),
                      onTap: () => _selectDevice(d),
                      onLongPress: () => _showDeviceContextMenu(d),
                    )),
              ],
              if (displayDevices.isEmpty && !_groupDevicesLoading)
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
