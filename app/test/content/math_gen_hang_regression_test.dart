import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/math_content.dart';

void main() {
  group('genMathProblems termination', () {
    // Regression: count answers at the range edges (1, 12) have fewer than 3
    // near-answer distractors in [1, 12]; the generator previously spun
    // forever trying to fill 4 choices from offsets [-2, +2] alone.
    test('all types terminate across 200 seeds and produce valid choices', () {
      for (final type in MathType.values) {
        for (var seed = 0; seed < 200; seed++) {
          final problems = genMathProblems(type, 'eggs', 15, Random(seed));
          expect(problems.length, 15);
          for (final p in problems) {
            expect(p.choices, contains(p.answer));
            expect(p.choices.toSet().length, p.choices.length);
          }
        }
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
