import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/english_letters.dart';
import '../../../core/art.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/save_controller.dart';
import '../../../domain/reward.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/level_select.dart';
import '../../../widgets/reward_modal.dart';
import '../../../widgets/trace_canvas.dart';

/// Letter Adventure — Game 1: Big Letters.
///
/// Shows a [LevelSelect] with 10 game slots, then a [GameDeck] of uppercase
/// letter tracing questions. Tracing a letter calls [TtsService.sayPhonics]
/// and tracks learning/mastery in [SaveController].
class BigLettersScreen extends ConsumerStatefulWidget {
  const BigLettersScreen({super.key});

  @override
  ConsumerState<BigLettersScreen> createState() => _BigLettersScreenState();
}

class _BigLettersScreenState extends ConsumerState<BigLettersScreen> {
  int? _gameIndex;

  void _onPlay(int index) => setState(() => _gameIndex = index);

  Future<void> _onComplete() async {
    final gi = _gameIndex!;
    await ref.read(saveControllerProvider.notifier).markLevelDone('big', gi, 10);
    if (!mounted) return;
    await showRewardModal(
      context,
      ref,
      const Reward(stars: 3, xp: 20, progressKey: 'letter', progressTo: 55),
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
          'Big Letters ${Art.emoji('land-letter')}',
          style: WqTheme.headingStyle(22),
        ),
      ),
      body: _gameIndex == null
          ? LevelSelect(
              typeId: 'big',
              games: 10,
              title: 'Big Letters',
              color: WqColors.orange,
              onPlay: _onPlay,
            )
          : GameDeck<EnglishLetter>(
              typeId: 'big',
              gameIndex: _gameIndex!,
              pool: kEnglishLetters,
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
    return LetterTraceQuestion(
      key: ValueKey('big-q-${item.u}'),
      letter: item,
      advance: advance,
    );
  }
}

// ---------------------------------------------------------------------------
// Question widget
// ---------------------------------------------------------------------------

/// Single tracing question: shows the letter label, a [TraceCanvas] for the
/// uppercase glyph, and a restart button. Fires [advance] ≈ 1.5 s after the
/// coverage threshold is reached.
///
/// On coverage: calls [TtsService.sayPhonics] and updates letter
/// learning/mastery state in [SaveController].
class LetterTraceQuestion extends ConsumerStatefulWidget {
  const LetterTraceQuestion({
    super.key,
    required this.letter,
    required this.advance,
  });

  final EnglishLetter letter;
  final VoidCallback advance;

  @override
  ConsumerState<LetterTraceQuestion> createState() =>
      _LetterTraceQuestionState();
}

class _LetterTraceQuestionState extends ConsumerState<LetterTraceQuestion> {
  int _resetKey = 0;
  bool _covered = false;

  Future<void> _onCovered() async {
    if (_covered) return;
    _covered = true;

    // Phonics callout.
    unawaited(
      ref
          .read(ttsServiceProvider)
          .sayPhonics(widget.letter.u, widget.letter.word),
    );

    // Update letter learning/mastery.
    final save = ref.read(saveControllerProvider).value;
    final learning = save?.lettersLearning ?? const <String>[];
    if (learning.contains(widget.letter.u)) {
      unawaited(
        ref
            .read(saveControllerProvider.notifier)
            .setLetterMastered(widget.letter.u),
      );
    } else {
      unawaited(
        ref
            .read(saveControllerProvider.notifier)
            .setLetterLearning(widget.letter.u),
      );
    }

    // Advance after sparkle animation completes (~1.5 s).
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) widget.advance();
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.letter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Letter label ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${letter.u} is for ',
                style: WqTheme.headingStyle(22),
              ),
              Art.glyph(letter.emoji, size: 28),
              Text(
                ' ${letter.word}',
                style: WqTheme.headingStyle(22),
              ),
            ],
          ),
        ),

        // ── Trace canvas ─────────────────────────────────────────────────────
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: TraceCanvas(
                  key: ValueKey('trace-$_resetKey'),
                  glyph: letter.u,
                  onCovered: _onCovered,
                ),
              ),
            ),
          ),
        ),

        // ── Restart button ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              height: 64,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _resetKey++;
                    _covered = false;
                  });
                },
                icon: const Text('↺', style: TextStyle(fontSize: 20)),
                label: const Text(
                  'Start over',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: WqColors.ink,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: WqColors.lines, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
