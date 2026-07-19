import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/features/session/file_transfer_screen.dart';

void main() {
  group('FileTransferScreen', () {
    testWidgets('shows no transfers yet when list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FileTransferScreen(sessionId: 'test-session'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('No transfers yet'), findsOneWidget);
    });
  });
}
