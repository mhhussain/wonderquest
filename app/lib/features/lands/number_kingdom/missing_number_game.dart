import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/numbers_content.dart';
import '../../../core/art.dart';
import '../../../core/audio/sfx_service.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/save_controller.dart';
import '../../../domain/reward.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/level_select.dart';
import '../../../widgets/reward_modal.dart';

/// Pre-computed 90-item missing-number round pool (deterministic seed).
final _kMissingPool = genMissingRounds(90, Random('missing-pool'.hashCode));

/// Number Kingdom — Game 2: Missing Number.
///
/// Shows a [LevelSelect] with 10 game slots, then a [GameDeck] of missing
/// number rounds. Each round shows a number sequence with one gap; the child
/// picks the missing number from 3 choices.
class MissingNumberScreen extends ConsumerStatefulWidget {
  const MissingNumberScreen({super.key});

  @override
  ConsumerState<MissingNumberScreen> createState() =>
      _MissingNumberScreenState();
}

class _MissingNumberScreenState extends ConsumerState<MissingNumberScreen> {
  int? _gameIndex;

  void _onPlay(int index) => setState(() => _gameIndex = index);

  Future<void> _onComplete() async {
    final gi = _gameIndex!;
    await ref
        .read(saveControllerProvider.notifier)
        .markLevelDone('missing', gi, 10);
    if (!mounted) return;
    await showRewardModal(
      context,
      ref,
      const Reward(
        stars: 3,
        xp: 26,
        sticker: '\u{1F522}',
        progressKey: 'number',
        progressTo: 50,
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
          'Missing Number ${Art.emoji('abacus')}',
          style: WqTheme.headingStyle(22),
        ),
      ),
      body: _gameIndex == null
          ? LevelSelect(
              typeId: 'missing',
              games: 10,
              title: 'Missing Number',
              color: WqColors.sky,
              onPlay: _onPlay,
            )
          : GameDeck<MissingNumberRound>(
              typeId: 'missing',
              gameIndex: _gameIndex!,
              pool: _kMissingPool,
              games: 10,
              perGame: 15,
              questionBuilder: _buildQuestion,
              onComplete: _onComplete,
            ),
    );
  }

  Widget _buildQuestion(
    BuildContext context,
    MissingNumberRound item,
    VoidCallback advance,
  ) {
    return MissingNumberQuestion(
      key: ValueKey('missing-q-${item.seq.join('-')}-${item.missIdx}'),
      round: item,
      advance: advance,
    );
  }
}

// ---------------------------------------------------------------------------
// Question widget
// ---------------------------------------------------------------------------

/// Single missing-number question.
///
/// Shows a sequence of number tiles with one gap (displayed as '?'). The
/// child picks the missing number from [round.choices] (3 options). Correct
/// tap fills the gap with a pop animation and calls [advance] after a short
/// delay. Wrong tap: brief red flash then reset.
class MissingNumberQuestion extends ConsumerStatefulWidget {
  const MissingNumberQuestion({
    super.key,
    required this.round,
    required this.advance,
  });

  final MissingNumberRound round;
  final VoidCallback advance;

  @override
  ConsumerState<MissingNumberQuestion> createState() =>
      _MissingNumberQuestionState();
}

class _MissingNumberQuestionState
    extends ConsumerState<MissingNumberQuestion> {
  int? _picked;
  bool _correct = false;

  Future<void> _choose(int n) async {
    if (_picked != null && _correct) return; // already answered correctly

    final answer = widget.round.answer;
    final ok = n == answer;

    setState(() {
      _picked = n;
      _correct = ok;
    });

    if (ok) {
      unawaited(ref.read(sfxServiceProvider).play(Sfx.ding));
      unawaited(
        ref.read(ttsServiceProvider).speak('$n! Perfect!', rate: 0.92),
      );
      // Update number mastery.
      unawaited(
        ref
            .read(saveControllerProvider.notifier)
            .setNumberMastered('$n'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1000));
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
            'Which number fills the gap?',
            textAlign: TextAlign.center,
            style: WqTheme.headingStyle(20).copyWith(color: WqColors.softInk),
          ),
        ),

        // ── Sequence tiles ────────────────────────────────────────────────────
        Expanded(
          flex: 3,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(round.seq.length, (k) {
                  final isGap = k == round.missIdx;
                  final showAnswer = isGap && _correct;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AnimatedContainer(
                      key: isGap ? const Key('missing-gap') : null,
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      height: 96,
                      decoration: BoxDecoration(
                        color: isGap
                            ? (showAnswer
                                ? WqColors.green
                                : WqColors.gapBackground)
                            : WqColors.teal,
                        borderRadius: BorderRadius.circular(18),
                        border: isGap && !showAnswer
                            ? Border.all(
                                color: WqColors.orange,
                                width: 5,
                                strokeAlign: BorderSide.strokeAlignInside,
                              )
                            : null,
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            isGap
                                ? (showAnswer ? '${round.answer}' : '?')
                                : '${round.seq[k]}',
                            key: ValueKey(
                              isGap
                                  ? (showAnswer ? 'ans' : 'gap')
                                  : 'tile-$k',
                            ),
                            style: TextStyle(
                              fontFamily: 'Baloo2',
                              fontWeight: FontWeight.w800,
                              fontSize: 40,
                              color: isGap && !showAnswer
                                  ? WqColors.orange
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Choice buttons ────────────────────────────────────────────────────
        Expanded(
          flex: 2,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: round.choices.map((n) {
                final isPicked = _picked == n;
                Color bg;
                if (isPicked && _correct) {
                  bg = WqColors.green;
                } else if (isPicked && !_correct) {
                  bg = WqColors.coral;
                } else {
                  bg = WqColors.backgroundAlt;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GestureDetector(
                    key: Key('missing-choice-$n'),
                    onTap: () => _choose(n),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: WqColors.lines, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '$n',
                          style: TextStyle(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w800,
                            fontSize: 52,
                            color: isPicked ? Colors.white : WqColors.sky,
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

        const SizedBox(height: 16),
      ],
    );
  }
}
