import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nex/features/auth/auth_screen.dart';
import 'package:nex/features/auth/auth_provider.dart';
import 'package:nex/l10n/app_localizations.dart';

void main() {
  group('AuthScreen', () {
    Widget buildApp() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const AuthScreen(),
        ),
      );
    }

    testWidgets('renders SSO login button', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('Sign in to LitchiViewer'), findsOneWidget);
      expect(find.text('Sign in with Browser'), findsOneWidget);
      // 不再渲染邮箱/密码表单
      expect(find.text('Email'), findsNothing);
      expect(find.text('Password'), findsNothing);
    });

    testWidgets('shows branding icon', (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.byIcon(Icons.desktop_windows), findsOneWidget);
    });
  });
}