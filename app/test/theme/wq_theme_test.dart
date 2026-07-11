import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/theme/wq_colors.dart';
import 'package:wonder_quest/theme/wq_theme.dart';

void main() {
  group('WqColors', () {
    test('orange has correct hex value', () {
      expect(WqColors.orange, const Color(0xFFFF8A3D));
    });

    test('background has correct hex value', () {
      expect(WqColors.background, const Color(0xFFFFF8EE));
    });

    test('landColors contains 8 colors', () {
      expect(WqColors.landColors, hasLength(8));
    });

    test('landColors starts with orange and ends with pink', () {
      expect(WqColors.landColors.first, WqColors.orange);
      expect(WqColors.landColors.last, WqColors.pink);
    });
  });

  group('WqTheme', () {
    testWidgets('scaffold background matches WqColors.background',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WqTheme.theme,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final resolvedColor = scaffold.backgroundColor;
      // The scaffold should use the theme's scaffoldBackgroundColor.
      expect(
        resolvedColor ?? Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor,
        WqColors.background,
      );
    });

    testWidgets('theme fontFamily is Nunito', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WqTheme.theme,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Nunito');
    });

    test('headingStyle returns Baloo2 bold', () {
      final style = WqTheme.headingStyle(24);
      expect(style.fontFamily, 'Baloo2');
      expect(style.fontWeight, FontWeight.w700);
      expect(style.fontSize, 24);
      expect(style.color, WqColors.ink);
    });
  });
}
