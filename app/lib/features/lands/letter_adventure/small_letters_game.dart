import 'dart:async';

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
import '../../../widgets/reward_modal.dart';

/// Letter Adventure — Game 2: Small Letters abc.
///
/// Displays a 5-column grid of all 26 uppercase→lowercase pairs. Tapping a
/// card plays [TtsService.sayPhonics] and marks it visited. When all 26 have
/// been visited a [showRewardModal] is presented.
class SmallLettersScreen extends ConsumerStatefulWidget {
  const SmallLettersScreen({super.key});

  @override
  ConsumerState<SmallLettersScreen> createState() => _SmallLettersScreenState();
}

class _SmallLettersScreenState extends ConsumerState<SmallLettersScreen> {
  final Set<String> _visited = {};
  EnglishLetter? _current;
  bool _rewarded = false;

  Future<void> _tap(EnglishLetter letter) async {
    setState(() {
      _current = letter;
      _visited.add(letter.u);
    });

    unawaited(
      ref.read(sfxServiceProvider).play(Sfx.pop),
    );
    unawaited(
      ref.read(ttsServiceProvider).sayPhonics(letter.l, letter.word),
    );

    if (_visited.length == kEnglishLetters.length && !_rewarded) {
      _rewarded = true;
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await ref
          .read(saveControllerProvider.notifier)
          .markLevelDone('small', 0, 1);
      if (!mounted) return;
      await showRewardModal(
        context,
        ref,
        const Reward(
          stars: 5,
          xp: 30,
          egg: true,
          sticker: '🐣',
          progressKey: 'letter',
          progressTo: 65,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Small Letters abc ${Art.emoji('abc')}',
          style: WqTheme.headingStyle(22),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                '${_visited.length} / ${kEnglishLetters.length} met',
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: WqColors.softInk,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info panel ──────────────────────────────────────────────────
            SizedBox(
              width: 220,
              child: _InfoPanel(current: _current),
            ),
            const SizedBox(width: 16),

            // ── Letter grid ─────────────────────────────────────────────────
            Expanded(
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: kEnglishLetters.length,
                itemBuilder: (context, index) {
                  final letter = kEnglishLetters[index];
                  final visited = _visited.contains(letter.u);
                  final isCurrent = _current?.u == letter.u;
                  return _LetterCard(
                    key: Key('letter-card-${letter.u}'),
                    letter: letter,
                    visited: visited,
                    isCurrent: isCurrent,
                    onTap: () => _tap(letter),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info panel
// ---------------------------------------------------------------------------

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.current});

  final EnglishLetter? current;

  @override
  Widget build(BuildContext context) {
    if (current == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: WqColors.backgroundAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: WqColors.lines, width: 2),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('👆', style: TextStyle(fontSize: 56)),
              SizedBox(height: 12),
              Text(
                'Tap any letter\nto meet it!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: WqColors.softInk,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: WqColors.backgroundAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WqColors.lines, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Uppercase + lowercase pair
            Text(
              '${current!.u} ${current!.l}',
              style: WqTheme.headingStyle(52).copyWith(color: WqColors.orange),
            ),
            const SizedBox(height: 8),
            // Emoji
            Art.glyph(current!.emoji, size: 52),
            const SizedBox(height: 8),
            // Word
            Text(
              current!.word,
              style: WqTheme.headingStyle(20),
            ),
            const SizedBox(height: 4),
            // Sound
            Text(
              'sound: "${current!.ph}"',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: WqColors.softInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Letter card tile
// ---------------------------------------------------------------------------

class _LetterCard extends StatelessWidget {
  const _LetterCard({
    super.key,
    required this.letter,
    required this.visited,
    required this.isCurrent,
    required this.onTap,
  });

  final EnglishLetter letter;
  final bool visited;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (isCurrent) {
      bg = WqColors.orange;
    } else if (visited) {
      bg = WqColors.teal;
    } else {
      bg = WqColors.backgroundAlt;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? WqColors.orange : WqColors.lines,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${letter.u}${letter.l}',
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: (visited || isCurrent) ? Colors.white : WqColors.ink,
              ),
            ),
            Art.glyph(letter.emoji, size: 22),
          ],
        ),
      ),
    );
  }
}
