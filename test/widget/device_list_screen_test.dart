import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/devices/device_list_screen.dart';
import 'package:flutter_app/features/devices/device_provider.dart';

void main() {
  group('DeviceListScreen', () {
    testWidgets('shows progress indicator while loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => DeviceProvider(),
            child: const DeviceListScreen(),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
