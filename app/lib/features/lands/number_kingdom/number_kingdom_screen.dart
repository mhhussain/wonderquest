import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/art.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import 'count_match_game.dart';
import 'missing_number_game.dart';

/// Entry screen for the Number Kingdom land — shows a 2-game picker.
///
/// Each card navigates to the corresponding game's own screen via
/// [Navigator.push], which manages the LevelSelect → Game → Reward cycle.
class NumberKingdomScreen extends ConsumerWidget {
  const NumberKingdomScreen({super.key});

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
          'Number Kingdom ${Art.emoji('land-number')}',
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
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
                children: [
                  _GameCard(
                    key: const Key('game-count'),
                    title: 'Count & Match',
                    emojiKey: 'land-number',
                    sub: '10 games',
                    color: WqColors.teal,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const CountMatchScreen(),
                      ),
                    ),
                  ),
                  _GameCard(
                    key: const Key('game-missing'),
                    title: 'Missing Number',
                    emojiKey: 'land-number',
                    sub: '10 games',
                    color: WqColors.sky,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const MissingNumberScreen(),
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
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
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
