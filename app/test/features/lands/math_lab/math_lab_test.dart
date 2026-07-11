import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/math_content.dart';
import 'package:wonder_quest/core/audio/sfx_service.dart';
import 'package:wonder_quest/core/audio/tts_service.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';
import 'package:wonder_quest/features/lands/math_lab/math_station_game.dart';

// ---------------------------------------------------------------------------
// Test doubles  (same pattern as number_kingdom_test.dart)
// ---------------------------------------------------------------------------

class _MemStore extends SaveFileStore {
  _MemStore() : super(Directory.systemTemp);
  SaveData? _seeded;

  @override
  Future<SaveData> load() =>
      Future.value(_seeded ?? SaveData.initial(profileId: 'mem'));

  @override
  Future<void> save(SaveData data) async => _seeded = data;
}

class _FakeSfxService implements SfxService {
  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> playWhaleCall(double baseFreqHz) async {}
}

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
// Harness
// ---------------------------------------------------------------------------

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
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

/// Pumps twice to settle [AsyncNotifier.build].
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Convenience constants
// ---------------------------------------------------------------------------

/// Subtraction station (cookie) — choices are always active, no tap gate.
const _cookieStation = MathStation(
  id: 'cookie',
  title: 'Cookie Math',
  emoji: '🍪',
  obj: '🍪',
  objName: 'cookies',
  color: Color(0xFFFFC53D), // WqColors.yellow
  type: MathType.sub,
);

/// Addition station (snack) — requires tapping all objects first.
const _snackStation = MathStation(
  id: 'snack',
  title: 'Dino Snack Time',
  emoji: '🦖',
  obj: '🍎',
  objName: 'apples',
  color: Color(0xFF7BC043), // WqColors.green
  type: MathType.add,
);

