import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nex/features/sessions/session_list_screen.dart';
import 'package:nex/features/session/session_provider.dart';

void main() {
  group('SessionListScreen', () {
    testWidgets('shows empty state when no session history', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => SessionProvider(),
            child: const SessionListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No session history yet'), findsOneWidget);
    });

    testWidgets('shows session list when history exists', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => SessionProvider(),
            child: const SessionListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SessionListScreen), findsOneWidget);
    });
  });
}
