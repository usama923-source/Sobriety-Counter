import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quit_drinking/screens/home_screen.dart';

void main() {
  group('HomeScreen widget', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Should render the header
      expect(find.byType(HomeScreen), findsOneWidget);

      // Wait for initial load animation to complete
      await tester.pump(const Duration(seconds: 1));

      // Header elements should appear after the loading overlay fades
      // The loading overlay should eventually disappear
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('has dark mode toggle', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Wait for smooth page loading
      await tester.pump(const Duration(seconds: 1));

      // The theme toggle icon button should exist
      // Look for the dark mode icon button by tooltip
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    });
  });
}
