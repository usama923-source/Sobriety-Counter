import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quit_drinking/widgets/empty_state.dart';

void main() {
  group('EmptyState widget', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.spa_rounded,
              title: 'No data yet',
            ),
          ),
        ),
      );

      // Verify the title is displayed
      expect(find.text('No data yet'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.info_outline,
              title: 'Empty',
              subtitle: 'Add some content to get started',
            ),
          ),
        ),
      );

      expect(find.text('Add some content to get started'), findsOneWidget);
    });

    testWidgets('renders action button when label and callback provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.add,
              title: 'Nothing here',
              actionLabel: 'Add Item',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('does not render action button when onAction is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.add,
              title: 'Nothing here',
              actionLabel: 'Add Item', // label provided but no callback
            ),
          ),
        ),
      );

      // Button should not appear since onAction is null
      expect(find.text('Add Item'), findsNothing);
    });

    testWidgets('responds to action button tap', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.add,
              title: 'Nothing here',
              actionLabel: 'Add',
              onAction: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add'));
      expect(wasTapped, isTrue);
    });
  });
}
