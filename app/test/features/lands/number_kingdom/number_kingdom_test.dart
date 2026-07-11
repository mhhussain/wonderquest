import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/numbers_content.dart';
import 'package:wonder_quest/core/audio/sfx_service.dart';
import 'package:wonder_quest/core/audio/tts_service.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';
import 'package:wonder_quest/features/lands/number_kingdom/count_match_game.dart';
import 'package:wonder_quest/features/lands/number_kingdom/missing_number_game.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// In-memory [SaveFileStore] — no real file I/O.
class _MemStore extends SaveFileStore {
  _MemStore() : super(Directory.systemTemp);

  SaveData? _seeded;

  @override
  Future<SaveData> load() =>
      Future.value(_seeded ?? SaveData.initial(profileId: 'mem'));

  @override
  Future<void> save(SaveData data) async => _seeded = data;
}

/// No-op [SfxService] — avoids platform audio channels in tests.
class _FakeSfxService implements SfxService {
  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> playWhaleCall(double baseFreqHz) async {}
}

/// Fake [TtsBackend] that records calls without touching platform channels.
class _FakeTtsBackend implements TtsBackend {
  final List<String> spoken = [];

  @override
  Future<dynamic> getVoices() async => <Map<String, String>>[];

  @override
  Future<void> setLanguage(String locale) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<dynamic> speak(String text) async {
    spoken.add(text);
    return 1;
  }

  @override
  Future<void> stop() async {}
}

// ---------------------------------------------------------------------------
// Harness helpers
// ---------------------------------------------------------------------------

/// Wraps [child] with the minimum [ProviderScope] overrides required by
/// Number Kingdom widgets: save store + TTS + SFX.
Widget _harness({
  required Widget child,
  required _MemStore store,
  required _FakeTtsBackend fakeTts,
}) {
  return ProviderScope(
    overrides: [
      saveStoreProvider.overrideWithValue(store),
      ttsServiceProvider.overrideWith(
        (ref) => TtsService(fakeTts, soundOn: () => true),
      ),
      sfxServiceProvider.overrideWithValue(_FakeSfxService()),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

/// Pumps twice to settle [AsyncNotifier.build] (microtask-based).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── Test 1 + 2: Count game choice gate and tally ─────────────────────────
  group('CountMatchQuestion', () {
    // Use a predictable round: 3 apples.
    const round = CountRound(emoji: '🍎', count: 3);

    testWidgets(
      'choices are gated — tapping choice before all objects does nothing',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();
        var advanced = false;

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: CountMatchQuestion(
              round: round,
              advance: () => advanced = true,
            ),
          ),
        );
        await _settle(tester);

        // The IgnorePointer should be absorbing (choices disabled).
        final ignoreFinder = find.byType(IgnorePointer);
        final ignoreWidgets = tester
            .widgetList<IgnorePointer>(ignoreFinder)
            .where((w) => w.ignoring)
            .toList();
        expect(
          ignoreWidgets,
          isNotEmpty,
          reason: 'at least one IgnorePointer must be ignoring before all '
              'objects are counted',
        );

        // Tap every visible choice key — none should trigger advance.
        // (IgnorePointer absorbs the taps.)
        for (final n in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]) {
          final f = find.byKey(Key('count-choice-$n'));
          if (tester.any(f)) {
            await tester.tap(f, warnIfMissed: false);
            await tester.pump();
          }
        }
        await tester.pump(const Duration(milliseconds: 1200));
        expect(advanced, isFalse,
            reason: 'advance must not fire before all objects counted');
      },
    );

    testWidgets(
      'tally equals object count after tapping all objects',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: CountMatchQuestion(
              round: round,
              advance: () {},
            ),
          ),
        );
        await _settle(tester);

        // Tap all 3 objects one by one.
        for (var k = 0; k < round.count; k++) {
          await tester.tap(find.byKey(Key('count-obj-$k')));
          await tester.pump();
        }

        // After tapping all, the last badge should show '3' (== round.count).
        expect(
          find.text('${round.count}'),
          findsWidgets,
          reason: 'badge text matching count (${ round.count}) must appear '
              'after all objects tapped',
        );

        // And the IgnorePointer covering choices should no longer be ignoring.
        final ignoreFinder = find.byType(IgnorePointer);
        final stillIgnoring = tester
            .widgetList<IgnorePointer>(ignoreFinder)
            .where((w) => w.ignoring)
            .toList();
        expect(
          stillIgnoring,
          isEmpty,
          reason: 'IgnorePointer must stop absorbing after all objects counted',
        );
      },
    );

    testWidgets(
      'correct choice advances after all objects are counted',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();
        var advanced = false;

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: CountMatchQuestion(
              round: round,
              advance: () => advanced = true,
            ),
          ),
        );
        await _settle(tester);

        // Tap all 3 objects.
        for (var k = 0; k < round.count; k++) {
          await tester.tap(find.byKey(Key('count-obj-$k')));
          await tester.pump();
        }

        // Tap the correct answer button (key == 'count-choice-3').
        await tester.tap(find.byKey(const Key('count-choice-3')));
        await tester.pump();

        // Advance fires after ~1.1 s delay.
        await tester.pump(const Duration(milliseconds: 1200));
        expect(advanced, isTrue,
            reason: 'correct choice after full count should advance');
      },
    );
  });

  // ── Test 3: Missing number correct choice fills gap and advances ──────────
  group('MissingNumberQuestion', () {
    // seq=[3,4,5,6,7], missIdx=2, answer=5, choices=[4,5,6] (sorted)
    const round = MissingNumberRound(
      seq: [3, 4, 5, 6, 7],
      missIdx: 2,
      answer: 5,
      choices: [4, 5, 6],
    );

    testWidgets(
      'correct choice fills the gap and advances',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();
        var advanced = false;

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: MissingNumberQuestion(
              round: round,
              advance: () => advanced = true,
            ),
          ),
        );
        await _settle(tester);

        // Initially the gap shows '?'.
        expect(
          find.text('?'),
          findsOneWidget,
          reason: 'gap tile must show ? before answer is chosen',
        );

        // Tap the correct choice (5).
        await tester.tap(find.byKey(const Key('missing-choice-5')));
        await tester.pump();

        // Gap tile should now show the answer.
        expect(
          find.text('5'),
          findsWidgets,
          reason: 'gap tile must show the answer after correct choice',
        );

        // Advance fires after ~1 s delay.
        await tester.pump(const Duration(milliseconds: 1100));
        expect(advanced, isTrue,
            reason: 'advance must fire after correct missing-number choice');

        // Verify mastery was written: reload from store and check numbersMastered.
        final saved = await store.load();
        expect(
          saved.numbersMastered.contains('${round.answer}'),
          isTrue,
          reason: 'answered number must be recorded in numbersMastered',
        );
      },
    );

    testWidgets(
      'wrong choice does not fill gap and does not advance',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();
        var advanced = false;

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: MissingNumberQuestion(
              round: round,
              advance: () => advanced = true,
            ),
          ),
        );
        await _settle(tester);

        // Tap a wrong choice (4).
        await tester.tap(find.byKey(const Key('missing-choice-4')));
        await tester.pump();

        // Gap still shows '?' (wrong choice does not fill gap).
        expect(
          find.text('?'),
          findsOneWidget,
          reason: 'gap must still show ? after wrong choice',
        );

        // Advance must not fire.
        await tester.pump(const Duration(milliseconds: 1100));
        expect(advanced, isFalse,
            reason: 'advance must not fire after wrong choice');
      },
    );
  });
}
