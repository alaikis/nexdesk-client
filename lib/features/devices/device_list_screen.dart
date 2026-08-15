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
import '../../l10n/app_localizations.dart';

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
  bool _showFavoritesOnly = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedDeviceIds = {};

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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? l10n.magicPacketSent : l10n.failedToWakeDevice)),
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

  Future<void> _toggleFavorite(String deviceId) async {
    try {
      await context.read<DeviceProvider>().toggleFavorite(deviceId);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final provider = context.read<DeviceProvider>();
        final device = provider.devices.firstWhere((d) => d.id == deviceId, orElse: () => Device(id: '', name: '', os: '', online: false, favorite: false));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(device.favorite ? l10n.addedToFavorites : l10n.removedFromFavorites)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUpdateFavorite(e.toString()))),
        );
      }
    }
  }

  void _toggleSelection(String deviceId) {
    setState(() {
      if (_selectedDeviceIds.contains(deviceId)) {
        _selectedDeviceIds.remove(deviceId);
      } else {
        _selectedDeviceIds.add(deviceId);
      }
    });
  }

  void _enterSelectionMode(String deviceId) {
    setState(() {
      _isSelectionMode = true;
      _selectedDeviceIds.clear();
      _selectedDeviceIds.add(deviceId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedDeviceIds.clear();
    });
  }

  Future<void> _batchFavorite() async {
    final provider = context.read<DeviceProvider>();
    for (final id in _selectedDeviceIds) {
      await provider.toggleFavorite(id);
    }
    _exitSelectionMode();
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.favorite)),
      );
    }
  }

  Future<void> _batchUnfavorite() async {
    final provider = context.read<DeviceProvider>();
    for (final id in _selectedDeviceIds) {
      final device = provider.devices.firstWhere((d) => d.id == id, orElse: () => Device(id: '', name: '', os: '', online: false, favorite: false, tags: const []));
      if (device.favorite) {
        await provider.toggleFavorite(id);
      }
    }
    _exitSelectionMode();
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.unfavorite)),
      );
    }
  }

  Future<void> _renameDevice(String deviceId, String name) async {
    try {
      await context.read<DeviceProvider>().renameDevice(deviceId, name);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.renamedTo(name))),
        );
      }
      if (_selectedDevice?.id == deviceId) {
        setState(() => _selectedDevice = context.read<DeviceProvider>().devices.firstWhere((d) => d.id == deviceId));
      }
    } on ApiException catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToRename(e.toString()))),
        );
      }
    }
  }

  Future<void> _showEditTagsDialog(Device device) async {
    final tags = List<String>.from(device.tags);
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editTags),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              children: tags.map((tag) => Chip(
                label: Text(tag),
                onDeleted: () {
                  tags.remove(tag);
                  (context as Element).markNeedsBuild();
                },
              )).toList(),
            ),
            const SizedBox(height: 12),
            NexInput(
              controller: controller,
              hintText: l10n.addTag,
              onChanged: (value) {
                if (value.endsWith(',')) {
                  final newTag = value.replaceAll(',', '').trim();
                  if (newTag.isNotEmpty && !tags.contains(newTag)) {
                    tags.add(newTag);
                    controller.clear();
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              context.pop(tags);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      try {
        await context.read<DeviceProvider>().updateDeviceTags(device.id, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.tagsUpdatedFor(device.name))),
          );
        }
        if (_selectedDevice?.id == device.id) {
          setState(() => _selectedDevice = context.read<DeviceProvider>().devices.firstWhere((d) => d.id == device.id));
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToUpdateTags(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createGroup),
        content: NexInput(controller: nameController, hintText: l10n.groupName),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              context.pop(nameController.text.trim());
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      try {
        await context.read<GroupProvider>().createGroup(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.groupCreated(result))),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToCreateGroup(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _showRenameGroupDialog(Group group) async {
    final nameController = TextEditingController(text: group.name);
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameGroup),
        content: NexInput(controller: nameController, hintText: l10n.groupName),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              context.pop(nameController.text.trim());
            },
            child: Text(l10n.renameCtx),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      try {
        await context.read<GroupProvider>().renameGroup(group.id, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.groupRenamed(result))),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToRenameGroup(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _showDeleteGroupDialog(Group group) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteGroup),
        content: Text(l10n.deleteGroupConfirm(group.name)),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => context.pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await context.read<GroupProvider>().deleteGroup(group.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.groupDeleted(group.name))),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToDeleteGroup(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _showAssignDeviceDialog(Device device) async {
    final groupProvider = context.read<GroupProvider>();
    final l10n = AppLocalizations.of(context)!;
    if (groupProvider.groups.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noGroupsAvailable)),
        );
      }
      return;
    }
    final selected = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addToGroup(device.name)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: groupProvider.groups.length,
            itemBuilder: (context, index) {
              final group = groupProvider.groups[index];
              return ListTile(
                title: Text(group.name),
                trailing: Text('${group.deviceCount} ${l10n.devices}'),
                onTap: () => context.pop(group.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text(l10n.cancel)),
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
            SnackBar(content: Text(l10n.addedToGroup(device.name))),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToAddToGroup(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _showUnassignDeviceDialog(Device device) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeFromGroup),
        content: Text(l10n.removeFromGroupConfirm(device.name)),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => context.pop(true),
            child: Text(l10n.remove),
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
            SnackBar(content: Text(l10n.removedFromGroup(device.name))),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToRemoveFromGroup(e.toString()))),
          );
        }
      }
    }
  }

  void _showDeviceContextMenu(Device device) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add),
              title: Text(l10n.addToGroupCtx),
              onTap: () {
                context.pop();
                _showAssignDeviceDialog(device);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_remove),
              title: Text(l10n.removeFromGroupCtx),
              onTap: () {
                context.pop();
                _showUnassignDeviceDialog(device);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.renameCtx),
              onTap: () {
                context.pop();
                _showRenameDeviceDialog(device);
              },
            ),
            ListTile(
              leading: const Icon(Icons.label),
              title: Text(l10n.editTagsCtx),
              onTap: () {
                context.pop();
                _showEditTagsDialog(device);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDeviceDialog(Device device) async {
    final nameController = TextEditingController(text: device.name);
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameDevice),
        content: NexInput(controller: nameController, hintText: l10n.deviceName),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              context.pop(nameController.text.trim());
            },
            child: Text(l10n.renameCtx),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      await _renameDevice(device.id, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceProvider>();
    final groups = context.watch<GroupProvider>();
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
            items: [
              SidebarItem(icon: Icons.computer, label: l10n.devices),
              SidebarItem(icon: Icons.history, label: l10n.sessions),
              SidebarItem(icon: Icons.folder_shared, label: l10n.shares),
              SidebarItem(icon: Icons.settings, label: l10n.settings),
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
                          hintText: l10n.searchDevices,
                          prefixIcon: Icons.search,
                        ),
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.groups, size: 20),
                        tooltip: l10n.groupManagement,
                        onSelected: (value) {
                          if (value == 'create') {
                            _showCreateGroupDialog();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'create', child: Text(l10n.createGroupMenu)),
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
                            label: Text(l10n.filterAll),
                            selected: groups.selectedGroupId == null,
                            onSelected: (_) => _selectGroup(null),
                          ),
                          FilterChip(
                            label: Text(l10n.filterUngrouped),
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
                  if (_showFavoritesOnly || _isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: Text(l10n.favorites),
                            selected: _showFavoritesOnly,
                            onSelected: (_) => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (_isSelectionMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: cs.surfaceContainerHighest,
                      child: Row(
                        children: [
                          Text(l10n.selectedCount(_selectedDeviceIds.length), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _selectedDeviceIds.isEmpty ? null : _batchFavorite,
                            icon: Icon(Icons.star, size: 18, color: cs.primary),
                            label: Text(l10n.favorite),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _selectedDeviceIds.isEmpty ? null : _batchUnfavorite,
                            icon: Icon(Icons.star_border, size: 18, color: cs.onSurfaceVariant),
                            label: Text(l10n.unfavorite),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _exitSelectionMode,
                            icon: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
                            label: Text(l10n.cancel),
                          ),
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
      orElse: () => Device(id: '', name: '', os: '', online: false, code: '', favorite: false, tags: const []),
    );
    final l10n = AppLocalizations.of(context)!;

    final displayDevices = groups.selectedGroupId == null
        ? (_showFavoritesOnly ? devices.favoriteDevices : devices.filteredDevices)
        : _groupDevices.where((d) => !_showFavoritesOnly || d.favorite).toList();
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
                SectionHeader(title: l10n.online(displayOnline.length)),
                const SizedBox(height: 8),
                ...displayOnline.map((d) => DeviceCard(
                      device: d,
                      onConnect: () => _startSession(d.id),
                      onCopy: () => _copyCode(d.code),
                      onWake: d.wolEnabled ? () => _wakeDevice(d.id) : null,
                      wakingDeviceId: _wakingDeviceId,
                      isSelected: _isSelectionMode ? _selectedDeviceIds.contains(d.id) : _isSelected(d),
                      onTap: _isSelectionMode ? () => _toggleSelection(d.id) : () => _selectDevice(d),
                      onLongPress: _isSelectionMode ? () => _showDeviceContextMenu(d) : () {
                        _enterSelectionMode(d.id);
                      },
                      onToggleFavorite: () => _toggleFavorite(d.id),
                      onRename: (name) => _renameDevice(d.id, name),
                      inSelectionMode: _isSelectionMode,
                    )),
                const SizedBox(height: 20),
              ],
              if (displayOffline.isNotEmpty) ...[
                SectionHeader(title: l10n.offline(displayOffline.length)),
                const SizedBox(height: 8),
                ...displayOffline.map((d) => DeviceCard(
                      device: d,
                      onConnect: () => _startSession(d.id),
                      onCopy: () => _copyCode(d.code),
                      onWake: d.wolEnabled ? () => _wakeDevice(d.id) : null,
                      wakingDeviceId: _wakingDeviceId,
                      isSelected: _isSelectionMode ? _selectedDeviceIds.contains(d.id) : _isSelected(d),
                      onTap: _isSelectionMode ? () => _toggleSelection(d.id) : () => _selectDevice(d),
                      onLongPress: _isSelectionMode ? () => _showDeviceContextMenu(d) : () {
                        _enterSelectionMode(d.id);
                      },
                      onToggleFavorite: () => _toggleFavorite(d.id),
                      onRename: (name) => _renameDevice(d.id, name),
                      inSelectionMode: _isSelectionMode,
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
              onClose: () {
                setState(() => _selectedDevice = null);
                _exitSelectionMode();
              },
              onToggleFavorite: () => _toggleFavorite(_selectedDevice!.id),
              onEditTags: () => _showEditTagsDialog(_selectedDevice!),
              onRename: (name) => _renameDevice(_selectedDevice!.id, name),
            ),
          ),
      ],
    );
  }
}

class _DeviceDetailPanel extends StatefulWidget {
  final Device device;
  final VoidCallback onConnect;
  final VoidCallback onCopy;
  final VoidCallback? onWake;
  final VoidCallback onClose;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onEditTags;
  final ValueChanged<String>? onRename;

  const _DeviceDetailPanel({
    required this.device,
    required this.onConnect,
    required this.onCopy,
    this.onWake,
    required this.onClose,
    this.onToggleFavorite,
    this.onEditTags,
    this.onRename,
  });

  @override
  State<_DeviceDetailPanel> createState() => _DeviceDetailPanelState();
}

class _DeviceDetailPanelState extends State<_DeviceDetailPanel> {
  bool _isEditingName = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final device = widget.device;
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
                if (_isEditingName) ...[
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        border: OutlineInputBorder(borderSide: BorderSide(color: cs.outline)),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          widget.onRename?.call(value.trim());
                        }
                        setState(() => _isEditingName = false);
                      },
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _nameController.text = device.name;
                        setState(() => _isEditingName = true);
                      },
                      child: Text(device.name, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ],
                if (widget.onToggleFavorite != null)
                  IconButton(
                    onPressed: widget.onToggleFavorite,
                    icon: Icon(
                      device.favorite ? Icons.star : Icons.star_border,
                      size: 18,
                      color: device.favorite ? Colors.amber : cs.onSurfaceVariant,
                    ),
                    tooltip: device.favorite ? l10n.removeFromFavoritesTooltip : l10n.addToFavoritesTooltip,
                  ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
                  tooltip: l10n.close,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DetailRow(label: l10n.osLabel, value: device.os),
                const SizedBox(height: 12),
                _DetailRow(label: l10n.statusLabel, value: device.online ? l10n.onlineStatus : l10n.offlineStatus),
                const SizedBox(height: 12),
                _DetailRow(label: l10n.deviceCodeLabel, value: device.code.isEmpty ? l10n.notSet : device.code),
                if (device.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(label: l10n.tagsLabel, value: device.tags.join(', ')),
                ],
                const SizedBox(height: 24),
                Text(l10n.actions, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.connect_without_contact,
                  label: l10n.connect,
                  onTap: widget.onConnect,
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  icon: Icons.copy,
                  label: l10n.copyCode,
                  onTap: widget.onCopy,
                ),
                if (widget.onWake != null) ...[
                  const SizedBox(height: 8),
                  _ActionButton(
                    icon: Icons.power_settings_new,
                    label: l10n.wakeDevice,
                    onTap: widget.onWake,
                  ),
                ],
                const SizedBox(height: 8),
                _ActionButton(
                  icon: Icons.restart_alt,
                  label: l10n.restart,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.restartCommandSent)),
                      );
                    },
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  icon: Icons.share,
                  label: l10n.shareFiles,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.fileSharingComingSoon)),
                      );
                    },
                ),
                if (widget.onEditTags != null) ...[
                  const SizedBox(height: 8),
                  _ActionButton(
                    icon: Icons.label,
                    label: l10n.editTagsAction,
                    onTap: widget.onEditTags,
                  ),
                ],
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
