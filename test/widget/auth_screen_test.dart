import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nex/features/auth/auth_screen.dart';
import 'package:nex/features/auth/auth_provider.dart';
import 'package:nex/l10n/app_localizations.dart';

void main() {
  group('AuthScreen', () {
    testWidgets('renders login mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const AuthScreen(mode: AuthMode.login),
          ),
        ),
      );
      expect(find.text('Sign in to NEX'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders register mode with name field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const AuthScreen(mode: AuthMode.register),
          ),
        ),
      );
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows submit button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChangeNotifierProvider(
            create: (_) => AuthProvider(),
            child: const AuthScreen(mode: AuthMode.login),
          ),
        ),
      );
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
