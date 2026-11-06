import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nex/features/session/recording_list_screen.dart';
import 'package:nex/l10n/app_localizations.dart';

void main() {
  group('RecordingListScreen', () {
    testWidgets('shows no recordings yet when list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RecordingListScreen(sessionId: 'test-session'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('No recordings yet'), findsOneWidget);
    });
  });
}
