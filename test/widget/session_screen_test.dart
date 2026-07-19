import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/session/session_screen.dart';

void main() {
  group('SessionScreen', () {
    testWidgets('renders screen selector title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionScreen(sessionId: 'test-session'),
        ),
      );
      expect(find.text('Select screens to share'), findsOneWidget);
    });

    testWidgets('shows start button or loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionScreen(sessionId: 'test-session'),
        ),
      );
      expect(
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
        find.text('Start Session').evaluate().isNotEmpty ||
        find.text('Select at least one screen').evaluate().isNotEmpty,
        true,
      );
    });
  });
}
