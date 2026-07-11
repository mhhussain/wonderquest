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
import '../../../core/progress_keys.dart';

/// Letter Adventure — Game 5: Reading Words.
///
/// Shows a [LevelSelect] with 10 game slots, then a [GameDeck] of word-family
/// drag-to-build questions. The child drags the missing onset letter(s) from a
/// tile tray onto the word blank to assemble the word.
class ReadingWordsScreen extends ConsumerStatefulWidget {
  const ReadingWordsScreen({super.key});

  @override
  ConsumerState<ReadingWordsScreen> createState() =>
      _ReadingWordsScreenState();
}

class _ReadingWordsScreenState extends ConsumerState<ReadingWordsScreen> {
  int? _gameIndex;

  void _onPlay(int index) => setState(() => _gameIndex = index);

  Future<void> _onComplete() async {
    final gi = _gameIndex!;
    await ref
        .read(saveControllerProvider.notifier)
        .markLevelDone('word', gi, 10);
    if (!mounted) return;
    await showRewardModal(
      context,
      ref,
      const Reward(
        stars: 5,
        xp: 40,
        egg: true,
        sticker: '📖',
        progressKey: ProgressKeys.letter,
        progressTo: 90,
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
          'Reading Words ${Art.emoji('land-reading')}',
          style: WqTheme.headingStyle(22),
        ),
      ),
      body: _gameIndex == null
          ? LevelSelect(
              typeId: 'word',
              games: 10,
              title: 'Reading Words',
              color: WqColors.coral,
              onPlay: _onPlay,
            )
          : GameDeck<WordFamily>(
              typeId: 'word',
              gameIndex: _gameIndex!,
              pool: kWordFamilies,
              games: 10,
              perGame: 15,
              questionBuilder: _buildQuestion,
              onComplete: _onComplete,
            ),
    );
  }

  Widget _buildQuestion(
    BuildContext context,
    WordFamily item,
    VoidCallback advance,
  ) {
    return ReadingWordsQuestion(
      key: ValueKey('word-q-${item.word}'),
      round: item,
      advance: advance,
    );
  }
}

// ---------------------------------------------------------------------------
// Question widget
// ---------------------------------------------------------------------------

/// Single drag-to-build question.
///
/// Renders the word-family picture and blank slots, plus a tray of draggable
/// letter tiles (miss + distract, shuffled). The child drags tiles onto the
/// [DragTarget] word frame. Correct tiles fill the next slot; wrong tiles
/// trigger [Sfx.wrong]. When all slots are filled the word is spoken and
/// [advance] fires after a short delay.
class ReadingWordsQuestion extends ConsumerStatefulWidget {
  const ReadingWordsQuestion({
    super.key,
    required this.round,
    required this.advance,
  });

  final WordFamily round;
  final VoidCallback advance;

  @override
  ConsumerState<ReadingWordsQuestion> createState() =>
      _ReadingWordsQuestionState();
}

