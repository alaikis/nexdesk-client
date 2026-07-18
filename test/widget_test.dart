import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../lib/app.dart';
import '../lib/features/auth/auth_provider.dart';
import '../lib/features/devices/device_provider.dart';
import '../lib/features/session/session_provider.dart';

void main() {
  testWidgets('NexApp smoke test', (WidgetTester tester) async {
    final auth = AuthProvider();
    await auth.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider(create: (_) => DeviceProvider()),
          ChangeNotifierProvider(create: (_) => SessionProvider()),
        ],
        child: const NexApp(),
      ),
    );

    expect(find.byType(NexApp), findsOneWidget);
  });
}
