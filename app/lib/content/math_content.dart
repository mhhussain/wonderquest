import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/wq_colors.dart';

/// Type of math activity: counting, addition, subtraction, or comparison.
enum MathType { count, add, sub, compare }

/// A math station: a themed environment with a specific math activity type.
///
/// Part of Little Math Lab. The 6 stations are:
/// - Count the Zoo (count animals)
/// - Dino Snack Time (add apples)
/// - Treasure Hunt (add gems)
/// - Lost Dino Eggs (subtract eggs)
/// - Cookie Math (subtract cookies)
/// - More or Less (compare groups)
class MathStation {
  final String id;
  final String title;
  final String emoji;
  final String obj;
  final String objName;
  final Color color;
  final MathType type;

  const MathStation({
    required this.id,
    required this.title,
    required this.emoji,
    required this.obj,
    required this.objName,
    required this.color,
    required this.type,
  });

  @override
  String toString() =>
      'MathStation(id: $id, title: $title, emoji: $emoji, obj: $obj, objName: $objName, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MathStation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          emoji == other.emoji &&
          obj == other.obj &&
          objName == other.objName &&
          color == other.color &&
          type == other.type;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      emoji.hashCode ^
      obj.hashCode ^
      objName.hashCode ^
      color.hashCode ^
      type.hashCode;
}

/// A single object (emoji + name) for pool selection.
class _PoolItem {
  final String emoji;
  final String name;

  const _PoolItem({required this.emoji, required this.name});
}

/// Zoo animals for "Count the Zoo": 18 animals.
const List<_PoolItem> _kZooAnimalsData = [
  _PoolItem(emoji: '🦁', name: 'lions'),
  _PoolItem(emoji: '🐘', name: 'elephants'),
  _PoolItem(emoji: '🦒', name: 'giraffes'),
  _PoolItem(emoji: '🐵', name: 'monkeys'),
  _PoolItem(emoji: '🦓', name: 'zebras'),
  _PoolItem(emoji: '🐯', name: 'tigers'),
  _PoolItem(emoji: '🦛', name: 'hippos'),
  _PoolItem(emoji: '🐍', name: 'snakes'),
  _PoolItem(emoji: '🦩', name: 'flamingos'),
  _PoolItem(emoji: '🐧', name: 'penguins'),
  _PoolItem(emoji: '🐢', name: 'turtles'),
  _PoolItem(emoji: '🦘', name: 'kangaroos'),
  _PoolItem(emoji: '🐼', name: 'pandas'),
  _PoolItem(emoji: '🦜', name: 'parrots'),
  _PoolItem(emoji: '🐪', name: 'camels'),
  _PoolItem(emoji: '🦏', name: 'rhinos'),
  _PoolItem(emoji: '🐊', name: 'crocodiles'),
  _PoolItem(emoji: '🦚', name: 'peacocks'),
];

/// Gems for "Treasure Hunt": 12 gemstones.
const List<_PoolItem> _kGemsData = [
  _PoolItem(emoji: '💎', name: 'diamonds'),
  _PoolItem(emoji: '🔴', name: 'rubies'),
  _PoolItem(emoji: '🔵', name: 'sapphires'),
  _PoolItem(emoji: '🟢', name: 'emeralds'),
  _PoolItem(emoji: '🟣', name: 'amethysts'),
  _PoolItem(emoji: '🟡', name: 'gold stones'),
  _PoolItem(emoji: '🟠', name: 'amber stones'),
  _PoolItem(emoji: '⚪', name: 'pearls'),
  _PoolItem(emoji: '🔶', name: 'topaz gems'),
  _PoolItem(emoji: '🔷', name: 'aqua gems'),
  _PoolItem(emoji: '🟤', name: 'bronze stones'),
  _PoolItem(emoji: '🪙', name: 'gold coins'),
];

/// Fruits and vegetables for addition stations: 20 items.
const List<_PoolItem> _kFruitsVeggiesData = [
  _PoolItem(emoji: '🍎', name: 'apples'),
  _PoolItem(emoji: '🍌', name: 'bananas'),
  _PoolItem(emoji: '🍓', name: 'strawberries'),
  _PoolItem(emoji: '🍇', name: 'grapes'),
  _PoolItem(emoji: '🍊', name: 'oranges'),
  _PoolItem(emoji: '🥕', name: 'carrots'),
  _PoolItem(emoji: '🌽', name: 'corn cobs'),
  _PoolItem(emoji: '🥦', name: 'broccoli'),
  _PoolItem(emoji: '🍉', name: 'watermelons'),
  _PoolItem(emoji: '🍐', name: 'pears'),
  _PoolItem(emoji: '🍑', name: 'peaches'),
  _PoolItem(emoji: '🍒', name: 'cherries'),
  _PoolItem(emoji: '🍅', name: 'tomatoes'),
  _PoolItem(emoji: '🥔', name: 'potatoes'),
  _PoolItem(emoji: '🍆', name: 'eggplants'),
  _PoolItem(emoji: '🥒', name: 'cucumbers'),
  _PoolItem(emoji: '🫐', name: 'blueberries'),
  _PoolItem(emoji: '🥝', name: 'kiwis'),
  _PoolItem(emoji: '🍍', name: 'pineapples'),
  _PoolItem(emoji: '🥬', name: 'lettuce'),
];

