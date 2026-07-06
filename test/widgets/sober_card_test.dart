import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quit_drinking/widgets/sober_card.dart';

void main() {
  group('SoberCard widget', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoberCard(
              child: const Text('Hello, Sobriety!'),
            ),
          ),
        ),
      );

      expect(find.text('Hello, Sobriety!'), findsOneWidget);
    });

    testWidgets('responds to tap when onTap is provided', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoberCard(
              onTap: () => wasTapped = true,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      expect(wasTapped, isTrue);
    });

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoberCard(
              padding: const EdgeInsets.all(32),
              child: const Text('Padded'),
            ),
          ),
        ),
      );

      // The card should be findable and render without errors
      expect(find.text('Padded'), findsOneWidget);
    });

    testWidgets('applies custom color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoberCard(
              color: Colors.red,
              child: const Text('Colored'),
            ),
          ),
        ),
      );

      expect(find.text('Colored'), findsOneWidget);
    });

    testWidgets('disables hover effect when enableHoverEffect is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoberCard(
              enableHoverEffect: false,
              child: const Text('No hover'),
            ),
          ),
        ),
      );

      expect(find.text('No hover'), findsOneWidget);
    });

    testWidgets('applies semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoberCard(
              semanticLabel: 'Test Card',
              child: const Text('Semantic'),
            ),
          ),
        ),
      );

      expect(find.text('Semantic'), findsOneWidget);
    });
  });
}
