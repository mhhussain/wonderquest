import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/features/spike/tts_spike_screen.dart';

void main() {
  // Wrap in MaterialApp so Navigator, Theme, and Directionality are available.
  Widget buildSubject() => const MaterialApp(home: TtsSpikeScreen());

  group('TtsSpikeScreen', () {
    testWidgets('renders app-bar title', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('Arabic TTS Spike (Debug)'), findsOneWidget);
    });

    testWidgets('renders List Voices button', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byKey(const Key('btn_list_voices')), findsOneWidget);
    });

    testWidgets('renders Speak Ba button', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byKey(const Key('btn_speak_ba')), findsOneWidget);
    });

    testWidgets('renders Speak Batta button', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byKey(const Key('btn_speak_batta')), findsOneWidget);
    });

    testWidgets('renders Speak English Fallback button', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byKey(const Key('btn_speak_english')), findsOneWidget);
    });

    testWidgets('renders Stop button', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byKey(const Key('btn_stop')), findsOneWidget);
    });

    testWidgets('shows Arabic glyphs for Baa and Batta buttons', (tester) async {
      await tester.pumpWidget(buildSubject());
      // ب (Baa) and بَطَّة (Batta) glyphs should appear in the button labels
      expect(find.text('ب'), findsOneWidget);
      expect(find.text('بَطَّة'), findsOneWidget);
    });

    testWidgets('shows empty-state prompt before any action', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('Tap a button to begin.'), findsOneWidget);
    });
  });
}
