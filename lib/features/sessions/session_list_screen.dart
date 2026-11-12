import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../session/session_provider.dart';
import '../../widgets/nex_card.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/empty_state.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

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
    final sessions = context.watch<SessionProvider>().history;
    final l10n = AppLocalizations.of(context)!;
    final wise = WiseTheme.of(context);

    final backgroundColor = wise.background;
    final cardBackground = wise.card;
    final textPrimary = wise.textPrimary;
    final textSecondary = wise.textSecondary;
    final primaryColor = wise.primary;

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
            items: [
              SidebarItem(icon: Icons.computer, label: l10n.devices),
              SidebarItem(icon: Icons.history, label: l10n.sessions),
              SidebarItem(icon: Icons.settings, label: l10n.settings),
            ],
          ),
          Expanded(
            child: Container(
              color: backgroundColor,
              child: sessions.isEmpty
                  ? EmptyState(
                      icon: Icons.history,
                      title: l10n.noSessionHistory,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final s = sessions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: NexCard(
                            color: cardBackground,
                            enableShadow: true,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                l10n.sessionLabel(s.id),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${s.controllerDeviceId} 鈫?${s.controlleeDeviceId}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: wise.primaryTint,
                                  borderRadius: BorderRadius.circular(wise.radius.full),
                                ),
                                child: Text(
                                  s.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
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
