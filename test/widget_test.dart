import 'package:andco/main.dart';
import 'package:andco/core/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App Widget Tests', () {
    testWidgets('Splash screen loads correctly', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
        const ProviderScope(
          child: AndcoApp(),
        ),
      );

      // Verify that the splash screen loads with app name
      expect(find.text('Andco'), findsOneWidget);
      expect(find.text('Smart School Transport'), findsOneWidget);
      expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);
    });

    testWidgets('Theme switching works correctly', (WidgetTester tester) async {
      // Build our app
      await tester.pumpWidget(
        const ProviderScope(
          child: AndcoApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Get the ThemeService provider
      final container = ProviderContainer();
      final themeService = container.read(themeServiceProvider.notifier);

      // Test light theme
      themeService.setThemeMode(AppThemeMode.light);
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is MaterialApp && widget.theme?.brightness == Brightness.light,
        ),
        findsOneWidget,
      );

      // Test dark theme
      themeService.setThemeMode(AppThemeMode.dark);
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is MaterialApp && widget.darkTheme?.brightness == Brightness.dark,
        ),
        findsOneWidget,
      );

      // Clean up
      container.dispose();
    });

    testWidgets('App handles system theme changes', (WidgetTester tester) async {
      // Build our app with system theme mode
      await tester.pumpWidget(
        const ProviderScope(
          child: AndcoApp(),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderContainer();
      final themeService = container.read(themeServiceProvider.notifier);

      // Set to system theme mode
      themeService.setThemeMode(AppThemeMode.system);
      await tester.pump();

      // Verify the app responds to system theme
      expect(
        find.byWidgetPredicate(
          (widget) => widget is MaterialApp && widget.themeMode == ThemeMode.system,
        ),
        findsOneWidget,
      );

      // Clean up
      container.dispose();
    });

    testWidgets('App handles errors gracefully', (WidgetTester tester) async {
      // Build our app with an error-throwing widget
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => throw Exception('Test error'),
            ),
          ),
        ),
      );

      // Expect error widget to be shown
      await tester.pumpAndSettle();
      expect(find.byType(ErrorWidget), findsOneWidget);
    });
  });
}