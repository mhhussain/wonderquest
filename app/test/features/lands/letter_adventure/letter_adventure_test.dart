import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/english_letters.dart';
import 'package:wonder_quest/core/audio/sfx_service.dart';
import 'package:wonder_quest/core/audio/tts_service.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';
import 'package:wonder_quest/features/lands/letter_adventure/match_letters_game.dart';
import 'package:wonder_quest/features/lands/letter_adventure/reading_words_game.dart';
import 'package:wonder_quest/features/lands/letter_adventure/trace_letters_game.dart';

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
/// Letter Adventure widgets: save store + TTS + SFX.
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

/// Simulates a pan gesture across a [TraceCanvas] to fire its [onCovered]
/// callback via the real widget path.
///
/// The guide point must be at [Offset(50, 50)] in local canvas coords
/// (i.e., [debugGuidePoints] was set to `[Offset(50, 50)]`). The 40 px
/// horizontal sweep exceeds [kTouchSlop] (18 px) and passes within the
/// 28 px tolerance of the guide point.
Future<void> _panCanvas(WidgetTester tester, Finder canvasFinder) async {
  final topLeft = tester.getTopLeft(canvasFinder);
  final gesture = await tester.startGesture(
    Offset(topLeft.dx + 30, topLeft.dy + 50),
  );
  await tester.pump();
  await gesture.moveTo(Offset(topLeft.dx + 70, topLeft.dy + 50));
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── Test 1: Match game includes confusable ─────────────────────────────────
  group('MatchQuestion', () {
    testWidgets(
      "shows 'd' as a choice when the letter is 'B' (b↔d confusable)",
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();

        // Letter B: lowercase 'b', confusable 'd'.
        final letterB =
            kEnglishLetters.firstWhere((e) => e.u == 'B');

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: MatchQuestion(
              letter: letterB,
              advance: () {},
            ),
          ),
        );
        await _settle(tester);

        // There must be exactly 3 choice buttons and one of them must be 'd'.
        // The choices are rendered as Text widgets with the lowercase letter.
        expect(
          find.text('d'),
          findsOneWidget,
          reason: "confusable 'd' must appear as a choice for letter B",
        );
      },
    );

    testWidgets(
      'tapping correct answer calls advance after delay',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();
        var advanced = false;

        final letterA = kEnglishLetters.firstWhere((e) => e.u == 'A');

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: MatchQuestion(
              letter: letterA,
              advance: () => advanced = true,
            ),
          ),
        );
        await _settle(tester);

        // Tap the 'a' choice.
        await tester.tap(find.text('a'));
        await tester.pump();

        // Advance fires after ~1.1 s.
        await tester.pump(const Duration(milliseconds: 1200));
        expect(advanced, isTrue);
      },
    );
  });

  // ── Test 2: Reading Words accepts correct / rejects wrong ──────────────────
  group('ReadingWordsQuestion', () {
    // Use the BAT family: miss=['B'], end='AT', distract=['C','H','R'].
    final bat = kWordFamilies.firstWhere((w) => w.word == 'BAT');

    testWidgets(
      'dragging correct letter fills the slot',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();
        var advanced = false;

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: ReadingWordsQuestion(
              round: bat,
              advance: () => advanced = true,
            ),
          ),
        );
        await _settle(tester);

        // Find the 'B' tile (tile-B-0) and the DragTarget.
        final bTileFinder = find.byKey(const Key('tile-B-0'));
        final targetFinder = find.byKey(const Key('word-target'));

        expect(bTileFinder, findsOneWidget, reason: 'B tile must be present');
        expect(targetFinder, findsOneWidget,
            reason: 'word-target must be present');

        // Simulate drag: press on tile, move to target, release.
        final tileCenter = tester.getCenter(bTileFinder);
        final targetCenter = tester.getCenter(targetFinder);

        final gesture = await tester.startGesture(tileCenter);
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.moveTo(targetCenter);
        await tester.pump();
        await gesture.up();
        await tester.pump();
        await tester.pump();

        // Slot should now show 'B' (filled).
        // The word advances after 1.5 s delay — pump past it.
        await tester.pump(const Duration(milliseconds: 1600));
        expect(advanced, isTrue, reason: 'correct drop should advance the word');
      },
    );

    testWidgets(
      'dragging wrong letter does not fill the slot',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();
        var advanced = false;

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: ReadingWordsQuestion(
              round: bat,
              advance: () => advanced = true,
            ),
          ),
        );
        await _settle(tester);

        // Find the 'C' tile (wrong letter) and the DragTarget.
        // The tile index depends on shuffle order — find by text 'C' in tiles.
        // The tiles are: ['B','C','H','R'] shuffled. Find any 'C' tile.
        final cTileFinder = find.byWidgetPredicate(
          (w) => w is Text && w.data == 'C',
        );
        final targetFinder = find.byKey(const Key('word-target'));

        // There may be multiple Text('C') — pick the one in the tile tray.
        // Use the _TileFace widget which contains the Text.
        // Since tiles are Draggable<String>, find the draggable with data 'C'.
        // We can find it by iterating — use firstMatchingWidget.

        // Drag the wrong tile.
        final cCenter = tester.getCenter(cTileFinder.first);
        final targetCenter = tester.getCenter(targetFinder);

        final gesture = await tester.startGesture(cCenter);
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.moveTo(targetCenter);
        await tester.pump();
        await gesture.up();
        await tester.pump();
        await tester.pump();

        // Wrong drop: word should NOT be assembled, advance should not fire.
        expect(
          advanced,
          isFalse,
          reason: 'wrong drop must not advance the word',
        );

        // The slot should still show '?' (unfilled).
        expect(
          find.text('?'),
          findsOneWidget,
          reason: 'slot must still show ? after wrong drop',
        );
      },
    );
  });

  // ── Test 3: Trace Letters mastery via widget path ──────────────────────────
  group('LetterPairTraceQuestion (mastery tracking)', () {
    // Both tests use debugGuidePoints at Offset(50, 50) so that a 40 px
    // horizontal pan (via _panCanvas) covers the guide point and fires the
    // real onCovered → _checkBothCovered → setLetterLearning/setLetterMastered
    // path without bypassing the widget dispatch.

    testWidgets(
      'tracing A in one game adds it to lettersLearning',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();

        final letterA = kEnglishLetters.firstWhere((e) => e.u == 'A');

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: LetterPairTraceQuestion(
              letter: letterA,
              advance: () {},
              debugUpperGuidePoints: const [Offset(50, 50)],
              debugLowerGuidePoints: const [Offset(50, 50)],
            ),
          ),
        );
        await _settle(tester);

        // Verify 'A' is not yet in learning.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(LetterPairTraceQuestion)),
        );
        await container.read(saveControllerProvider.future);
        expect(
          container.read(saveControllerProvider).requireValue.lettersLearning,
          isNot(contains('A')),
        );

        // Pan both canvases — fires the real _checkBothCovered branch.
        await _panCanvas(tester, find.byKey(const ValueKey('upper-0')));
        await _panCanvas(tester, find.byKey(const ValueKey('lower-0')));

        // Settle microtasks so the unawaited setLetterLearning completes.
        await tester.pump();
        await tester.pump();

        expect(
          container.read(saveControllerProvider).requireValue.lettersLearning,
          contains('A'),
          reason: 'A must be in lettersLearning after first trace',
        );
        expect(
          container.read(saveControllerProvider).requireValue.lettersMastered,
          isNot(contains('A')),
          reason: 'A must NOT be mastered after only one trace',
        );

        // Drain the 1.5 s advance timer from _checkBothCovered.
        await tester.pump(const Duration(milliseconds: 1600));
      },
    );

    testWidgets(
      'tracing A in a second game promotes it to lettersMastered',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();

        // Pre-seed: 'A' is already in lettersLearning (traced once before).
        await store.save(
          SaveData.initial(profileId: 'mastery-test').copyWith(
            lettersLearning: const ['A'],
          ),
        );

        final letterA = kEnglishLetters.firstWhere((e) => e.u == 'A');

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: LetterPairTraceQuestion(
              letter: letterA,
              advance: () {},
              debugUpperGuidePoints: const [Offset(50, 50)],
              debugLowerGuidePoints: const [Offset(50, 50)],
            ),
          ),
        );
        await _settle(tester);

        final container = ProviderScope.containerOf(
          tester.element(find.byType(LetterPairTraceQuestion)),
        );
        await container.read(saveControllerProvider.future);

        // Confirm seed state.
        expect(
          container.read(saveControllerProvider).requireValue.lettersLearning,
          contains('A'),
        );

        // Pan both canvases — since 'A' is already in learning, the widget
        // calls setLetterMastered via the real _checkBothCovered branch.
        await _panCanvas(tester, find.byKey(const ValueKey('upper-0')));
        await _panCanvas(tester, find.byKey(const ValueKey('lower-0')));

        // Settle microtasks so the unawaited setLetterMastered completes.
        await tester.pump();
        await tester.pump();

        expect(
          container.read(saveControllerProvider).requireValue.lettersMastered,
          contains('A'),
          reason: 'A must be in lettersMastered after second trace',
        );
        expect(
          container.read(saveControllerProvider).requireValue.lettersLearning,
          isNot(contains('A')),
          reason: 'A must be removed from lettersLearning when mastered',
        );

        // Drain the 1.5 s advance timer from _checkBothCovered.
        await tester.pump(const Duration(milliseconds: 1600));
      },
    );

    // ── Test 4: Dual-coverage gate ────────────────────────────────────────────
    testWidgets(
      'advance fires only after BOTH canvases are covered',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();
        var advanced = false;

        final letterA = kEnglishLetters.firstWhere((e) => e.u == 'A');

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: LetterPairTraceQuestion(
              letter: letterA,
              advance: () => advanced = true,
              debugUpperGuidePoints: const [Offset(50, 50)],
              debugLowerGuidePoints: const [Offset(50, 50)],
            ),
          ),
        );
        await _settle(tester);

        // Cover upper canvas only — advance must NOT fire.
        await _panCanvas(tester, find.byKey(const ValueKey('upper-0')));
        await tester.pump();
        expect(
          advanced,
          isFalse,
          reason: 'advance must not fire with only upper canvas covered',
        );

        // Cover lower canvas — now both are covered; advance fires after 1.5 s.
        await _panCanvas(tester, find.byKey(const ValueKey('lower-0')));
        await tester.pump(const Duration(milliseconds: 1600));
        expect(
          advanced,
          isTrue,
          reason: 'advance must fire after BOTH canvases are covered',
        );
      },
    );
  });
}
