import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/two_factor_screen.dart';
import 'features/devices/control_center_screen.dart';
import 'features/devices/device_list_screen.dart';
import 'features/session/session_screen.dart';
import 'features/sessions/session_list_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shares/share_list_screen.dart';
import 'features/shares/share_browser_screen.dart';
import 'features/screen_wall/screen_wall_screen.dart';
import 'features/meetings/meeting_list_screen.dart';
import 'features/meetings/meeting_create_screen.dart';
import 'features/meetings/meeting_room_screen.dart';
import 'l10n/app_localizations.dart';

class NexApp extends StatefulWidget {
  const NexApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<NexApp> createState() => _NexAppState();
}

class _NexAppState extends State<NexApp> {
  Locale _locale = const Locale('en');
  static _NexAppState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this;
    _loadLocale();
  }

  static Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nex_language', locale.languageCode);
    _instance?.setState(() => _instance?._locale = locale);
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('nex_language');
    if (langCode != null && mounted) {
      setState(() => _locale = Locale(langCode));
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      navigatorKey: NexApp.navigatorKey,
      initialLocation: '/devices',
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final loggedIn = auth.isLoggedIn;
        final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/2fa';

        if (!loggedIn && !loggingIn) return '/login';
        if (loggedIn && loggingIn) return '/devices';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const AuthScreen(mode: AuthMode.login),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const AuthScreen(mode: AuthMode.register),
        ),
        GoRoute(
          path: '/2fa',
          builder: (context, state) => const TwoFactorScreen(),
        ),
        GoRoute(
          path: '/devices',
          builder: (context, state) => const ControlCenterScreen(),
        ),
        GoRoute(
          path: '/devices/list',
          builder: (context, state) => const DeviceListScreen(),
        ),
        GoRoute(
          path: '/session/:id',
          builder: (context, state) {
            final sessionId = state.pathParameters['id']!;
            return SessionScreen(sessionId: sessionId);
          },
        ),
        GoRoute(
          path: '/sessions',
          builder: (context, state) => const SessionListScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/shares',
          builder: (context, state) => const ShareListScreen(),
        ),
        GoRoute(
          path: '/shares/:id',
          builder: (context, state) {
            final shareId = int.parse(state.pathParameters['id']!);
            return ShareBrowserScreen(shareId: shareId);
          },
        ),
        GoRoute(
          path: '/screen-wall',
          builder: (context, state) => const ScreenWallScreen(),
        ),
        GoRoute(
          path: '/meetings',
          builder: (context, state) => const MeetingListScreen(),
        ),
        GoRoute(
          path: '/meeting-create',
          builder: (context, state) => const MeetingCreateScreen(),
        ),
        GoRoute(
          path: '/meeting-room/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return MeetingRoomScreen(meetingId: id);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: AppLocalizations.of(context)?.appName ?? 'NEX',
      theme: NexTheme.light(),
      darkTheme: NexTheme.dark(),
      themeMode: ThemeMode.system,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
