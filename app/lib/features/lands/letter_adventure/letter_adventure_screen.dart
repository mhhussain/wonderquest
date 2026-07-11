import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/art.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import 'big_letters_game.dart';
import 'match_letters_game.dart';
import 'reading_words_game.dart';
import 'small_letters_game.dart';
import 'trace_letters_game.dart';

/// Entry screen for the Letter Adventure land — shows a 5-game picker.
///
/// Each card navigates to the corresponding game's own screen via
/// [Navigator.push], which manages the LevelSelect → Game → Reward cycle.
class LetterAdventureScreen extends ConsumerWidget {
  const LetterAdventureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          'Letter Adventure ${Art.emoji('land-letter')}',
          style: WqTheme.headingStyle(24),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pick a game to play!',
              style: WqTheme.headingStyle(20).copyWith(color: WqColors.softInk),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _GameCard(
                    key: const Key('game-big'),
                    title: 'Big Letters',
                    emojiKey: 'land-letter',
                    sub: 'Trace the ABC',
                    color: WqColors.orange,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const BigLettersScreen(),
                      ),
                    ),
                  ),
                  _GameCard(
                    key: const Key('game-small'),
                    title: 'Small Letters abc',
                    emojiKey: 'abc',
                    sub: 'Meet lowercase letters',
                    color: WqColors.teal,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const SmallLettersScreen(),
                      ),
                    ),
                  ),
                  _GameCard(
                    key: const Key('game-match'),
                    title: 'Match Big & Small',
                    emojiKey: 'magnet',
                    sub: 'Find the match',
                    color: WqColors.grape,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const MatchLettersScreen(),
                      ),
                    ),
                  ),
                  _GameCard(
                    key: const Key('game-trace'),
                    title: 'Trace Letters',
                    emojiKey: 'land-trace',
                    sub: 'Big & little together',
                    color: WqColors.green,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const TraceLettersScreen(),
                      ),
                    ),
                  ),
                  _GameCard(
                    key: const Key('game-word'),
                    title: 'Reading Words',
                    emojiKey: 'land-reading',
                    sub: 'Drag to build words',
                    color: WqColors.coral,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const ReadingWordsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Game card tile
// ---------------------------------------------------------------------------

class _GameCard extends StatelessWidget {
  const _GameCard({
    super.key,
    required this.title,
    required this.emojiKey,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String emojiKey;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: WqColors.shadow,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Art.glyph(emojiKey, size: 36),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
