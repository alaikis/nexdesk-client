import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/two_factor_screen.dart';
import 'features/devices/device_list_screen.dart';
import 'features/session/session_screen.dart';
import 'features/sessions/session_list_screen.dart';
import 'features/settings/settings_screen.dart';

class NexApp extends StatelessWidget {
  const NexApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      ],
    );

    return MaterialApp.router(
      title: 'NEX',
      theme: NexTheme.light(),
      darkTheme: NexTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
