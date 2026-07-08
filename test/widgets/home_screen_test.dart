import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quit_drinking/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('HomeScreen widget', () {
    testWidgets('renders without crashing', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Should render the header
      expect(find.byType(HomeScreen), findsOneWidget);

      // Wait for initial load animation to complete and let services init
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Header elements should appear after the loading overlay fades
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('has dark mode toggle', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Wait for smooth page loading and let services init
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // The theme toggle icon button should exist
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    });
  });
}
