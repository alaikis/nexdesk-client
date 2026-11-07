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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessions = context.watch<SessionProvider>().history;
    final l10n = AppLocalizations.of(context)!;
    
    final backgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardBackground = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1D1D1F);
    final textSecondary = isDark ? const Color(0xFF98989D) : const Color(0xFF6E6E73);
    final primaryColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);

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
                                '${s.controllerDeviceId} → ${s.controlleeDeviceId}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(NexRadius.full),
                                ),
                                child: Text(
                                  s.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
