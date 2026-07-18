import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/devices/device_list_screen.dart';
import 'features/session/session_screen.dart';

class NexApp extends StatelessWidget {
  const NexApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/devices',
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final loggedIn = auth.isLoggedIn;
        final loggingIn = state.matchedLocation == '/login';

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
      ],
    );

    return MaterialApp.router(
      title: 'NEX',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.black.withOpacity(0.04)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5F7),
          foregroundColor: Color(0xFF1D1D1F),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1D1D1F),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFF1D1D1F),
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFF1D1D1F),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF1D1D1F),
            fontSize: 15,
            height: 1.4,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF6E6E73),
            fontSize: 13,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF007AFF),
            side: const BorderSide(color: Color(0xFF007AFF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A84FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF000000),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C1C1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          foregroundColor: Color(0xFFF5F5F7),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
