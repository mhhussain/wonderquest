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
class PoolItem {
  final String emoji;
  final String name;

  const PoolItem({required this.emoji, required this.name});
}

/// Element-wise list equality helper (no Flutter/collection import needed).
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Zoo animals for "Count the Zoo": 18 animals.
const List<PoolItem> kZooAnimals = [
  PoolItem(emoji: '🦁', name: 'lions'),
  PoolItem(emoji: '🐘', name: 'elephants'),
  PoolItem(emoji: '🦒', name: 'giraffes'),
  PoolItem(emoji: '🐵', name: 'monkeys'),
  PoolItem(emoji: '🦓', name: 'zebras'),
  PoolItem(emoji: '🐯', name: 'tigers'),
  PoolItem(emoji: '🦛', name: 'hippos'),
  PoolItem(emoji: '🐍', name: 'snakes'),
  PoolItem(emoji: '🦩', name: 'flamingos'),
  PoolItem(emoji: '🐧', name: 'penguins'),
  PoolItem(emoji: '🐢', name: 'turtles'),
  PoolItem(emoji: '🦘', name: 'kangaroos'),
  PoolItem(emoji: '🐼', name: 'pandas'),
  PoolItem(emoji: '🦜', name: 'parrots'),
  PoolItem(emoji: '🐪', name: 'camels'),
  PoolItem(emoji: '🦏', name: 'rhinos'),
  PoolItem(emoji: '🐊', name: 'crocodiles'),
  PoolItem(emoji: '🦚', name: 'peacocks'),
];

/// Gems for "Treasure Hunt": 12 gemstones.
const List<PoolItem> kGems = [
  PoolItem(emoji: '💎', name: 'diamonds'),
  PoolItem(emoji: '🔴', name: 'rubies'),
  PoolItem(emoji: '🔵', name: 'sapphires'),
  PoolItem(emoji: '🟢', name: 'emeralds'),
  PoolItem(emoji: '🟣', name: 'amethysts'),
  PoolItem(emoji: '🟡', name: 'gold stones'),
  PoolItem(emoji: '🟠', name: 'amber stones'),
  PoolItem(emoji: '⚪', name: 'pearls'),
  PoolItem(emoji: '🔶', name: 'topaz gems'),
  PoolItem(emoji: '🔷', name: 'aqua gems'),
  PoolItem(emoji: '🟤', name: 'bronze stones'),
  PoolItem(emoji: '🪙', name: 'gold coins'),
];

/// Fruits and vegetables for addition stations: 20 items.
const List<PoolItem> kFruitsVeggies = [
  PoolItem(emoji: '🍎', name: 'apples'),
  PoolItem(emoji: '🍌', name: 'bananas'),
  PoolItem(emoji: '🍓', name: 'strawberries'),
  PoolItem(emoji: '🍇', name: 'grapes'),
  PoolItem(emoji: '🍊', name: 'oranges'),
  PoolItem(emoji: '🥕', name: 'carrots'),
  PoolItem(emoji: '🌽', name: 'corn cobs'),
  PoolItem(emoji: '🥦', name: 'broccoli'),
  PoolItem(emoji: '🍉', name: 'watermelons'),
  PoolItem(emoji: '🍐', name: 'pears'),
  PoolItem(emoji: '🍑', name: 'peaches'),
  PoolItem(emoji: '🍒', name: 'cherries'),
  PoolItem(emoji: '🍅', name: 'tomatoes'),
  PoolItem(emoji: '🥔', name: 'potatoes'),
  PoolItem(emoji: '🍆', name: 'eggplants'),
  PoolItem(emoji: '🥒', name: 'cucumbers'),
  PoolItem(emoji: '🫐', name: 'blueberries'),
  PoolItem(emoji: '🥝', name: 'kiwis'),
  PoolItem(emoji: '🍍', name: 'pineapples'),
  PoolItem(emoji: '🥬', name: 'lettuce'),
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

/// A single math problem: two operands, answer, and choices.
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
          _listEquals(choices, other.choices) &&
          obj == other.obj;

  @override
  int get hashCode =>
      a.hashCode ^
      b.hashCode ^
      answer.hashCode ^
      Object.hashAll(choices) ^
      obj.hashCode;
}

