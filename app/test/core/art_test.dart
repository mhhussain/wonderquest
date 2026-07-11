import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/art.dart';

void main() {
  group('Art.emoji', () {
    test('rexy maps to dinosaur emoji', () {
      expect(Art.emoji('rexy'), '🦖');
    });

    test('egg maps to egg emoji', () {
      expect(Art.emoji('egg'), '🥚');
    });

    test('star maps to star emoji', () {
      expect(Art.emoji('star'), '⭐');
    });

    test('lock maps to lock emoji', () {
      expect(Art.emoji('lock'), '🔒');
    });

    test('parent maps to family emoji', () {
      expect(Art.emoji('parent'), '👪');
    });

    test('sound-on maps to speaker emoji', () {
      expect(Art.emoji('sound-on'), '🔊');
    });

    test('sound-off maps to speaker-off emoji', () {
      expect(Art.emoji('sound-off'), '🔇');
    });

    test('passthrough: unknown key that is already emoji returns as-is', () {
      expect(Art.emoji('🐝'), '🐝');
    });

    test('passthrough: emoji-like unknown key returns as-is', () {
      expect(Art.emoji('🌟'), '🌟');
    });
  });

  group('Art.glyph', () {
    testWidgets('glyph renders Text widget with emoji', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Art.glyph('rexy'),
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
      final textWidget = find.byType(Text).evaluate().first.widget as Text;
      expect(textWidget.data, '🦖');
      expect(textWidget.style?.fontSize, 48);
    });

    testWidgets('glyph uses custom size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Art.glyph('star', size: 64),
          ),
        ),
      );

      final textWidget = find.byType(Text).evaluate().first.widget as Text;
      expect(textWidget.data, '⭐');
      expect(textWidget.style?.fontSize, 64);
    });

    testWidgets('glyph with passthrough emoji', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Art.glyph('🐝'),
          ),
        ),
      );

      final textWidget = find.byType(Text).evaluate().first.widget as Text;
      expect(textWidget.data, '🐝');
    });
  });

  test('mascot constant is rexy', () {
    expect(Art.mascot, 'rexy');
  });
}
