import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nex/features/devices/device_list_screen.dart';
import 'package:nex/features/devices/device_provider.dart';
import 'package:nex/features/devices/group_provider.dart';
import 'package:nex/features/auth/auth_provider.dart';
import 'package:nex/features/session/session_provider.dart';
import 'package:nex/l10n/app_localizations.dart';

void main() {
  group('DeviceListScreen', () {
    testWidgets('builds without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => GroupProvider()),
              ChangeNotifierProvider(create: (_) => SessionProvider()),
              ChangeNotifierProvider(create: (_) => DeviceProvider()),
            ],
            child: const DeviceListScreen(),
          ),
        ),
      );
      expect(find.byType(DeviceListScreen), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => GroupProvider()),
              ChangeNotifierProvider(create: (_) => SessionProvider()),
              ChangeNotifierProvider(create: (_) => DeviceProvider()),
            ],
            child: const DeviceListScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
