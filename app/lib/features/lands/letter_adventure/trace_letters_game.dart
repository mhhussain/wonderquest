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

/// Letter Adventure — Game 4: Trace Letters.
///
/// Like Big Letters but shows uppercase and lowercase side by side. Both
/// glyphs must be covered before the question advances.
class TraceLettersScreen extends ConsumerStatefulWidget {
  const TraceLettersScreen({super.key});

  @override
  ConsumerState<TraceLettersScreen> createState() =>
      _TraceLettersScreenState();
}

class _TraceLettersScreenState extends ConsumerState<TraceLettersScreen> {
  int? _gameIndex;

  void _onPlay(int index) => setState(() => _gameIndex = index);

  Future<void> _onComplete() async {
    final gi = _gameIndex!;
    await ref
        .read(saveControllerProvider.notifier)
        .markLevelDone('trace', gi, 10);
    if (!mounted) return;
    await showRewardModal(
      context,
      ref,
      const Reward(
        stars: 4,
        xp: 30,
        sticker: '✏️',
        progressKey: 'letter',
        progressTo: 70,
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
          'Trace Letters ${Art.emoji('land-trace')}',
          style: WqTheme.headingStyle(22),
        ),
      ),
      body: _gameIndex == null
          ? LevelSelect(
              typeId: 'trace',
              games: 10,
              title: 'Trace Letters',
              color: WqColors.green,
              onPlay: _onPlay,
            )
          : GameDeck<EnglishLetter>(
              typeId: 'trace',
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
    return LetterPairTraceQuestion(
      key: ValueKey('trace-q-${item.u}'),
      letter: item,
      advance: advance,
    );
  }
}

// ---------------------------------------------------------------------------
// Question widget
// ---------------------------------------------------------------------------

/// Single trace question showing uppercase and lowercase side by side.
///
/// Both canvases must reach coverage threshold before [advance] fires.
/// Fires [TtsService.sayPhonics] and [TtsService.speak] on completion.
class LetterPairTraceQuestion extends ConsumerStatefulWidget {
  const LetterPairTraceQuestion({
    super.key,
    required this.letter,
    required this.advance,
  });

  final EnglishLetter letter;
  final VoidCallback advance;

  @override
  ConsumerState<LetterPairTraceQuestion> createState() =>
      _LetterPairTraceQuestionState();
}

class _LetterPairTraceQuestionState
    extends ConsumerState<LetterPairTraceQuestion> {
  int _resetKey = 0;
  bool _upperCovered = false;
  bool _lowerCovered = false;
  bool _advanced = false;

  void _onUpperCovered() {
    if (_upperCovered) return;
    setState(() => _upperCovered = true);
    _checkBothCovered();
  }

  void _onLowerCovered() {
    if (_lowerCovered) return;
    setState(() => _lowerCovered = true);
    _checkBothCovered();
  }

  Future<void> _checkBothCovered() async {
    if (!_upperCovered || !_lowerCovered || _advanced) return;
    _advanced = true;

    unawaited(
      ref
          .read(ttsServiceProvider)
          .speak(
            '${widget.letter.u} and ${widget.letter.l}. '
            '${widget.letter.ph}. ${widget.letter.word}!',
          ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) widget.advance();
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.letter;
    final bothCovered = _upperCovered && _lowerCovered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Label ─────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Art.glyph(letter.emoji, size: 28),
              const SizedBox(width: 8),
              Text(letter.word, style: WqTheme.headingStyle(22)),
            ],
          ),
        ),

        // ── Dual trace canvases ───────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Uppercase
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Big ${letter.u}',
                          style: WqTheme.headingStyle(18).copyWith(
                            color: _upperCovered
                                ? WqColors.green
                                : WqColors.softInk,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TraceCanvas(
                          key: ValueKey('upper-$_resetKey'),
                          glyph: letter.u,
                          onCovered: _onUpperCovered,
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                const VerticalDivider(
                  width: 24,
                  thickness: 2,
                  color: WqColors.lines,
                ),

                // Lowercase
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Little ${letter.l}',
                          style: WqTheme.headingStyle(18).copyWith(
                            color: _lowerCovered
                                ? WqColors.green
                                : WqColors.softInk,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TraceCanvas(
                          key: ValueKey('lower-$_resetKey'),
                          glyph: letter.l,
                          onCovered: _onLowerCovered,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Status + restart ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 64,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _resetKey++;
                      _upperCovered = false;
                      _lowerCovered = false;
                      _advanced = false;
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
              if (bothCovered) ...[
                const SizedBox(width: 16),
                Text(
                  '✓ Both traced!',
                  style: WqTheme.headingStyle(18)
                      .copyWith(color: WqColors.green),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
