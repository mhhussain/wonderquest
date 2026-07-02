import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/domain/spot_scene_engine.dart';

void main() {
  group('SpotSceneLayout.place', () {
    const canvas = Size(800, 600);

    test('all items inside canvas bounds', () {
      final goals = [
        const SpotGoal(char: '🐝', count: 3, label: 'bees'),
      ];
      final items = SpotSceneLayout.place(
        goals: goals,
        decoys: ['🌿'],
        decoyCount: 5,
        canvas: canvas,
        random: Random(42),
      );

      expect(items, isNotEmpty);
      for (final item in items) {
        expect(
          item.pos.dx,
          greaterThanOrEqualTo(0),
          reason: 'Item ${item.id} x=${item.pos.dx} is left of canvas',
        );
        expect(
          item.pos.dy,
          greaterThanOrEqualTo(0),
          reason: 'Item ${item.id} y=${item.pos.dy} is above canvas',
        );
        expect(
          item.pos.dx,
          lessThanOrEqualTo(canvas.width),
          reason: 'Item ${item.id} x=${item.pos.dx} is right of canvas',
        );
        expect(
          item.pos.dy,
          lessThanOrEqualTo(canvas.height),
          reason: 'Item ${item.id} y=${item.pos.dy} is below canvas',
        );
      }
    });

    test('item count equals sum(goal counts) + decoyCount', () {
      final goals = [
        const SpotGoal(char: '🐝', count: 2, label: 'bees'),
        const SpotGoal(char: '🦋', count: 3, label: 'butterflies'),
      ];
      const decoyCount = 10;
      final items = SpotSceneLayout.place(
        goals: goals,
        decoys: ['🌿'],
        decoyCount: decoyCount,
        canvas: canvas,
        random: Random(42),
      );
      expect(items.length, equals(2 + 3 + decoyCount));
    });

    test('no two items closer than 0.5 × min cell size', () {
      final goals = [const SpotGoal(char: '🐝', count: 4, label: 'bees')];
      const decoyCount = 12; // total = 16
      final items = SpotSceneLayout.place(
        goals: goals,
        decoys: ['🌿'],
        decoyCount: decoyCount,
        canvas: canvas,
        random: Random(42),
      );

      final n = items.length;
      // Mirror the engine's grid formula.
      final cols = sqrt(n.toDouble()).ceil().clamp(1, n);
      final rows = (n / cols).ceil();
      final cw = canvas.width / cols;
      final ch = canvas.height / rows;
      final minCellSize = cw < ch ? cw : ch;
      // Allow a tiny floating-point tolerance.
      final minDist = 0.5 * minCellSize - 1e-9;

      for (var i = 0; i < items.length; i++) {
        for (var j = i + 1; j < items.length; j++) {
          final dx = items[i].pos.dx - items[j].pos.dx;
          final dy = items[i].pos.dy - items[j].pos.dy;
          final dist = sqrt(dx * dx + dy * dy);
          expect(
            dist,
            greaterThanOrEqualTo(minDist),
            reason:
                'Items $i and $j are too close: dist=$dist < minDist=$minDist',
          );
        }
      }
    });
  });

  group('SpotSceneState', () {
    test('tapping a target twice counts only once', () {
      final goals = [const SpotGoal(char: '🐝', count: 2, label: 'bees')];
      final state = SpotSceneState(goals, SpotMode.find);

      const item = PlacedItem(
        char: '🐝',
        pos: Offset(100, 100),
        size: 48,
        isTarget: true,
        id: 0,
      );

      expect(state.tap(item), isTrue, reason: 'First tap should register');
      expect(state.tap(item), isFalse, reason: 'Second tap should be ignored');
      expect(state.foundByChar['🐝'], equals(1));
    });

    test('complete is false until all goals are met', () {
      final goals = [
        const SpotGoal(char: '🐝', count: 2, label: 'bees'),
        const SpotGoal(char: '🦋', count: 1, label: 'butterfly'),
      ];
      final state = SpotSceneState(goals, SpotMode.find);

      const bee1 = PlacedItem(
        char: '🐝',
        pos: Offset(0, 0),
        size: 48,
        isTarget: true,
        id: 0,
      );
      const bee2 = PlacedItem(
        char: '🐝',
        pos: Offset(100, 0),
        size: 48,
        isTarget: true,
        id: 1,
      );
      const butterfly = PlacedItem(
        char: '🦋',
        pos: Offset(200, 0),
        size: 48,
        isTarget: true,
        id: 2,
      );

      state.tap(bee1);
      expect(state.complete, isFalse, reason: 'One bee found — not complete');

      state.tap(bee2);
      expect(
        state.complete,
        isFalse,
        reason: 'Both bees found but butterfly missing',
      );

      state.tap(butterfly);
      expect(state.complete, isTrue, reason: 'All goals met');
    });

    test('tapping a decoy returns false', () {
      final goals = [const SpotGoal(char: '🐝', count: 1, label: 'bee')];
      final state = SpotSceneState(goals, SpotMode.find);

      const decoy = PlacedItem(
        char: '🌿',
        pos: Offset(0, 0),
        size: 48,
        isTarget: false,
        id: 9,
      );
      expect(state.tap(decoy), isFalse);
    });

    test('foundByChar reflects count of found targets per char', () {
      final goals = [
        const SpotGoal(char: '🐝', count: 3, label: 'bees'),
      ];
      final state = SpotSceneState(goals, SpotMode.count);

      final items = List.generate(
        3,
        (i) => PlacedItem(
          char: '🐝',
          pos: Offset(i * 100.0, 0),
          size: 48,
          isTarget: true,
          id: i,
        ),
      );

      state.tap(items[0]);
      expect(state.foundByChar['🐝'], equals(1));

      state.tap(items[1]);
      expect(state.foundByChar['🐝'], equals(2));

      state.tap(items[2]);
      expect(state.foundByChar['🐝'], equals(3));
      expect(state.complete, isTrue);
    });
  });
}
