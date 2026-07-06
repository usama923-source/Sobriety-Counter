import 'package:flutter_test/flutter_test.dart';
import 'package:quit_drinking/main.dart';

void main() {
  testWidgets('Sober Today app renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SoberTodayApp());

    // Verify the app title is displayed
    expect(find.text('Sober Today'), findsOneWidget);
  });
}
