import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nex/widgets/empty_state.dart';
import 'package:nex/l10n/app_localizations.dart';

void main() {
  testWidgets('EmptyState renders text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EmptyState(),
        ),
      ),
    );
    expect(find.text('No devices yet'), findsOneWidget);
  });
}
