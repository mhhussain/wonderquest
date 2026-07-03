import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/math_content.dart';
import 'package:wonder_quest/theme/wq_colors.dart';

void main() {
  group('Math Content', () {
    test('kMathStations has 6 stations', () {
      expect(kMathStations.length, equals(6));
    });

    test('all station ids are unique', () {
      final ids = kMathStations.map((s) => s.id).toSet();
      expect(ids.length, equals(kMathStations.length));
    });

    test('all station titles are non-empty', () {
      for (final station in kMathStations) {
        expect(station.title.isNotEmpty, isTrue);
      }
    });

    test('all station colors are defined', () {
      expect(kMathStations[0].color, equals(WqColors.green)); // snack
      expect(kMathStations[1].color, equals(WqColors.orange)); // zoo
      expect(kMathStations[2].color, equals(WqColors.teal)); // gems
      expect(kMathStations[3].color, equals(WqColors.coral)); // eggs
      expect(kMathStations[4].color, equals(WqColors.yellow)); // cookie
      expect(kMathStations[5].color, equals(WqColors.grape)); // morles
    });

    test('station order matches expected ids', () {
      final ids = kMathStations.map((s) => s.id).toList();
      expect(
        ids,
        equals(['snack', 'zoo', 'gems', 'eggs', 'cookie', 'morles']),
      );
    });

    test('Count the Zoo station is configured correctly', () {
      final zoo = kMathStations.firstWhere((s) => s.id == 'zoo');
      expect(zoo.title, equals('Count the Zoo'));
      expect(zoo.emoji, equals('🦁'));
      expect(zoo.type, equals(MathType.count));
    });

    test('Dino Snack Time station is configured correctly', () {
      final snack = kMathStations.firstWhere((s) => s.id == 'snack');
      expect(snack.title, equals('Dino Snack Time'));
      expect(snack.type, equals(MathType.add));
    });

    test('Treasure Hunt station is configured correctly', () {
      final gems = kMathStations.firstWhere((s) => s.id == 'gems');
      expect(gems.title, equals('Treasure Hunt'));
      expect(gems.type, equals(MathType.add));
    });

    test('Lost Dino Eggs station is configured correctly', () {
      final eggs = kMathStations.firstWhere((s) => s.id == 'eggs');
      expect(eggs.title, equals('Lost Dino Eggs'));
      expect(eggs.type, equals(MathType.sub));
    });

    test('Cookie Math station is configured correctly', () {
      final cookie = kMathStations.firstWhere((s) => s.id == 'cookie');
      expect(cookie.title, equals('Cookie Math'));
      expect(cookie.type, equals(MathType.sub));
    });

    test('More or Less station is configured correctly', () {
      final morles = kMathStations.firstWhere((s) => s.id == 'morles');
      expect(morles.title, equals('More or Less'));
      expect(morles.type, equals(MathType.compare));
    });

    group('genMathProblems - Addition', () {
      test('generates exactly n problems', () {
        final problems =
            genMathProblems(MathType.add, 'snack', 50, Random(42));
        expect(problems.length, equals(50));
      });

      test('all additions satisfy a + b <= 16', () {
        final problems =
            genMathProblems(MathType.add, 'snack', 100, Random(42));
        for (final p in problems) {
          expect(p.a + p.b, lessThanOrEqualTo(16));
        }
      });

      test('all additions have a >= 1 and b >= 1', () {
        final problems =
            genMathProblems(MathType.add, 'snack', 100, Random(42));
        for (final p in problems) {
          expect(p.a, greaterThanOrEqualTo(1));
          expect(p.b, greaterThanOrEqualTo(1));
        }
      });

      test('answer equals a + b', () {
        final problems =
            genMathProblems(MathType.add, 'snack', 100, Random(42));
        for (final p in problems) {
          expect(p.answer, equals(p.a + p.b));
        }
      });

      test('answer is in choices list', () {
        final problems =
            genMathProblems(MathType.add, 'snack', 100, Random(42));
        for (final p in problems) {
          expect(p.choices, contains(p.answer));
        }
      });

      test('all choices are unique', () {
        final problems =
            genMathProblems(MathType.add, 'snack', 100, Random(42));
        for (final p in problems) {
          final uniqueChoices = p.choices.toSet();
          expect(uniqueChoices.length, equals(p.choices.length));
        }
      });

      test('each problem has 4 choices', () {
        final problems =
            genMathProblems(MathType.add, 'snack', 100, Random(42));
        for (final p in problems) {
          expect(p.choices.length, equals(4));
        }
      });

      test('200 seeded add problems all valid', () {
        final problems =
            genMathProblems(MathType.add, 'snack', 200, Random(999));
        for (final p in problems) {
          expect(p.a + p.b, lessThanOrEqualTo(16));
          expect(p.answer, equals(p.a + p.b));
          expect(p.choices, contains(p.answer));
          expect(p.choices.length, equals(4));
        }
      });
    });

    group('genMathProblems - Subtraction', () {
      test('generates exactly n problems', () {
        final problems =
            genMathProblems(MathType.sub, 'eggs', 50, Random(42));
        expect(problems.length, equals(50));
      });

      test('all subtractions have total >= 2 and <= 12', () {
        final problems =
            genMathProblems(MathType.sub, 'eggs', 100, Random(42));
        for (final p in problems) {
          expect(p.a, inInclusiveRange(2, 12));
        }
      });

      test('all subtractions have take < total', () {
        final problems =
            genMathProblems(MathType.sub, 'eggs', 100, Random(42));
        for (final p in problems) {
          expect(p.b, lessThan(p.a));
        }
      });

      test('answer equals total - take', () {
        final problems =
            genMathProblems(MathType.sub, 'eggs', 100, Random(42));
        for (final p in problems) {
          expect(p.answer, equals(p.a - p.b));
        }
      });

      test('answer >= 1', () {
        final problems =
            genMathProblems(MathType.sub, 'eggs', 100, Random(42));
        for (final p in problems) {
          expect(p.answer, greaterThanOrEqualTo(1));
        }
      });

      test('answer is in choices', () {
        final problems =
            genMathProblems(MathType.sub, 'eggs', 100, Random(42));
        for (final p in problems) {
          expect(p.choices, contains(p.answer));
        }
      });

      test('each problem has 4 choices', () {
        final problems =
            genMathProblems(MathType.sub, 'eggs', 100, Random(42));
        for (final p in problems) {
          expect(p.choices.length, equals(4));
        }
      });
    });

    group('genMathProblems - Counting', () {
      test('generates exactly n problems', () {
        final problems =
            genMathProblems(MathType.count, 'zoo', 50, Random(42));
        expect(problems.length, equals(50));
      });

      test('all counts are in range 1–12', () {
        final problems =
            genMathProblems(MathType.count, 'zoo', 100, Random(42));
        for (final p in problems) {
          expect(p.a, inInclusiveRange(1, 12));
        }
      });

      test('answer equals count (a)', () {
        final problems =
            genMathProblems(MathType.count, 'zoo', 100, Random(42));
        for (final p in problems) {
          expect(p.answer, equals(p.a));
        }
      });

      test('answer is in choices', () {
        final problems =
            genMathProblems(MathType.count, 'zoo', 100, Random(42));
        for (final p in problems) {
          expect(p.choices, contains(p.answer));
        }
      });

      test('each problem has 4 choices', () {
        final problems =
            genMathProblems(MathType.count, 'zoo', 100, Random(42));
        for (final p in problems) {
          expect(p.choices.length, equals(4));
        }
      });
    });

    group('genMathProblems - Comparison', () {
      test('generates exactly n problems', () {
        final problems =
            genMathProblems(MathType.compare, 'morles', 50, Random(42));
        expect(problems.length, equals(50));
      });

      test('all a and b values are in range 1–12', () {
        final problems =
            genMathProblems(MathType.compare, 'morles', 100, Random(42));
        for (final p in problems) {
          expect(p.a, inInclusiveRange(1, 12));
          expect(p.b, inInclusiveRange(1, 12));
        }
      });

      test('a never equals b', () {
        final problems =
            genMathProblems(MathType.compare, 'morles', 100, Random(42));
        for (final p in problems) {
          expect(p.a, isNot(equals(p.b)));
        }
      });

      test('answer is 1 when a > b, 0 when a < b', () {
        final problems =
            genMathProblems(MathType.compare, 'morles', 100, Random(42));
        for (final p in problems) {
          if (p.a > p.b) {
            expect(p.answer, equals(1));
          } else {
            expect(p.answer, equals(0));
          }
        }
      });

      test('each problem has 2 choices (compare)', () {
        final problems =
            genMathProblems(MathType.compare, 'morles', 50, Random(42));
        for (final p in problems) {
          expect(p.choices.length, equals(2));
        }
      });

      test('compare choices are always exactly [0, 1]', () {
        final problems =
            genMathProblems(MathType.compare, 'morles', 100, Random(42));
        for (final p in problems) {
          expect(p.choices, equals([0, 1]));
        }
      });
    });

    group('Public object pool constants', () {
      test('kZooAnimals has 18 entries', () {
        expect(kZooAnimals.length, equals(18));
      });

      test('kGems has 12 entries', () {
        expect(kGems.length, equals(12));
      });

      test('kFruitsVeggies has 20 entries', () {
        expect(kFruitsVeggies.length, equals(20));
      });
    });

    group('Math station with object pools', () {
      test('zoo station generates problems with zoo animal emoji', () {
        final problems =
            genMathProblems(MathType.count, 'zoo', 50, Random(42));
        final zooEmoji = {
          '🦁', '🐘', '🦒', '🐵', '🦓', '🐯', '🦛', '🐍', '🦩', '🐧',
          '🐢', '🦘', '🐼', '🦜', '🐪', '🦏', '🐊', '🦚'
        };
        for (final p in problems) {
          expect(zooEmoji, contains(p.obj));
        }
      });

      test('gems station generates problems with gem emoji', () {
        final problems =
            genMathProblems(MathType.add, 'gems', 50, Random(42));
        final gemEmoji = {
          '💎', '🔴', '🔵', '🟢', '🟣', '🟡', '🟠', '⚪', '🔶', '🔷',
          '🟤', '🪙'
        };
        for (final p in problems) {
          expect(gemEmoji, contains(p.obj));
        }
      });

      test('snack station generates problems with fruits/veggies emoji', () {
        final problems =
            genMathProblems(MathType.add, 'snack', 50, Random(42));
        final foodEmoji = {
          '🍎', '🍌', '🍓', '🍇', '🍊', '🥕', '🌽', '🥦', '🍉', '🍐',
          '🍑', '🍒', '🍅', '🥔', '🍆', '🥒', '🫐', '🥝', '🍍', '🥬'
        };
        for (final p in problems) {
          expect(foodEmoji, contains(p.obj));
        }
      });

      // Fixed-obj stations: sub and compare always use their station's obj.
      test('eggs station problems all have obj 🥚', () {
        final problems =
            genMathProblems(MathType.sub, 'eggs', 50, Random(42));
        for (final p in problems) {
          expect(p.obj, equals('🥚'));
        }
      });

      test('cookie station problems all have obj 🍪', () {
        final problems =
            genMathProblems(MathType.sub, 'cookie', 50, Random(42));
        for (final p in problems) {
          expect(p.obj, equals('🍪'));
        }
      });
    });

    group('MathProblem equality and hashing', () {
      test('two MathProblems with same values are equal', () {
        const p1 = MathProblem(
          a: 2,
          b: 3,
          answer: 5,
          choices: [4, 5, 6, 7],
          obj: '🍎',
        );
        const p2 = MathProblem(
          a: 2,
          b: 3,
          answer: 5,
          choices: [4, 5, 6, 7],
          obj: '🍎',
        );
        expect(p1, equals(p2));
      });

      test('MathProblem equality works with runtime-built (non-const) lists', () {
        // Non-const lists are distinct objects; referential == would fail here.
        final c1 = [4, 5, 6, 7];
        final c2 = [4, 5, 6, 7];
        final p1 = MathProblem(a: 2, b: 3, answer: 5, choices: c1, obj: '🍎');
        final p2 = MathProblem(a: 2, b: 3, answer: 5, choices: c2, obj: '🍎');
        expect(p1, equals(p2));
        expect(p1.hashCode, equals(p2.hashCode));
      });

      test('MathProblem hashCode is consistent', () {
        const p = MathProblem(
          a: 2,
          b: 3,
          answer: 5,
          choices: [4, 5, 6, 7],
          obj: '🍎',
        );
        expect(p.hashCode, equals(p.hashCode));
      });
    });

    group('Deterministic generation', () {
      test('add problems with same seed produce same sequence', () {
        final problems1 =
            genMathProblems(MathType.add, 'snack', 20, Random(777));
        final problems2 =
            genMathProblems(MathType.add, 'snack', 20, Random(777));

        for (var i = 0; i < problems1.length; i++) {
          expect(problems1[i].a, equals(problems2[i].a));
          expect(problems1[i].b, equals(problems2[i].b));
          expect(problems1[i].answer, equals(problems2[i].answer));
          expect(problems1[i].choices, equals(problems2[i].choices));
        }
      });

      test('sub problems with same seed produce same sequence', () {
        final problems1 =
            genMathProblems(MathType.sub, 'eggs', 20, Random(555));
        final problems2 =
            genMathProblems(MathType.sub, 'eggs', 20, Random(555));

        for (var i = 0; i < problems1.length; i++) {
          expect(problems1[i].a, equals(problems2[i].a));
          expect(problems1[i].b, equals(problems2[i].b));
          expect(problems1[i].answer, equals(problems2[i].answer));
        }
      });
    });
  });
}