/// Compare station (morles).
const _morlesStation = MathStation(
  id: 'morles',
  title: 'More or Less',
  emoji: '⚖️',
  obj: '🦕',
  objName: 'dinos',
  color: Color(0xFF8B7BE0), // WqColors.grape
  type: MathType.compare,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── 1. Sub problems from genMathProblems never produce a negative answer ───
  group('genMathProblems', () {
    test('sub problems: answer is always ≥ 0 (never negative)', () {
      final pool = genMathProblems(MathType.sub, 'eggs', 80, Random(0xBEEF));
      for (final p in pool) {
        expect(
          p.answer,
          greaterThanOrEqualTo(0),
          reason: 'sub answer must be ≥ 0; got ${p.a} − ${p.b} = ${p.answer}',
        );
        expect(
          p.answer,
          equals(p.a - p.b),
          reason: 'sub answer must equal a − b',
        );
      }
    });

    test('sub problems: all choices are non-negative (pool from cookie)', () {
      final pool = genMathProblems(MathType.sub, 'cookie', 80, Random(0xCAFE));
      for (final p in pool) {
        for (final c in p.choices) {
          expect(c, greaterThanOrEqualTo(0),
              reason: 'choice $c is negative for problem ${p.a}-${p.b}');
        }
      }
    });
  });

  // ── 2. Equation hidden before answer, shown after correct answer ───────────
  group('MathStationQuestion — equation reveal', () {
    // Sub (cookie): no tap gate → can tap choices immediately.
    // Problem: a=5, b=2, answer=3, choices=[1,3,4,6].
    const subProblem = MathProblem(
      a: 5,
      b: 2,
      answer: 3,
      choices: [1, 3, 4, 6],
      obj: '🍪',
    );

    testWidgets('equation is hidden before a correct answer is given',
        (tester) async {
      final store = _MemStore();
      final fakeTts = _FakeTtsBackend();

      await tester.pumpWidget(
        _harness(
          store: store,
          fakeTts: fakeTts,
          child: MathStationQuestion(
            problem: subProblem,
            station: _cookieStation,
            advance: () {},
          ),
        ),
      );
      await _settle(tester);

      // Equation widget must NOT be present before any answer.
      expect(
        find.byKey(const Key('math-equation')),
        findsNothing,
        reason: 'equation must be hidden before the child answers correctly',
      );
    });

    testWidgets('correct answer reveals the equation', (tester) async {
      final store = _MemStore();
      final fakeTts = _FakeTtsBackend();
      var advanced = false;

      await tester.pumpWidget(
        _harness(
          store: store,
          fakeTts: fakeTts,
          child: MathStationQuestion(
            problem: subProblem,
            station: _cookieStation,
            advance: () => advanced = true,
          ),
        ),
      );
      await _settle(tester);

      // Tap the correct choice (answer = 3).
      await tester.tap(find.byKey(const Key('math-choice-3')));
      await tester.pump(); // process setState

      // Equation is now shown.
      expect(
        find.byKey(const Key('math-equation')),
        findsOneWidget,
        reason: 'equation must appear immediately after a correct answer',
      );

      // Advance fires after the built-in delay.
      await tester.pump(const Duration(milliseconds: 1500));
      expect(
        advanced,
        isTrue,
        reason: 'advance must be called after the success delay',
      );
    });

    testWidgets('wrong answer does not reveal equation and does not advance',
        (tester) async {
      final store = _MemStore();
      final fakeTts = _FakeTtsBackend();
      var advanced = false;

      await tester.pumpWidget(
        _harness(
          store: store,
          fakeTts: fakeTts,
          child: MathStationQuestion(
            problem: subProblem,
            station: _cookieStation,
            advance: () => advanced = true,
          ),
        ),
      );
      await _settle(tester);

      // Tap a wrong choice (answer = 3, pick 1 instead).
      await tester.tap(find.byKey(const Key('math-choice-1')));
      await tester.pump();

      // Equation still hidden.
      expect(
        find.byKey(const Key('math-equation')),
        findsNothing,
        reason: 'equation must remain hidden after a wrong answer',
      );

      await tester.pump(const Duration(milliseconds: 1500));
      expect(advanced, isFalse,
          reason: 'advance must not fire after a wrong choice');
    });
  });

  // ── 3. Add gate: choices unlock only after all objects are tapped ──────────
  group('MathStationQuestion — add tap gate', () {
    // Problem: a=2, b=3 → 5 objects total; answer=5, choices=[3,5,6,8].
    const addProblem = MathProblem(
      a: 2,
      b: 3,
      answer: 5,
      choices: [3, 5, 6, 8],
      obj: '🍎',
    );

    testWidgets('choices are gated until all objects are tapped', (tester) async {
      final store = _MemStore();
      final fakeTts = _FakeTtsBackend();
      var advanced = false;

      await tester.pumpWidget(
        _harness(
          store: store,
          fakeTts: fakeTts,
          child: MathStationQuestion(
            problem: addProblem,
            station: _snackStation,
            advance: () => advanced = true,
          ),
        ),
      );
      await _settle(tester);

      // The IgnorePointer covering choices must be ignoring.
      final ignoring = tester
          .widgetList<IgnorePointer>(find.byType(IgnorePointer))
          .where((w) => w.ignoring)
          .toList();
      expect(
        ignoring,
        isNotEmpty,
        reason:
            'IgnorePointer must be ignoring before all objects are tapped',
      );

      // Attempt to tap a choice — should be absorbed.
      for (final n in [3, 5, 6, 8]) {
        final f = find.byKey(Key('math-choice-$n'));
        if (tester.any(f)) {
          await tester.tap(f, warnIfMissed: false);
          await tester.pump();
        }
      }
      await tester.pump(const Duration(milliseconds: 1500));
      expect(advanced, isFalse,
          reason: 'advance must not fire before objects are tapped');

      // Tap all 5 objects (group A: ids 0,1; group B: ids 100,101,102).
      for (final id in [0, 1, 100, 101, 102]) {
        await tester.tap(find.byKey(Key('math-obj-$id')));
        await tester.pump();
      }

      // Choices should now be active.
      final stillIgnoring = tester
          .widgetList<IgnorePointer>(find.byType(IgnorePointer))
          .where((w) => w.ignoring)
          .toList();
      expect(
        stillIgnoring,
        isEmpty,
        reason: 'IgnorePointer must stop ignoring after all objects tapped',
      );

      // Tap the correct answer.
      await tester.tap(find.byKey(const Key('math-choice-5')));
      await tester.pump();

      // Equation revealed.
      expect(find.byKey(const Key('math-equation')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1500));
      expect(advanced, isTrue);
    });
  });

  // ── 4. More-or-Less prompt alternates; correct side advances ───────────────
  group('MathStationQuestion — compare (More or Less)', () {
    // Problem: a=5 (A group), b=3 (B group); answer=1 means A has more.
    const compareProblem = MathProblem(
      a: 5,
      b: 3,
      answer: 1, // 1 = A has more
      choices: [0, 1],
      obj: '🦕',
    );

    testWidgets('prompt shows "MORE" when wantMore=true', (tester) async {
      await tester.pumpWidget(
        _harness(
          store: _MemStore(),
          fakeTts: _FakeTtsBackend(),
          child: MathStationQuestion(
            problem: compareProblem,
            station: _morlesStation,
            wantMore: true,
            advance: () {},
          ),
        ),
      );
      await _settle(tester);

      expect(
        find.text('Which group has MORE?'),
        findsOneWidget,
        reason: 'wantMore=true must display the "MORE" prompt',
      );
    });

    testWidgets('prompt shows "FEWER" when wantMore=false', (tester) async {
      await tester.pumpWidget(
        _harness(
          store: _MemStore(),
          fakeTts: _FakeTtsBackend(),
          child: MathStationQuestion(
            problem: compareProblem,
            station: _morlesStation,
            wantMore: false,
            advance: () {},
          ),
        ),
      );
      await _settle(tester);

      expect(
        find.text('Which group has FEWER?'),
        findsOneWidget,
        reason: 'wantMore=false must display the "FEWER" prompt',
      );
    });

    testWidgets(
        'correct side (A has more, wantMore=true) advances; wrong side does not',
        (tester) async {
      final store = _MemStore();
      final fakeTts = _FakeTtsBackend();
      var advanced = false;

      await tester.pumpWidget(
        _harness(
          store: store,
          fakeTts: fakeTts,
          child: MathStationQuestion(
            problem: compareProblem,
            station: _morlesStation,
            wantMore: true, // want MORE → correct side is A (a=5 > b=3)
            advance: () => advanced = true,
          ),
        ),
      );
      await _settle(tester);

      // Tap the WRONG panel (B has fewer, so B is wrong when wantMore=true).
      await tester.tap(find.byKey(const Key('compare-panel-B')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(advanced, isFalse,
          reason: 'wrong panel must not advance');

      // Tap the CORRECT panel (A has more).
      await tester.tap(find.byKey(const Key('compare-panel-A')));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(advanced, isTrue,
          reason: 'correct panel (A, wantMore=true, A has more) must advance');
    });

    testWidgets(
        'correct side (A has more, wantMore=false) is B (fewer); advances',
        (tester) async {
      final store = _MemStore();
      final fakeTts = _FakeTtsBackend();
      var advanced = false;

      await tester.pumpWidget(
        _harness(
          store: store,
          fakeTts: fakeTts,
          child: MathStationQuestion(
            problem: compareProblem,
            station: _morlesStation,
            wantMore: false, // want FEWER → correct side is B (b=3 < a=5)
            advance: () => advanced = true,
          ),
        ),
      );
      await _settle(tester);

      // Tap the CORRECT panel (B has fewer).
      await tester.tap(find.byKey(const Key('compare-panel-B')));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(advanced, isTrue,
          reason: 'correct panel (B, wantMore=false, B has fewer) must advance');
    });
  });
}
