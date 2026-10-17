import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quit_drinking/services/sobriety_service.dart';
import 'package:quit_drinking/widgets/sobriety_counter_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCard(WidgetTester tester, SobrietyService service) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SobrietyCounterCard(service: service),
          ),
        ),
      ),
    );
  }

  testWidgets('waits for storage instead of prompting for a quit date',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'sobriety_start_date': DateTime(2026, 10, 1).millisecondsSinceEpoch,
    });
    // Not initialized: this is the launch moment where the stored date has not
    // been read yet, so the card must not claim there is no date.
    final service = SobrietyService();
    addTearDown(service.dispose);

    await pumpCard(tester, service);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Begin Your Journey'), findsNothing);
  });

  testWidgets('shows the live counter for a stored date, never the prompt',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'sobriety_start_date': DateTime(2026, 10, 1).millisecondsSinceEpoch,
    });
    final service = SobrietyService();
    await service.init();

    await pumpCard(tester, service);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Begin Your Journey'), findsNothing);
    expect(find.text('Your Sobriety Journey'), findsOneWidget);

    // Stop the live counter's timer before the test ends.
    service.dispose();
  });

  testWidgets('asks for a quit date only when none is actually stored',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = SobrietyService();
    await service.init();

    await pumpCard(tester, service);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Begin Your Journey'), findsOneWidget);

    service.dispose();
  });
}