/// Generate n math problems for the given station and type.
///
/// Uses injected Random for determinism.
///
/// Honors prototype ranges (raw/math.jsx):
/// - add: a+b ≤ 16, both 1–9
/// - sub: total 2–12, take 1 to total-1, result ≥ 0
/// - count: 1–12
/// - compare: a, b 1–12, a ≠ b
///
/// Pool routing (matches prototype):
/// - 'zoo' → animal from kZooAnimals, rotated without repeat per game
/// - 'gems' → gem from kGems, rotated without repeat per game
/// - 'snack' → fruit/veggie from kFruitsVeggies, rotated without repeat per game
/// - 'eggs' / 'cookie' / 'morles' → station's fixed obj (prototype uses
///   theme.obj for sub and compare stations — no pool variation)
///
/// For pool stations, the pool is shuffled and items are drawn without replacement
/// within a game window. Once exhausted, the pool is reshuffled and items drawn again
/// (allowing repeats only after every item was used once).
///
/// Choices: 4 for count/add/sub (answer + 3 near-answer distractors);
/// compare always uses exactly [0, 1] ("B has more" / "A has more").
List<MathProblem> genMathProblems(
  MathType type,
  String stationId,
  int n,
  Random r,
) {
  final problems = <MathProblem>[];

  // Pool stations vary the obj per problem; fixed stations use station.obj.
  final bool usePool =
      stationId == 'zoo' || stationId == 'gems' || stationId == 'snack';
  final List<PoolItem>? originalPool = usePool
      ? (stationId == 'zoo'
          ? kZooAnimals
          : stationId == 'gems'
              ? kGems
              : kFruitsVeggies)
      : null;
  final String fixedObj = usePool
      ? ''
      : kMathStations.firstWhere((s) => s.id == stationId).obj;

  // Initialize pool copy for non-repeating draws (for pool stations only).
  late List<PoolItem> poolCopy;
  if (usePool) {
    poolCopy = List<PoolItem>.from(originalPool!);
    _shuffleList(poolCopy, r);
  }

  while (problems.length < n) {
    late int a, b, answer;
    var lo = 0;
    var hi = 20;

    if (type == MathType.add) {
      // Addition: a + b ≤ 16, both 1–9.
      a = 1 + r.nextInt(9);
      b = 1 + r.nextInt(9);
      if (a + b > 16) continue;
      answer = a + b;
    } else if (type == MathType.sub) {
      // Subtraction: total 2–12, take 1 to total-1.
      final total = 2 + r.nextInt(11);
      final take = 1 + r.nextInt(total - 1);
      a = total;
      b = take;
      answer = total - take;
    } else if (type == MathType.count) {
      // Count: 1–12.
      a = 1 + r.nextInt(12);
      b = 0; // unused for count
      answer = a;
      lo = 1;
      hi = 12;
    } else {
      // Compare: a, b 1–12, a ≠ b.
      a = 1 + r.nextInt(12);
      b = 1 + r.nextInt(12);
      if (a == b) continue;
      answer = a > b ? 1 : 0; // 1 = "A has more", 0 = "B has more"
    }

    // Build choices.
    // Compare always uses [0, 1] (the only valid answers); skip distractor
    // loop entirely — lo=1 would make 0 unreachable as a distractor.
    // For count/add/sub: 4 choices via bounded near-answer distractors with
    // uniform-fallback after 24 attempts to prevent starvation near range edges.
    List<int> choices;
    if (type == MathType.compare) {
      choices = [0, 1];
    } else {
      final choiceSet = <int>{answer};
      var attempts = 0;
      while (choiceSet.length < 4) {
        final distractor = attempts++ < 24
            ? answer + (r.nextInt(5) - 2) // near-answer offset [-2, +2]
            : lo + r.nextInt(hi - lo + 1); // uniform fallback in [lo, hi]
        if (distractor >= lo && distractor <= hi && distractor != answer) {
          choiceSet.add(distractor);
        }
      }
      choices = choiceSet.toList()..sort();
    }

    // Pick object: pool stations draw from shuffled pool without replacement;
    // fixed stations use station obj.
    late String obj;
    if (usePool) {
      // Draw from pool; if exhausted, reshuffle and continue.
      if (poolCopy.isEmpty) {
        poolCopy = List<PoolItem>.from(originalPool!);
        _shuffleList(poolCopy, r);
      }
      obj = poolCopy.removeLast().emoji;
    } else {
      obj = fixedObj;
    }

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

/// Fisher-Yates shuffle using the provided Random instance for determinism.
void _shuffleList<T>(List<T> list, Random r) {
  for (var i = list.length - 1; i > 0; i--) {
    final j = r.nextInt(i + 1);
    final temp = list[i];
    list[i] = list[j];
    list[j] = temp;
  }
}
