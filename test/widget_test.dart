import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quit_drinking/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Sober Today app renders without crashing',
      (WidgetTester tester) async {
    // Initialize SharedPreferences with empty mock values for test environment
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: SoberTodayApp(),
      ),
    );

    // Pump past the splash screen timer (1200ms) and allow HomeScreen
    // providers to initialize without leaving pending periodic timers.
    await tester.pump(const Duration(seconds: 2));
    // Drain one more tick to let any service timers settle.
    await tester.pump(const Duration(seconds: 1));

    // Verify the app renders without crashing by checking for the app title
    expect(find.text('Sober Today'), findsAtLeastNWidgets(1));
  });
}
