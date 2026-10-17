import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quit_drinking/core/providers/currency_provider.dart';
import 'package:quit_drinking/services/savings_service.dart';
import 'package:quit_drinking/services/sobriety_service.dart';
import 'package:quit_drinking/widgets/money_saved_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the money symbol follows the currency selection immediately',
      (tester) async {
    SharedPreferences.setMockInitialValues({'currency': 'USD'});

    // Not initialized: no quit date, so no live counter timer in this test.
    final sobriety = SobrietyService();
    addTearDown(sobriety.dispose);

    // Mirrors the home screen: the card is rebuilt by a watcher of the
    // currency provider, exactly as HomeScreen does.
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => SingleChildScrollView(
                child: MoneySavedCard(
                  savingsService: SavingsService(),
                  sobrietyService: sobriety,
                  currencyService: ref.watch(currencyServiceProvider),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(r'$0'), findsOneWidget);
    expect(find.text(r'Based on 5 drinks at $5.00 each'), findsOneWidget);
    expect(find.text(r'$25'), findsOneWidget);

    // Change the currency the way Settings does.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MoneySavedCard)),
    );
    await container.read(currencyServiceProvider).setCurrency('EUR');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // let the swap animation end

    expect(find.text('€0'), findsOneWidget);
    expect(find.text('Based on 5 drinks at €5.00 each'), findsOneWidget);
    expect(find.text('€25'), findsOneWidget);
    expect(find.text(r'$0'), findsNothing);

    // And the choice is written to storage for the next launch.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('currency'), 'EUR');
  });
}
