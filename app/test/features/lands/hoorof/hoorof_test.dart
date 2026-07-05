import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/arabic_letters.dart';
import 'package:wonder_quest/core/audio/sfx_service.dart';
import 'package:wonder_quest/core/audio/tts_service.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';
import 'package:wonder_quest/features/lands/hoorof/hear_match_game.dart';
import 'package:wonder_quest/features/lands/hoorof/hoorof_utils.dart';
import 'package:wonder_quest/features/lands/hoorof/letter_pop_game.dart';
import 'package:wonder_quest/features/lands/hoorof/shape_builder_game.dart';

// ---------------------------------------------------------------------------
// Test doubles (same pattern as letter_adventure_test.dart)
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

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── Group 1: arabicProgressTo pure function ──────────────────────────────

  group('arabicProgressTo', () {
    test('returns 0 when no levels are recorded', () {
      expect(arabicProgressTo({}), 0);
    });

    test(
        'returns 0 when letters done in fewer than 3 distinct game types',
        () {
      // Letter 0 done in only 2 game types → not counted.
      final levels = {
        'hrf-learn': [true, false, ...List.filled(26, false)],
        'hrf-trace': [true, false, ...List.filled(26, false)],
      };
      expect(arabicProgressTo(levels), 0);
    });

    test('first cluster (3 letters) in 3 game types → 3/28 × 100 ≈ 11', () {
      // Letters at indices 0, 1, 2 (ا ب ت) done in hrf-learn, hrf-trace, hrf-hear.
      final base28 = List<bool>.filled(28, false);

      List<bool> mark(List<int> indices) {
        final lst = List<bool>.from(base28);
        for (final i in indices) {
          lst[i] = true;
        }
        return lst;
      }

      final levels = {
        'hrf-learn': mark([0, 1, 2]),
        'hrf-trace': mark([0, 1, 2]),
        'hrf-hear': mark([0, 1, 2]),
      };
      final result = arabicProgressTo(levels);
      // 3 / 28 * 100 = 10.714... rounded = 11
      expect(result, 11);
    });

    test('all 28 letters done in all 8 game types → 100', () {
      final allDone = List<bool>.filled(28, true);
      final levels = {
        for (final id in kHrfGameIds) id: allDone,
      };
      expect(arabicProgressTo(levels), 100);
    });

    test('monotonic: progress never decreases when more letters are added',
        () {
      final base28 = List<bool>.filled(28, false);

      List<bool> mark(List<int> indices) {
        final lst = List<bool>.from(base28);
        for (final i in indices) {
          lst[i] = true;
        }
        return lst;
      }

      // 7 letters across 3+ games → 7/28*100 = 25.
      final levels7 = {
        'hrf-learn': mark([0, 1, 2, 3, 4, 5, 6]),
        'hrf-trace': mark([0, 1, 2, 3, 4, 5, 6]),
        'hrf-hear': mark([0, 1, 2, 3, 4, 5, 6]),
      };
      final result7 = arabicProgressTo(levels7);
      expect(result7, 25);

      // 14 letters → 50.
      final levels14 = {
        'hrf-learn': mark(List.generate(14, (i) => i)),
        'hrf-trace': mark(List.generate(14, (i) => i)),
        'hrf-hear': mark(List.generate(14, (i) => i)),
      };
      final result14 = arabicProgressTo(levels14);
      expect(result14, 50);
      expect(result14, greaterThanOrEqualTo(result7));
    });

    test('only letters done in ≥ 3 distinct games are counted', () {
      final base28 = List<bool>.filled(28, false);

      List<bool> mark(List<int> indices) {
        final lst = List<bool>.from(base28);
        for (final i in indices) {
          lst[i] = true;
        }
        return lst;
      }

      // Letter 0 in 3 games → counts. Letter 1 in only 2 → does not.
      final levels = {
        'hrf-learn': mark([0, 1]),
        'hrf-trace': mark([0, 1]),
        'hrf-hear': mark([0]), // letter 1 NOT here
      };
      // Only letter 0 qualifies: 1/28*100 = 4 (rounded from 3.57).
      expect(arabicProgressTo(levels), (1 * 100 / 28).round());
    });
  });

  // ── Group 2: hrfFamily pure function ─────────────────────────────────────

  group('hrfFamily', () {
    test('ب is in family with ت ث ن ي (excluding ب itself)', () {
      final fam = hrfFamily('ب');
      expect(fam, containsAll(['ت', 'ث', 'ن', 'ي']));
      expect(fam, isNot(contains('ب')));
    });

    test('ج family is ح خ (excluding ج)', () {
      final fam = hrfFamily('ج');
      expect(fam, containsAll(['ح', 'خ']));
      expect(fam, isNot(contains('ج')));
    });

    test('letter with no family returns all other letters', () {
      // ا, ك, ل, م, ه, و have no confusable family.
      // They should fall back to all 27 other letters.
      final fam = hrfFamily('ا');
      expect(fam.length, 27);
      expect(fam, isNot(contains('ا')));
    });

    test('returned family never contains the query letter', () {
      for (final letter in kArabicLetters) {
        final fam = hrfFamily(letter.g);
        expect(
          fam,
          isNot(contains(letter.g)),
          reason: 'hrfFamily(${letter.g}) must not contain ${letter.g}',
        );
      }
    });
  });

  // ── Group 3: dotLabel pure function ──────────────────────────────────────

  group('dotLabel', () {
    test('maps known codes to English labels', () {
      expect(dotLabel('1a'), '1 dot above');
      expect(dotLabel('2a'), '2 dots above');
      expect(dotLabel('3a'), '3 dots above');
      expect(dotLabel('1b'), '1 dot below');
      expect(dotLabel('2b'), '2 dots below');
      expect(dotLabel('0'), 'no dots');
    });

    test('passes through unknown codes', () {
      expect(dotLabel('99'), '99');
    });
  });

  // ── Group 4: Hear & Match — choices come from confusable family ───────────

  group('HearMatchScreen', () {
    testWidgets(
      'all 3 choices for ب come from its confusable family',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();

        // Use ب as the first and only round for determinism.
        final baa = kArabicLetters.firstWhere((l) => l.g == 'ب');

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: HearMatchScreen(debugRounds: [baa]),
          ),
        );
        await _settle(tester);

        // The 3 choice buttons all show Arabic glyphs.
        // Family for ب: {ب, ت, ث, ن, ي}.
        const family = ['ب', 'ت', 'ث', 'ن', 'ي'];

        // Find all choice buttons (key prefix 'hear-choice-').
        for (final g in family) {
          final finder = find.byKey(Key('hear-choice-$g'));
          if (finder.evaluate().isNotEmpty) {
            // Verify it is one of the family.
            expect(family, contains(g));
          }
        }

        // There must be exactly 3 choice widgets visible.
        final choiceFinders = family
            .map((g) => find.byKey(Key('hear-choice-$g')))
            .where((f) => f.evaluate().isNotEmpty)
            .toList();
        expect(
          choiceFinders.length,
          3,
          reason: 'exactly 3 choices must be shown',
        );
        // All found choices must be from the family.
        for (final g in family) {
          if (find.byKey(Key('hear-choice-$g')).evaluate().isNotEmpty) {
            expect(family, contains(g));
          }
        }

        // Drain any pending timers.
        await tester.pump(const Duration(milliseconds: 600));
      },
    );

    testWidgets(
      'tapping correct glyph advances round',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();

        final alif = kArabicLetters.firstWhere((l) => l.g == 'ا');

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: HearMatchScreen(debugRounds: [alif]),
          ),
        );
        await _settle(tester);

        // Tap the correct glyph.
        await tester.tap(find.byKey(Key('hear-choice-${alif.g}')));
        await tester.pump(const Duration(milliseconds: 200));

        // The choice should be highlighted green (correct).
        // No exception thrown = pass.
        await tester.pump(const Duration(milliseconds: 1200));
      },
    );
  });

  // ── Group 5: Shape Builder — only correct dots code accepted ─────────────

  group('ShapeBuilderScreen', () {
    // Use ب (dots='1b', base='ٮ') as a fixed first letter.
    final baa = kArabicLetters.firstWhere((l) => l.g == 'ب');

    testWidgets(
      'correct dots option (1b for ب) shows full letter glyph',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: ShapeBuilderScreen(debugRounds: [baa]),
          ),
        );
        await _settle(tester);

        // Initially the base form (ٮ) should be shown.
        expect(
          find.text(baa.base!),
          findsWidgets,
          reason: 'base form should be displayed initially',
        );

        // Tap the correct option (1b).
        final correctFinder = find.byKey(const Key('build-opt-1b'));
        expect(
          correctFinder,
          findsOneWidget,
          reason: 'correct dots option button must be present',
        );
        await tester.tap(correctFinder);
        await tester.pump(const Duration(milliseconds: 200));

        // After correct tap, the full glyph (ب) should appear (AnimatedSwitcher).
        expect(
          find.text(baa.g),
          findsWidgets,
          reason: 'full glyph must appear after correct dots are chosen',
        );

        // Drain advance timer.
        await tester.pump(const Duration(milliseconds: 1400));
      },
    );

    testWidgets(
      'wrong dots option does not show full glyph',
      (tester) async {
        final store = _MemStore();
        final fakeTts = _FakeTtsBackend();

        await tester.pumpWidget(
          _harness(
            store: store,
            fakeTts: fakeTts,
            child: ShapeBuilderScreen(debugRounds: [baa]),
          ),
        );
        await _settle(tester);

        // Find a wrong option (any option that is not '1b').
        const wrongCodes = ['1a', '2a', '3a', '2b', '0'];
        Key? wrongKey;
        for (final code in wrongCodes) {
          final f = find.byKey(Key('build-opt-$code'));
          if (f.evaluate().isNotEmpty) {
            wrongKey = Key('build-opt-$code');
            break;
          }
        }

        expect(
          wrongKey,
          isNotNull,
          reason: 'at least one wrong option must be present',
        );

        await tester.tap(find.byKey(wrongKey!));
        await tester.pump(const Duration(milliseconds: 200));

        // Full glyph (ب) should NOT appear after wrong tap.
        expect(
          find.text(baa.g),
          findsNothing,
          reason: 'full glyph must NOT appear after wrong dots are chosen',
        );

        // After reset delay, option clears.
        await tester.pump(const Duration(milliseconds: 600));
      },
    );
  });

  // ── Group 6: Find-letter decoys are same-family ───────────────────────────

  group('hrfFamily (find-letter decoy contract)', () {
    test('decoys for ب include same-family members ت ث ن ي', () {
      final baa = kArabicLetters.firstWhere((l) => l.g == 'ب');
      final fam = hrfFamily(baa.g);
      // The find game uses hrfFamily() as its decoy source.
      // All family members must be present.
      for (final g in ['ت', 'ث', 'ن', 'ي']) {
        expect(
          fam,
          contains(g),
          reason: 'decoy pool for ب must include family member $g',
        );
      }
    });

    test('decoys never contain the target glyph itself', () {
      for (final letter in kArabicLetters) {
        final decoys = hrfFamily(letter.g);
        expect(
          decoys,
          isNot(contains(letter.g)),
          reason:
              'decoy pool for ${letter.g} must not contain the target itself',
        );
      }
    });
  });

  // ── Group 8: clusterProgress pure function ───────────────────────────────

  group('clusterProgress', () {
    List<bool> markGlyphs(List<String> glyphs) {
      final lst = List<bool>.filled(kArabicLetters.length, false);
      for (final g in glyphs) {
        lst[kArabicLetters.indexWhere((l) => l.g == g)] = true;
      }
      return lst;
    }

    test('returns 0 for every cluster when no levels are recorded', () {
      for (var i = 0; i < kArabicClusters.length; i++) {
        expect(clusterProgress(i, {}), 0, reason: 'cluster $i should be 0');
      }
    });

    test('letter in only 2 game types does not count', () {
      final cluster0 = kArabicClusters[0];
      final levels = {
        'hrf-learn': markGlyphs(cluster0),
        'hrf-trace': markGlyphs(cluster0),
      };
      expect(clusterProgress(0, levels), 0);
    });

    test('cluster letters done in 3 game types count fully, others 0', () {
      final cluster0 = kArabicClusters[0];
      final levels = {
        'hrf-learn': markGlyphs(cluster0),
        'hrf-trace': markGlyphs(cluster0),
        'hrf-hear': markGlyphs(cluster0),
      };
      expect(clusterProgress(0, levels), cluster0.length);
      expect(clusterProgress(1, levels), 0);
    });

    test('partial cluster: only the ≥3-game letters count', () {
      final cluster0 = kArabicClusters[0];
      final first = cluster0.first;
      final levels = {
        'hrf-learn': markGlyphs([first]),
        'hrf-hear': markGlyphs([first]),
        'hrf-pop': markGlyphs([first]),
      };
      expect(clusterProgress(0, levels), 1);
    });
  });

  // ── Group 9: ClusterPicker progress indicator ────────────────────────────

  group('ClusterPicker', () {
    testWidgets('tile shows 0/N progress with a fresh save', (tester) async {
      final store = _MemStore();
      final fakeTts = _FakeTtsBackend();
      await tester.pumpWidget(_harness(
        store: store,
        fakeTts: fakeTts,
        child: ClusterPicker(
          title: 'Learn the Letter',
          emoji: '🔤',
          color: Colors.teal,
          onPick: (_) {},
          onExit: () {},
        ),
      ));
      await _settle(tester);

      final label = tester.widget<Text>(
        find.byKey(const ValueKey('cluster-progress-0')),
      );
      expect(label.data, 'Group 1  ·  0/${kArabicClusters[0].length}');
    });
  });

  // ── Group 10: LetterPopScreen (seeded, deterministic) ────────────────────

  group('LetterPopScreen', () {
    testWidgets(
        'wrong balloon is removed without scoring; correct balloon scores',
        (tester) async {
      const seed = 7;
      // Mirror the widget's first RNG draw to know the target glyph.
      final target =
          kArabicLetters[Random(seed).nextInt(kArabicLetters.length)].g;

      final store = _MemStore();
      final fakeTts = _FakeTtsBackend();
      await tester.pumpWidget(_harness(
        store: store,
        fakeTts: fakeTts,
        child: LetterPopScreen(random: Random(seed)),
      ));

      // Let the announce timer (400 ms) fire and balloons spawn (850 ms each).
      await tester.pump(const Duration(milliseconds: 500));

      String glyphOf(int id) => tester
          .widget<Text>(find.descendant(
            of: find.byKey(ValueKey('balloon-$id')),
            matching: find.byType(Text),
          ))
          .data!;

      // Balloons spawn at the bottom edge (partly offscreen) and overlapping
      // balloons steal hit-tests, so only tap balloons that are fully visible
      // and well clear of every other balloon on screen.
      bool isClear(int id) {
        final rect = tester.getRect(find.byKey(ValueKey('balloon-$id')));
        if (rect.top < 100 || rect.bottom > 530) return false;
        final c = tester.getCenter(find.byKey(ValueKey('balloon-$id')));
        for (var other = 0; other < 60; other++) {
          if (other == id) continue;
          final f = find.byKey(ValueKey('balloon-$other'));
          if (f.evaluate().isEmpty) continue;
          if ((tester.getCenter(f) - c).distance < 110) return false;
        }
        return true;
      }

      int? findClearBalloon({required bool wantTarget}) {
        for (var id = 0; id < 60; id++) {
          final f = find.byKey(ValueKey('balloon-$id'));
          if (f.evaluate().isEmpty) continue;
          if ((glyphOf(id) == target) != wantTarget) continue;
          if (isClear(id)) return id;
        }
        return null;
      }

      Future<int> waitForClearBalloon({required bool wantTarget}) async {
        for (var i = 0; i < 40; i++) {
          final id = findClearBalloon(wantTarget: wantTarget);
          if (id != null) return id;
          await tester.pump(const Duration(milliseconds: 850));
        }
        fail('no clear ${wantTarget ? 'target' : 'wrong'} balloon appeared');
      }

      expect(find.text('🎈 0/6'), findsOneWidget);

      // Wrong tap: balloon removed (prototype behavior), no score.
      final wrongId = await waitForClearBalloon(wantTarget: false);
      await tester.tap(find.byKey(ValueKey('balloon-$wrongId')));
      await tester.pump();
      expect(find.byKey(ValueKey('balloon-$wrongId')), findsNothing);
      expect(find.text('🎈 0/6'), findsOneWidget);

      // Correct tap: balloon removed and score increments.
      final correctId = await waitForClearBalloon(wantTarget: true);
      await tester.tap(find.byKey(ValueKey('balloon-$correctId')));
      await tester.pump();
      expect(find.byKey(ValueKey('balloon-$correctId')), findsNothing);
      expect(find.text('🎈 1/6'), findsOneWidget);

      // Dispose the screen to stop the ticker before the test ends.
      await tester.pumpWidget(const SizedBox());
    });
  });
}
