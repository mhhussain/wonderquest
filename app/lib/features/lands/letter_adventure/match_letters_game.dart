import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/english_letters.dart';
import '../../../core/art.dart';
import '../../../core/audio/sfx_service.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/save_controller.dart';
import '../../../domain/reward.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/level_select.dart';
import '../../../widgets/reward_modal.dart';

/// Pre-computed ordered pool for the match game (kMatchOrder → EnglishLetter).
List<EnglishLetter> get _matchPool => kMatchOrder
    .map((u) => kEnglishLetters.firstWhere((e) => e.u == u))
    .toList();

/// Letter Adventure — Game 3: Match Big & Small.
///
/// Shows a [LevelSelect] with 10 game slots, then a [GameDeck] of uppercase
/// → lowercase matching questions drawn from [kMatchOrder].
class MatchLettersScreen extends ConsumerStatefulWidget {
  const MatchLettersScreen({super.key});

  @override
  ConsumerState<MatchLettersScreen> createState() =>
      _MatchLettersScreenState();
}

class _MatchLettersScreenState extends ConsumerState<MatchLettersScreen> {
  int? _gameIndex;

  void _onPlay(int index) => setState(() => _gameIndex = index);

  Future<void> _onComplete() async {
    final gi = _gameIndex!;
    await ref
        .read(saveControllerProvider.notifier)
        .markLevelDone('match', gi, 10);
    if (!mounted) return;
    await showRewardModal(
      context,
      ref,
      const Reward(
        stars: 5,
        xp: 36,
        egg: true,
        sticker: '🏅',
        progressKey: 'letter',
        progressTo: 80,
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
          'Match Big & Small ${Art.emoji('magnet')}',
          style: WqTheme.headingStyle(22),
        ),
      ),
      body: _gameIndex == null
          ? LevelSelect(
              typeId: 'match',
              games: 10,
              title: 'Match Big & Small',
              color: WqColors.grape,
              onPlay: _onPlay,
            )
          : GameDeck<EnglishLetter>(
              typeId: 'match',
              gameIndex: _gameIndex!,
              pool: _matchPool,
              games: 10,
              perGame: 15,
              questionBuilder: _buildQuestion,
              onComplete: _onComplete,
            ),
    );
  }

  Widget _buildQuestion(
    BuildContext context,
    EnglishLetter item,
    VoidCallback advance,
  ) {
    return MatchQuestion(
      key: ValueKey('match-q-${item.u}'),
      letter: item,
      advance: advance,
    );
  }
}

// ---------------------------------------------------------------------------
// Question widget
// ---------------------------------------------------------------------------

/// Single matching question: shows the uppercase letter and 3 lowercase
/// choice buttons. The confusable pair (from [kConfusables]) is always
/// included when one exists.
///
/// Wrong tap: brief red flash then reset. Correct tap: cheer + advance.
class MatchQuestion extends ConsumerStatefulWidget {
  const MatchQuestion({
    super.key,
    required this.letter,
    required this.advance,
  });

  final EnglishLetter letter;
  final VoidCallback advance;

  @override
  ConsumerState<MatchQuestion> createState() => _MatchQuestionState();
}

class _MatchQuestionState extends ConsumerState<MatchQuestion> {
  late final List<String> _choices;
  String? _picked; // null = no pick yet
  bool _correct = false;

  @override
  void initState() {
    super.initState();
    _choices = _buildChoices(widget.letter);
  }

  static List<String> _buildChoices(EnglishLetter letter) {
    final answer = letter.l;
    final wrong = <String>{};

    // Always force the confusable as the first distractor when one exists.
    final confusable = kConfusables[answer];
    if (confusable != null) wrong.add(confusable);

    // Fill remaining distractors from a shuffled pool.
    final pool = kEnglishLetters.map((e) => e.l).where((l) => l != answer).toList()
      ..shuffle(Random(answer.codeUnitAt(0)));
    for (final l in pool) {
      if (wrong.length >= 2) break;
      wrong.add(l);
    }

    return ([answer, ...wrong.take(2)]..shuffle(Random(answer.codeUnitAt(0) + 1)));
  }

  Future<void> _choose(String chosen) async {
    if (_picked != null && _correct) return; // already answered correctly

    final answer = widget.letter.l;
    final ok = chosen == answer;

    setState(() {
      _picked = chosen;
      _correct = ok;
    });

    if (ok) {
      unawaited(
        ref.read(sfxServiceProvider).play(Sfx.ding),
      );
      unawaited(
        ref.read(ttsServiceProvider).speak(
          'Yes! Big ${widget.letter.u}, little ${widget.letter.l}.',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (mounted) widget.advance();
    } else {
      unawaited(ref.read(sfxServiceProvider).play(Sfx.wrong));
      await Future<void>.delayed(const Duration(milliseconds: 520));
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
    final letter = widget.letter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Prompt ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Which little letter is this?',
            textAlign: TextAlign.center,
            style: WqTheme.headingStyle(20).copyWith(color: WqColors.softInk),
          ),
        ),

        // ── Uppercase letter card ────────────────────────────────────────────
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: WqColors.backgroundAlt,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: WqColors.lines, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    letter.u,
                    style: WqTheme.headingStyle(110)
                        .copyWith(color: WqColors.orange),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Art.glyph(letter.emoji, size: 28),
                      const SizedBox(width: 8),
                      Text(letter.word, style: WqTheme.headingStyle(18)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Choice buttons ────────────────────────────────────────────────────
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _choices.map((l) {
              final isPicked = _picked == l;
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
                  onTap: () => _choose(l),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: WqColors.lines, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        l,
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontWeight: FontWeight.w700,
                          fontSize: 64,
                          color: isPicked ? Colors.white : WqColors.teal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