class _ReadingWordsQuestionState extends ConsumerState<ReadingWordsQuestion> {
  late final List<String> _tiles;
  List<String> _filled = const [];
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _tiles = [...widget.round.miss, ...widget.round.distract]
      ..shuffle(Random(widget.round.word.hashCode));
  }

  bool _isTileUsed(int tileIndex) {
    final letter = _tiles[tileIndex];
    if (!widget.round.miss.contains(letter)) return false;
    final alreadyFilled = _filled.where((f) => f == letter).length;
    // Earlier identical tiles "consume" the filled slots first.
    final earlierSame = _tiles
        .sublist(0, tileIndex)
        .where((t) => t == letter)
        .length;
    return earlierSame < alreadyFilled;
  }

  void _handleDrop(String letter) {
    if (_done || _filled.length >= widget.round.miss.length) return;
    final needed = widget.round.miss[_filled.length];
    if (letter == needed) {
      final newFilled = [..._filled, letter];
      final allDone = newFilled.length >= widget.round.miss.length;
      setState(() {
        _filled = newFilled;
        _done = allDone;
      });

      final tts = ref.read(ttsServiceProvider);
      if (allDone) {
        // Speak: each miss letter then end then full word.
        final missText = newFilled.join('… ');
        unawaited(
          tts.speak('$missText… ${widget.round.end}… ${widget.round.word}!'),
        );
        Future<void>.delayed(const Duration(milliseconds: 1500)).then((_) {
          if (mounted) widget.advance();
        });
      } else {
        unawaited(tts.speak(letter));
      }
    } else {
      unawaited(ref.read(sfxServiceProvider).play(Sfx.wrong));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Prompt ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            widget.round.miss.length > 1
                ? 'Two letters now — sound them out!'
                : 'Drag the first letter to finish the word',
            textAlign: TextAlign.center,
            style: WqTheme.headingStyle(18).copyWith(color: WqColors.softInk),
          ),
        ),

        // ── Scene card: emoji + word frame ──────────────────────────────────
        Expanded(
          child: Center(
            child: DragTarget<String>(
              key: const Key('word-target'),
              onWillAcceptWithDetails: (_) => !_done,
              onAcceptWithDetails: (details) => _handleDrop(details.data),
              builder: (context, candidateData, rejectedData) {
                final highlighted = candidateData.isNotEmpty;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: highlighted
                        ? WqColors.backgroundAlt
                        : WqColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: highlighted
                          ? WqColors.orange
                          : WqColors.lines,
                      width: highlighted ? 3 : 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 24,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Emoji
                        Art.glyph(widget.round.emoji, size: 80),
                        const SizedBox(width: 28),
                        // Word frame: slots + ending
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...widget.round.miss.asMap().entries.map(
                              (entry) {
                                final si = entry.key;
                                final filled = si < _filled.length;
                                return _WordSlot(
                                  key: Key('slot-$si'),
                                  letter: filled ? _filled[si] : null,
                                  isNext: si == _filled.length &&
                                      candidateData.isNotEmpty,
                                );
                              },
                            ),
                            Text(
                              widget.round.end,
                              style: WqTheme.headingStyle(60).copyWith(
                                color: WqColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ── Tile tray ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: _tiles.asMap().entries.map((entry) {
              final idx = entry.key;
              final letter = entry.value;
              final isUsed = _isTileUsed(idx);
              return _DraggableTile(
                key: Key('tile-$letter-$idx'),
                letter: letter,
                isUsed: isUsed,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Word slot
// ---------------------------------------------------------------------------

class _WordSlot extends StatelessWidget {
  const _WordSlot({
    super.key,
    required this.letter,
    required this.isNext,
  });

  final String? letter;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final isFilled = letter != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 70,
      height: 90,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: isFilled
            ? WqColors.green.withValues(alpha: 0.15)
            : isNext
                ? WqColors.orange.withValues(alpha: 0.15)
                : WqColors.backgroundAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFilled
              ? WqColors.green
              : isNext
                  ? WqColors.orange
                  : WqColors.lines,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          isFilled ? letter! : '?',
          style: WqTheme.headingStyle(isFilled ? 48 : 36).copyWith(
            color: isFilled ? WqColors.green : WqColors.softInk,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Draggable tile
// ---------------------------------------------------------------------------

class _DraggableTile extends StatelessWidget {
  const _DraggableTile({
    super.key,
    required this.letter,
    required this.isUsed,
  });

  final String letter;
  final bool isUsed;

  @override
  Widget build(BuildContext context) {
    if (isUsed) {
      return _TileFace(letter: letter, faded: true);
    }
    return Draggable<String>(
      data: letter,
      feedback: Material(
        color: Colors.transparent,
        child: _TileFace(
          letter: letter,
          faded: false,
          scale: 1.15,
          shadow: true,
        ),
      ),
      childWhenDragging: _TileFace(letter: letter, faded: true),
      child: _TileFace(letter: letter, faded: false),
    );
  }
}

class _TileFace extends StatelessWidget {
  const _TileFace({
    required this.letter,
    required this.faded,
    this.scale = 1.0,
    this.shadow = false,
  });

  final String letter;
  final bool faded;
  final double scale;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: faded ? WqColors.lines : WqColors.backgroundAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: faded ? WqColors.lines : WqColors.teal,
            width: 2,
          ),
          boxShadow: shadow
              ? [
                  const BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: SizedBox(
          width: 80,
          height: 80,
          child: Center(
            child: Text(
              letter,
              style: WqTheme.headingStyle(46).copyWith(
                color: faded ? WqColors.softInk : WqColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
