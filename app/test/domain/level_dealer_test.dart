import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/domain/level_dealer.dart';

void main() {
  group('dealGames', () {
    test('90-item pool, 10 games × 15: every game has 15 unique items, '
        'every item used ≤2× overall, all games full', () {
      final pool = List.generate(90, (i) => i);
      const games = 10;
      const perGame = 15;
      final result = dealGames(
        pool: pool,
        games: games,
        perGame: perGame,
        random: Random(42),
      );

      // Check all games full
      expect(result.length, equals(games));
      for (final game in result) {
        expect(game.length, equals(perGame));
      }

      // Check no within-game dupes
      for (final game in result) {
        expect(game.toSet().length, equals(perGame));
      }

      // Check usage distribution: each item used ≤2× overall
      final usage = <int, int>{};
      for (final game in result) {
        for (final item in game) {
          usage[item] = (usage[item] ?? 0) + 1;
        }
      }
      for (final count in usage.values) {
        expect(count, lessThanOrEqualTo(2));
      }
    });

    test('pool of 5, 1 game × 8 → repeats allowed, game length 8', () {
      final pool = [1, 2, 3, 4, 5];
      const games = 1;
      const perGame = 8;
      final result = dealGames(
        pool: pool,
        games: games,
        perGame: perGame,
        random: Random(42),
      );

      // Check game is generated with repeats
      expect(result.length, equals(games));
      expect(result[0].length, equals(perGame));

      // Check that all pool items appear at least once
      final gameSet = result[0].toSet();
      expect(gameSet.length, equals(5));
    });

    test('seeded Random(42) twice → identical deal', () {
      final pool = List.generate(20, (i) => i);
      const games = 3;
      const perGame = 5;

      final result1 = dealGames(
        pool: pool,
        games: games,
        perGame: perGame,
        random: Random(42),
      );

      final result2 = dealGames(
        pool: pool,
        games: games,
        perGame: perGame,
        random: Random(42),
      );

      expect(result1, equals(result2));
    });

    test('26-item pool, 10×15 → no within-game dupes', () {
      final pool = List.generate(26, (i) => i);
      const games = 10;
      const perGame = 15;
      final result = dealGames(
        pool: pool,
        games: games,
        perGame: perGame,
        random: Random(42),
      );

      // Check no within-game dupes
      for (final game in result) {
        expect(game.toSet().length, equals(perGame),
            reason: 'Game should have no duplicates');
      }

      // Check all games full
      for (final game in result) {
        expect(game.length, equals(perGame));
      }
    });
  });
}
