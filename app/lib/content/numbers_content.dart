import 'dart:math';

/// A single counting round: an emoji and a count.
///
/// Part of Number Kingdom's Count & Match activity.
class CountRound {
  final String emoji;
  final int count;

  const CountRound({
    required this.emoji,
    required this.count,
  });

  @override
  String toString() => 'CountRound(emoji: $emoji, count: $count)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountRound &&
          runtimeType == other.runtimeType &&
          emoji == other.emoji &&
          count == other.count;

  @override
  int get hashCode => emoji.hashCode ^ count.hashCode;
}

/// A single missing number round: a sequence with one missing element.
///
/// Part of Number Kingdom's Missing Number activity.
class MissingNumberRound {
  final List<int> seq;
  final int missIdx;
  final int answer;
  final List<int> choices;

  const MissingNumberRound({
    required this.seq,
    required this.missIdx,
    required this.answer,
    required this.choices,
  });

  @override
  String toString() =>
      'MissingNumberRound(seq: $seq, missIdx: $missIdx, answer: $answer, choices: $choices)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MissingNumberRound) return false;
    if (runtimeType != other.runtimeType) return false;
    if (seq.length != other.seq.length) return false;
    for (var i = 0; i < seq.length; i++) {
      if (seq[i] != other.seq[i]) return false;
    }
    if (choices.length != other.choices.length) return false;
    for (var i = 0; i < choices.length; i++) {
      if (choices[i] != other.choices[i]) return false;
    }
    return missIdx == other.missIdx && answer == other.answer;
  }

  @override
  int get hashCode {
    var hash = missIdx.hashCode ^ answer.hashCode;
    for (final item in seq) {
      hash ^= item.hashCode;
    }
    for (final item in choices) {
      hash ^= item.hashCode;
    }
    return hash;
  }
}

/// Emoji pool for count rounds: 16 varied object types.
///
/// From raw/data.jsx COUNT_EMOJIS.
const List<String> kCountEmojis = [
  '🥚',
  '🦕',
  '🍎',
  '⭐',
  '🐢',
  '🦋',
  '🐠',
  '🌸',
  '🐞',
  '🦖',
  '🌟',
  '🍌',
  '🐝',
  '🐚',
  '🦴',
  '🪺',
];

/// Generate n count rounds (counts 1–12, varied emoji).
///
/// Uses injected Random for determinism. Ramping behavior:
/// early rounds tend toward smaller counts, later rounds toward larger.
///
/// Ramp formula matches raw/number.jsx CountGame:
///   maxCount = min(12, 4 + floor(i / 2))
/// i=0..1 → max 4; i=2..3 → max 5; … i=16+ → max 12.
///
/// Each round picks a random emoji from the pool.
List<CountRound> genCountRounds(int n, Random r) {
  final rounds = <CountRound>[];

  for (int i = 0; i < n; i++) {
    final emoji = kCountEmojis[r.nextInt(kCountEmojis.length)];
    // Ramp: min(12, 4 + floor(i/2)) — matches prototype formula.
    final maxCount = (4 + i ~/ 2).clamp(1, 12);
    final count = 1 + r.nextInt(maxCount);

    rounds.add(CountRound(emoji: emoji, count: count));
  }

  return rounds;
}

/// Generate n missing-number rounds (sequences 5–6 long, answer 1–20).
///
/// Uses injected Random for determinism.
/// Early sequences (i < 9) are 5 long; later ones (i >= 9) are 6 long.
/// Answer is always 1–20; always appears in exactly 3 choices.
///
/// For a 90-item pool (10 games × 9 questions), each unique sequence
/// may repeat at most twice across all games.
List<MissingNumberRound> genMissingRounds(int n, Random r) {
  final rounds = <MissingNumberRound>[];

  for (int i = 0; i < n; i++) {
    // Ramp sequence length: early rounds 5, later 6.
    final span = i < 9 ? 5 : 6;
    final start = 1 + r.nextInt(i < 9 ? 6 : 14);
    final seq = List.generate(span, (j) => start + j);

    // Missing index is never at the edges (index 0 or span-1).
    final missIdx = 1 + r.nextInt(span - 2);
    final answer = seq[missIdx];

    // Build 3 choices: answer + 2 distractors.
    // Bounded attempts (24) + uniform fallback prevent starvation when answer
    // is near 1 or 20 (few valid near-answer distractors exist).
    final choiceSet = <int>{answer};
    var attempts = 0;
    while (choiceSet.length < 3) {
      final distractor = attempts++ < 24
          ? answer + (r.nextInt(5) - 2) // near-answer offset [-2, +2]
          : 1 + r.nextInt(20); // uniform fallback in [1, 20]
      if (distractor >= 1 && distractor <= 20 && distractor != answer) {
        choiceSet.add(distractor);
      }
    }
    final choices = choiceSet.toList()..sort();

    rounds.add(MissingNumberRound(
      seq: seq,
      missIdx: missIdx,
      answer: answer,
      choices: choices,
    ));
  }

  return rounds;
}
