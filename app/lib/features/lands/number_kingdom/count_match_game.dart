import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/numbers_content.dart';
import '../../../core/audio/sfx_service.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/save_controller.dart';
import '../../../domain/reward.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/level_select.dart';
import '../../../widgets/reward_modal.dart';

/// Pre-computed 90-item count round pool (deterministic seed).
final _kCountPool = genCountRounds(90, Random('count-pool'.hashCode));

/// Number Kingdom — Game 1: Count & Match.
///
/// Shows a [LevelSelect] with 10 game slots, then a [GameDeck] of count
/// rounds. Each round shows emoji objects the child taps one-by-one; once all
/// are counted the number choices activate.
class CountMatchScreen extends ConsumerStatefulWidget {
  const CountMatchScreen({super.key});

  @override
  ConsumerState<CountMatchScreen> createState() => _CountMatchScreenState();
}

class _CountMatchScreenState extends ConsumerState<CountMatchScreen> {
  int? _gameIndex;

  void _onPlay(int index) => setState(() => _gameIndex = index);

  Future<void> _onComplete() async {
    final gi = _gameIndex!;
    await ref
        .read(saveControllerProvider.notifier)
        .markLevelDone('count', gi, 10);
    if (!mounted) return;
    await showRewardModal(
      context,
      ref,
      const Reward(
        stars: 3,
        xp: 28,
        egg: true,
        progressKey: 'number',
        progressTo: 55,
      ),
      onPlayAgain: () {
        if (mounted) setState(() => _gameIndex = null);
      },
    );
    if (mounted) setState(() => _gameIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: () {
            if (_gameIndex != null) {
              setState(() => _gameIndex = null);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Count & Match \u{1F522}',
          style: WqTheme.headingStyle(22),
        ),
      ),
      body: _gameIndex == null
          ? LevelSelect(
              typeId: 'count',
              games: 10,
              title: 'Count & Match',
              color: WqColors.teal,
              onPlay: _onPlay,
            )
          : GameDeck<CountRound>(
              typeId: 'count',
              gameIndex: _gameIndex!,
              pool: _kCountPool,
              games: 10,
              perGame: 15,
              questionBuilder: _buildQuestion,
              onComplete: _onComplete,
            ),
    );
  }

  Widget _buildQuestion(
    BuildContext context,
    CountRound item,
    VoidCallback advance,
  ) {
    return CountMatchQuestion(
      key: ValueKey('count-q-${item.emoji}-${item.count}'),
      round: item,
      advance: advance,
    );
  }
}

// ---------------------------------------------------------------------------
// Question widget
// ---------------------------------------------------------------------------

/// Single count-and-match question.
///
/// Shows [round.count] emoji objects in a wrap. The child taps each one in
/// turn — a numbered badge appears and the tally is spoken. Once all objects
/// are counted, 4 number choice buttons activate. Tapping the correct answer
/// calls [setNumberMastered] then [advance].
///
/// Wrong taps: brief red flash then reset.
class CountMatchQuestion extends ConsumerStatefulWidget {
  const CountMatchQuestion({
    super.key,
    required this.round,
    required this.advance,
  });

  final CountRound round;
  final VoidCallback advance;

  @override
  ConsumerState<CountMatchQuestion> createState() =>
      _CountMatchQuestionState();
}

class _CountMatchQuestionState extends ConsumerState<CountMatchQuestion> {
  late final List<int> _choices;
  final List<int> _counted = []; // indices of objects tapped, in order
  int? _picked;
  bool _correct = false;

  bool get _allCounted => _counted.length == widget.round.count;

  @override
  void initState() {
    super.initState();
    _choices = _buildChoices(widget.round);
  }

