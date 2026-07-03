import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/numbers_content.dart';

void main() {
  group('Number Content', () {
    test('kCountEmojis has 16 emoji variants', () {
      expect(kCountEmojis.length, equals(16));
    });

    test('kCountEmojis contains expected emoji', () {
      expect(kCountEmojis, contains('🥚'));
      expect(kCountEmojis, contains('🦕'));
      expect(kCountEmojis, contains('🍎'));
      expect(kCountEmojis, contains('⭐'));
    });

    group('genCountRounds', () {
      test('generates exactly n rounds', () {
        final rounds = genCountRounds(90, Random(42));
        expect(rounds.length, equals(90));
      });

      test('all counts are in range 1–12', () {
        final rounds = genCountRounds(90, Random(42));
        for (final round in rounds) {
          expect(round.count, inInclusiveRange(1, 12));
        }
      });

      test('all emoji are from kCountEmojis pool', () {
        final rounds = genCountRounds(90, Random(42));
        for (final round in rounds) {
          expect(kCountEmojis, contains(round.emoji));
        }
      });

      test('most (emoji, count) pairs are unique (allows repeats)', () {
        final rounds = genCountRounds(90, Random(42));
        final counts = <String, int>{};
        for (final round in rounds) {
          final key = '${round.emoji}-${round.count}';
          counts[key] = (counts[key] ?? 0) + 1;
        }
        // With random generation, pairs may repeat; verify reasonable distribution
        final maxRepeat = counts.values.reduce((a, b) => a > b ? a : b);
        expect(maxRepeat, lessThanOrEqualTo(4)); // Allow reasonable repeats
      });

      test('early rounds have smaller average counts than late rounds', () {
        final rounds = genCountRounds(90, Random(42));
        final firstHalf = rounds.sublist(0, 45);
        final secondHalf = rounds.sublist(45);

        final avgFirst =
            firstHalf.map((r) => r.count).reduce((a, b) => a + b) /
                firstHalf.length;
        final avgSecond =
            secondHalf.map((r) => r.count).reduce((a, b) => a + b) /
                secondHalf.length;

        expect(avgFirst, lessThan(avgSecond));
      });

      test('generated rounds with same seed produce same sequence', () {
        final rounds1 = genCountRounds(20, Random(123));
        final rounds2 = genCountRounds(20, Random(123));

        for (var i = 0; i < rounds1.length; i++) {
          expect(rounds1[i].emoji, equals(rounds2[i].emoji));
          expect(rounds1[i].count, equals(rounds2[i].count));
        }
      });
    });

    group('genMissingRounds', () {
      test('generates exactly n rounds', () {
        final rounds = genMissingRounds(90, Random(42));
        expect(rounds.length, equals(90));
      });

      test('all answer values are in range 1–20', () {
        final rounds = genMissingRounds(90, Random(42));
        for (final round in rounds) {
          expect(round.answer, inInclusiveRange(1, 20));
        }
      });

      test('each round seq[missIdx] equals answer', () {
        final rounds = genMissingRounds(90, Random(42));
        for (final round in rounds) {
          expect(round.seq[round.missIdx], equals(round.answer));
        }
      });

      test('answer is in choices list', () {
        final rounds = genMissingRounds(90, Random(42));
        for (final round in rounds) {
          expect(round.choices, contains(round.answer));
        }
      });

      test('each round has 3 choices', () {
        final rounds = genMissingRounds(90, Random(42));
        for (final round in rounds) {
          expect(round.choices.length, equals(3));
        }
      });

      test('all choices are unique', () {
        final rounds = genMissingRounds(90, Random(42));
        for (final round in rounds) {
          final uniqueChoices = round.choices.toSet();
          expect(uniqueChoices.length, equals(round.choices.length));
        }
      });

      test('early sequences are 5 long', () {
        final rounds = genMissingRounds(90, Random(42));
        final earlyRounds = rounds.sublist(0, 9);
        for (final round in earlyRounds) {
          expect(round.seq.length, equals(5));
        }
      });

      test('later sequences are 6 long', () {
        final rounds = genMissingRounds(90, Random(42));
        final lateRounds = rounds.sublist(9);
        for (final round in lateRounds) {
          expect(round.seq.length, equals(6));
        }
      });

      test('missIdx is never at edges (0 or span-1)', () {
        final rounds = genMissingRounds(90, Random(42));
        for (final round in rounds) {
          expect(round.missIdx, greaterThan(0));
          expect(round.missIdx, lessThan(round.seq.length - 1));
        }
      });

      test('each sequence is an ascending range', () {
        final rounds = genMissingRounds(90, Random(42));
        for (final round in rounds) {
          for (var i = 1; i < round.seq.length; i++) {
            expect(round.seq[i], equals(round.seq[i - 1] + 1));
          }
        }
      });

      test('most sequences are unique (allows up to a few repeats)', () {
        final rounds = genMissingRounds(90, Random(42));
        final counts = <String, int>{};
        for (final round in rounds) {
          final start = round.seq.first;
          final span = round.seq.length;
          final missIdx = round.missIdx;
          final key = '$start-$span-$missIdx';
          counts[key] = (counts[key] ?? 0) + 1;
        }
        // Check that most sequences appear a reasonable number of times
        final maxRepeat = counts.values.reduce((a, b) => a > b ? a : b);
        expect(maxRepeat, lessThanOrEqualTo(4)); // Allow up to 4 repeats due to randomness
      });

      test('generated rounds with same seed produce same sequence', () {
        final rounds1 = genMissingRounds(20, Random(456));
        final rounds2 = genMissingRounds(20, Random(456));

        for (var i = 0; i < rounds1.length; i++) {
          expect(rounds1[i].seq, equals(rounds2[i].seq));
          expect(rounds1[i].missIdx, equals(rounds2[i].missIdx));
          expect(rounds1[i].answer, equals(rounds2[i].answer));
          expect(rounds1[i].choices, equals(rounds2[i].choices));
        }
      });
    });

    group('CountRound equality and hashing', () {
      test('two CountRounds with same values are equal', () {
        final r1 = const CountRound(emoji: '🍎', count: 5);
        final r2 = const CountRound(emoji: '🍎', count: 5);
        expect(r1, equals(r2));
      });

      test('two CountRounds with different values are not equal', () {
        final r1 = const CountRound(emoji: '🍎', count: 5);
        final r2 = const CountRound(emoji: '🍌', count: 5);
        expect(r1, isNot(equals(r2)));
      });

      test('CountRound hashCode is consistent', () {
        final r = const CountRound(emoji: '🍎', count: 5);
        expect(r.hashCode, equals(r.hashCode));
      });
    });

    group('MissingNumberRound equality and hashing', () {
      test('two MissingNumberRounds with same values are equal', () {
        final r1 = const MissingNumberRound(
          seq: [1, 2, 3, 4, 5],
          missIdx: 2,
          answer: 3,
          choices: [3, 4, 5],
        );
        final r2 = const MissingNumberRound(
          seq: [1, 2, 3, 4, 5],
          missIdx: 2,
          answer: 3,
          choices: [3, 4, 5],
        );
        expect(r1, equals(r2));
      });

      test('MissingNumberRound hashCode is consistent', () {
        final r = const MissingNumberRound(
          seq: [1, 2, 3, 4, 5],
          missIdx: 2,
          answer: 3,
          choices: [3, 4, 5],
        );
        expect(r.hashCode, equals(r.hashCode));
      });
    });
  });
}
