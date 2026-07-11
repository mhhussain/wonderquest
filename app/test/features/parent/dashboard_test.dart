import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/arabic_letters.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';
import 'package:wonder_quest/features/parent/dashboard_screen.dart';
import 'package:wonder_quest/theme/wq_colors.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MemStore extends SaveFileStore {
  _MemStore(this._seeded) : super(Directory.systemTemp);

  SaveData _seeded;

  @override
  Future<SaveData> load() => Future.value(_seeded);

  @override
  Future<void> save(SaveData data) async => _seeded = data;
}

/// Today as 'yyyy-MM-dd' so [applyDailyRollover] leaves the seed untouched.
String _today() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

SaveData _seededSave() => SaveData.initial(profileId: 'test').copyWith(
      lastPlayedDate: _today(),
      lettersMastered: ['A', 'B', 'C', 'D', 'E'],
      lettersLearning: ['F', 'G'],
      numbersMastered: ['1', '2', '3'],
      minutesToday: 12,
      streak: 3,
      week: [5, 10, 0, 0, 0, 0, 0],
      progress: {
        'letter': 19,
        'arabic': 50,
        'number': 15,
        'math': 0,
        'animal': 0,
        'world': 0,
        'find': 0,
      },
    );

Widget _harness(SaveData seed) {
  return ProviderScope(
    overrides: [
      saveStoreProvider.overrideWithValue(_MemStore(seed)),
    ],
    child: const MaterialApp(home: DashboardScreen()),
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
  group('pure helpers', () {
    test('readinessPercent is the mean of all 7 progress keys', () {
      expect(readinessPercent(_seededSave().progress), (84 / 7).round());
      expect(readinessPercent({'letter': 100}), (100 / 7).round());
      expect(
        readinessPercent({
          'letter': 100,
          'arabic': 100,
          'number': 100,
          'math': 100,
          'animal': 100,
          'world': 100,
          'find': 100,
        }),
        100,
      );
    });

    test('arabicMasteredCount maps percent to letter count', () {
      expect(arabicMasteredCount(0), 0);
      expect(arabicMasteredCount(50), 14);
      expect(arabicMasteredCount(100), kArabicLetters.length);
    });

    test('skillPercent averages multi-key bars (Animals & World)', () {
      final progress = {'animal': 40, 'world': 60};
      expect(skillPercent(['animal', 'world'], progress), 50);
      expect(skillPercent(['animal'], progress), 40);
    });

    test('coachNotes: lowest 2 practice ideas + confusable flag + win', () {
      final notes = coachNotes(
        progress: _seededSave().progress,
        lettersLearning: ['B', 'D'],
      );
      // Lowest two of the 6 bars (math 0, Animals & World 0, find 0 → first
      // two in rank order) produce practice ideas.
      expect(notes.where((n) => n.startsWith('⚠️ Practice idea')).length, 2);
      // B and D both learning → mixed-up flag.
      expect(notes.any((n) => n.contains('b / d')), isTrue);
      // Arabic (50) is the top skill → win line.
      expect(notes.any((n) => n.startsWith('✅') && n.contains('Arabic')),
          isTrue);
    });

    test('coachNotes: no confusable flag when only one of the pair learning',
        () {
      final notes = coachNotes(
        progress: _seededSave().progress,
        lettersLearning: ['B'],
      );
      expect(notes.any((n) => n.contains('b / d')), isFalse);
    });
  });

  group('DashboardScreen', () {
    testWidgets('shows seeded stats: 5/26 letters, arabic grid, readiness %',
        (tester) async {
      tester.view.physicalSize = const Size(1194, 834);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness(_seededSave()));
      await _settle(tester);

      // 1. Top stats row.
      expect(find.text('5/26'), findsOneWidget);
      expect(find.text('3/20'), findsOneWidget);
      expect(find.text('12 min'), findsOneWidget);
      expect(find.text('3 days'), findsOneWidget);

      // 2. Alphabet grid: exactly 5 green (mastered) tiles.
      var green = 0;
      for (final l in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
        final tile = tester.widget<Container>(
          find.descendant(
            of: find.byKey(ValueKey('alpha-$l')),
            matching: find.byType(Container),
          ),
        );
        final color = (tile.decoration! as BoxDecoration).color;
        if (color == WqColors.green) green++;
      }
      expect(green, 5, reason: '5 mastered letters → 5 green tiles');

      // 3. Arabic section present with 14/28 mastered (arabic=50).
      expect(find.text('Arabic letters — 14/${kArabicLetters.length}'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('arabic-0')), findsOneWidget);

      // 4. Week chart present with total.
      await tester.scrollUntilVisible(find.byKey(const Key('week-bars')), 200);
      expect(find.text('This week — 15 min total'), findsOneWidget);

      // 7. Readiness ring shows the computed mean.
      final expected = readinessPercent(_seededSave().progress);
      await tester.scrollUntilVisible(
          find.byKey(const Key('readiness-ring')), 200);
      expect(find.text('$expected%'), findsOneWidget);
    });

    testWidgets('readiness label reads GSRP Ready at ≥80', (tester) async {
      tester.view.physicalSize = const Size(1194, 834);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final ready = _seededSave().copyWith(progress: {
        'letter': 90,
        'arabic': 80,
        'number': 85,
        'math': 80,
        'animal': 80,
        'world': 80,
        'find': 80,
      });
      await tester.pumpWidget(_harness(ready));
      await _settle(tester);

      await tester.scrollUntilVisible(
          find.byKey(const Key('readiness-label')), 200);
      expect(find.text('GSRP Ready'), findsOneWidget);
    });

    testWidgets('settings action opens SettingsScreen', (tester) async {
      tester.view.physicalSize = const Size(1194, 834);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness(_seededSave()));
      await _settle(tester);

      await tester.tap(find.byKey(const Key('dashboard-settings')));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
