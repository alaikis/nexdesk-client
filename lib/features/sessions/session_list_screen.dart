import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../session/session_provider.dart';
import '../../widgets/nex_card.dart';
import '../../widgets/sidebar.dart';

class SessionListScreen extends StatefulWidget {
  const SessionListScreen({super.key});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  int _selectedNav = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SessionProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sessions = context.watch<SessionProvider>().history;
    return Scaffold(
      body: Row(
        children: [
          NexSidebar(
            selectedIndex: _selectedNav,
            onTap: (index) {
              setState(() => _selectedNav = index);
              if (index == 0) context.go('/');
              if (index == 2) context.go('/settings');
            },
            items: const [
              SidebarItem(icon: Icons.computer, label: 'Devices'),
              SidebarItem(icon: Icons.history, label: 'Sessions'),
              SidebarItem(icon: Icons.settings, label: 'Settings'),
            ],
          ),
          Expanded(
            child: Center(
              child: sessions.isEmpty
                  ? Text('No session history yet', style: TextStyle(color: cs.onSurfaceVariant))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final s = sessions[index];
                        return NexCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text('Session ${s.id}'),
                            subtitle: Text('${s.controllerDeviceId} → ${s.controlleeDeviceId}'),
                            trailing: Text(s.status),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