  /// Generates 4 number choices from the round (answer + 3 distractors).
  ///
  /// Seeded deterministically from the round so choices are stable on rebuild.
  static List<int> _buildChoices(CountRound round) {
    final answer = round.count;
    final rng = Random(round.emoji.hashCode ^ answer.hashCode);
    final choiceSet = <int>{answer};

    var tries = 0;
    while (choiceSet.length < 4) {
      if (tries++ > 60) {
        // Fallback: fill with sequential numbers around the answer.
        for (var d = 1; d <= 12 && choiceSet.length < 4; d++) {
          if (!choiceSet.contains(d)) choiceSet.add(d);
        }
        break;
      }
      final d = answer + rng.nextInt(5) - 2;
      if (d >= 1 && d <= 12) choiceSet.add(d);
    }

    return choiceSet.toList()
      ..shuffle(Random(answer.hashCode ^ 0x1337));
  }

  void _tapObject(int k) {
    if (_counted.contains(k)) return; // already tapped
    final next = List<int>.from(_counted)..add(k);
    setState(() {
      _counted.clear();
      _counted.addAll(next);
    });
    // Speak the running tally.
    unawaited(
      ref.read(ttsServiceProvider).speak(
        '${next.length}',
        rate: 0.9,
        pitch: 1.2,
      ),
    );
  }

  Future<void> _choose(int n) async {
    if (!_allCounted) return; // gate: all objects must be counted first
    if (_picked != null && _correct) return; // already answered correctly

    final answer = widget.round.count;
    final ok = n == answer;

    setState(() {
      _picked = n;
      _correct = ok;
    });

    if (ok) {
      unawaited(ref.read(sfxServiceProvider).play(Sfx.ding));
      unawaited(
        ref
            .read(ttsServiceProvider)
            .speak('$answer! That\'s right!', rate: 0.92),
      );
      // Update number mastery.
      unawaited(
        ref
            .read(saveControllerProvider.notifier)
            .setNumberMastered('$answer'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (mounted) widget.advance();
    } else {
      unawaited(ref.read(sfxServiceProvider).play(Sfx.wrong));
      unawaited(
        ref.read(ttsServiceProvider).speak('Try again!', rate: 0.95),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _picked = null;
          _correct = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final round = widget.round;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Prompt ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'How many are there?',
            textAlign: TextAlign.center,
            style: WqTheme.headingStyle(20).copyWith(color: WqColors.softInk),
          ),
        ),

        // ── Object scatter ───────────────────────────────────────────────────
        Expanded(
          flex: 3,
          child: Center(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: List.generate(round.count, (k) {
                  final isCounted = _counted.contains(k);
                  final tallyPos = _counted.indexOf(k) + 1;
                  return GestureDetector(
                    key: Key('count-obj-$k'),
                    onTap: () => _tapObject(k),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Emoji object
                          AnimatedScale(
                            scale: isCounted ? 1.18 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              round.emoji,
                              style: const TextStyle(fontSize: 48),
                            ),
                          ),
                          // Numbered badge when counted
                          if (isCounted)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: WqColors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$tallyPos',
                                    style: const TextStyle(
                                      fontFamily: 'Baloo2',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Instruction when not all counted ─────────────────────────────────
        if (!_allCounted)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Tap each one to count!',
              textAlign: TextAlign.center,
              style: WqTheme.headingStyle(16).copyWith(
                color: WqColors.teal,
              ),
            ),
          ),

        // ── Number choices ────────────────────────────────────────────────────
        Expanded(
          flex: 2,
          child: Center(
            child: IgnorePointer(
              // Gate: choices only respond after all objects are counted.
              ignoring: !_allCounted,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _choices.map((n) {
                  final isPicked = _picked == n;
                  Color bg;
                  if (!_allCounted) {
                    bg = WqColors.backgroundAlt;
                  } else if (isPicked && _correct) {
                    bg = WqColors.green;
                  } else if (isPicked && !_correct) {
                    bg = WqColors.coral;
                  } else {
                    bg = WqColors.backgroundAlt;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      key: Key('count-choice-$n'),
                      onTap: () => _choose(n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _allCounted
                                ? WqColors.teal
                                : WqColors.lines,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$n',
                            style: TextStyle(
                              fontFamily: 'Baloo2',
                              fontWeight: FontWeight.w800,
                              fontSize: 48,
                              color: isPicked
                                  ? Colors.white
                                  : (_allCounted
                                      ? WqColors.teal
                                      : WqColors.softInk),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
