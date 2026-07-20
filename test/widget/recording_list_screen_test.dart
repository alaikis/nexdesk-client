import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/session/recording_list_screen.dart';
import 'package:flutter_app/core/session_recording.dart';

void main() {
  group('RecordingListScreen', () {
    testWidgets('shows no recordings yet when list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RecordingListScreen(sessionId: 'test-session'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('No recordings yet'), findsOneWidget);
    });
  });
}