/// The 6 math stations in the Little Math Lab (order: as in raw/math.jsx).
const List<MathStation> kMathStations = [
  MathStation(
    id: 'snack',
    title: 'Dino Snack Time',
    emoji: '🦖',
    obj: '🍎',
    objName: 'apples',
    color: WqColors.green,
    type: MathType.add,
  ),
  MathStation(
    id: 'zoo',
    title: 'Count the Zoo',
    emoji: '🦁',
    obj: '🦁',
    objName: 'animals',
    color: WqColors.orange,
    type: MathType.count,
  ),
  MathStation(
    id: 'gems',
    title: 'Treasure Hunt',
    emoji: '💎',
    obj: '💎',
    objName: 'gems',
    color: WqColors.teal,
    type: MathType.add,
  ),
  MathStation(
    id: 'eggs',
    title: 'Lost Dino Eggs',
    emoji: '🥚',
    obj: '🥚',
    objName: 'eggs',
    color: WqColors.coral,
    type: MathType.sub,
  ),
  MathStation(
    id: 'cookie',
    title: 'Cookie Math',
    emoji: '🍪',
    obj: '🍪',
    objName: 'cookies',
    color: WqColors.yellow,
    type: MathType.sub,
  ),
  MathStation(
    id: 'morles',
    title: 'More or Less',
    emoji: '⚖️',
    obj: '🦕',
    objName: 'dinos',
    color: WqColors.grape,
    type: MathType.compare,
  ),
];

/// A single math problem: two operands, answer, and 4 choices.
class MathProblem {
  final int a;
  final int b;
  final int answer;
  final List<int> choices;
  final String obj;

  const MathProblem({
    required this.a,
    required this.b,
    required this.answer,
    required this.choices,
    required this.obj,
  });

  @override
  String toString() =>
      'MathProblem(a: $a, b: $b, answer: $answer, choices: $choices, obj: $obj)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MathProblem &&
          runtimeType == other.runtimeType &&
          a == other.a &&
          b == other.b &&
          answer == other.answer &&
          choices == other.choices &&
          obj == other.obj;

  @override
  int get hashCode =>
      a.hashCode ^
      b.hashCode ^
      answer.hashCode ^
      choices.hashCode ^
      obj.hashCode;
}

/// Generate n math problems for the given station and type.
///
/// Uses injected Random for determinism.
///
/// Honors prototype ranges:
/// - add: a+b ≤ 16, both 1–9
/// - sub: total 2–12, take 1 to total-1, result ≥ 0
/// - count: 1–12
/// - compare: a, b 1–12, a ≠ b
///
/// Each problem includes 4 choices (answer + 3 distractors within range).
List<MathProblem> genMathProblems(
  MathType type,
  String stationId,
  int n,
  Random r,
) {
  final problems = <MathProblem>[];

  // Select object pool based on station ID.
  final pool = stationId == 'zoo'
      ? _kZooAnimalsData
      : stationId == 'gems'
          ? _kGemsData
          : _kFruitsVeggiesData;

  while (problems.length < n) {
    late int a, b, answer, lo, hi;

    if (type == MathType.add) {
      // Addition: a + b ≤ 16, both 1–9.
      a = 1 + r.nextInt(9);
      b = 1 + r.nextInt(9);
      if (a + b > 16) continue;
      answer = a + b;
      lo = 0;
      hi = 20;
    } else if (type == MathType.sub) {
      // Subtraction: total 2–12, take 1 to total-1.
      final total = 2 + r.nextInt(11);
      final take = 1 + r.nextInt(total - 1);
      a = total;
      b = take;
      answer = total - take;
      lo = 0;
      hi = 20;
    } else if (type == MathType.count) {
      // Count: 1–12.
      a = 1 + r.nextInt(12);
      b = 0; // unused for count
      answer = a;
      lo = 1;
      hi = 12;
    } else if (type == MathType.compare) {
      // Compare: a, b 1–12, a ≠ b.
      a = 1 + r.nextInt(12);
      b = 1 + r.nextInt(12);
      if (a == b) continue;
      answer = a > b ? 1 : 0; // 1 for "a is more", 0 for "b is more"
      lo = 1;
      hi = 12;
    }

    // Build 4 choices for count/add/sub, or 2 for compare.
    final choiceCount = type == MathType.compare ? 2 : 4;
    final choiceSet = <int>{answer};
    // Prefer near-answer distractors (offset [-2, +2]); after a bounded
    // number of attempts fall back to uniform draws in [lo, hi] — near the
    // range edges (e.g. count answer 1 or 12) fewer than 3 near-offsets
    // exist and the near-only loop would never terminate.
    var attempts = 0;
    while (choiceSet.length < choiceCount) {
      final distractor = attempts++ < 24
          ? answer + (r.nextInt(5) - 2) // offset [-2, +2]
          : lo + r.nextInt(hi - lo + 1);
      if (distractor >= lo && distractor <= hi && distractor != answer) {
        choiceSet.add(distractor);
      }
    }
    final choices = choiceSet.toList()..sort();

    // Pick a random object from the pool.
    final obj = pool[r.nextInt(pool.length)].emoji;

    problems.add(MathProblem(
      a: a,
      b: b,
      answer: answer,
      choices: choices,
      obj: obj,
    ));
  }

  return problems;
}
