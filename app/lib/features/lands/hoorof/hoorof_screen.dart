import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/art.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/land_game_card.dart';
import 'find_letter_game.dart';
import 'hear_match_game.dart';
import 'learn_letter_game.dart';
import 'letter_pop_game.dart';
import 'memory_match_game.dart';
import 'safari_hunt_game.dart';
import 'shape_builder_game.dart';
import 'trace_letter_game.dart';

// ---------------------------------------------------------------------------
// Game card descriptor
// ---------------------------------------------------------------------------

class _CardSpec {
  const _CardSpec({
    required this.id,
    required this.title,
    required this.sub,
    required this.emoji,
    required this.color,
  });

  final String id;
  final String title;
  final String sub;
  final String emoji;
  final Color color;
}

const _kCards = <_CardSpec>[
  _CardSpec(
    id: 'learn',
    title: 'Learn the Letter',
    sub: 'Tap, hear, discover',
    emoji: '🔤',
    color: WqColors.teal,
  ),
  _CardSpec(
    id: 'trace',
    title: 'Trace the Letter',
    sub: 'Draw the glyph',
    emoji: '✏️',
    color: WqColors.green,
  ),
  _CardSpec(
    id: 'hear',
    title: 'Hear & Match',
    sub: 'Listen, tap the letter',
    emoji: '🎧',
    color: WqColors.grape,
  ),
  _CardSpec(
    id: 'memory',
    title: 'Match the Letters',
    sub: 'Find the pairs',
    emoji: '🧩',
    color: WqColors.orange,
  ),
  _CardSpec(
    id: 'find',
    title: 'Find the Letter',
    sub: 'Spot it in the crowd',
    emoji: '🔎',
    color: WqColors.yellow,
  ),
  _CardSpec(
    id: 'build',
    title: 'Shape Builder',
    sub: 'Add the dots',
    emoji: '🖍️',
    color: WqColors.pink,
  ),
  _CardSpec(
    id: 'pop',
    title: 'Letter Pop',
    sub: 'Pop the right balloon',
    emoji: '🎈',
    color: WqColors.coral,
  ),
  _CardSpec(
    id: 'safari',
    title: 'Safari Letter Hunt',
    sub: 'Desert letter explorer',
    emoji: '🐪',
    color: WqColors.sky,
  ),
];

// ---------------------------------------------------------------------------
// HoroofScreen
// ---------------------------------------------------------------------------

/// Entry screen for the Hoorof (حروف) land — Arabic letter adventure.
///
/// Shows an 8-game picker grid. Each card navigates to the corresponding
/// game screen via [Navigator.push].
///
/// UI chrome is English, LTR. Arabic glyphs and words appear only inside
/// individual game widgets.
class HoroofScreen extends ConsumerWidget {
  const HoroofScreen({super.key});

  Widget _screenFor(String id) {
    return switch (id) {
      'learn' => const LearnLetterScreen(),
      'trace' => const TraceLetterScreen(),
      'hear' => const HearMatchScreen(),
      'memory' => const MemoryMatchScreen(),
      'find' => const FindLetterScreen(),
      'build' => const ShapeBuilderScreen(),
      'pop' => const LetterPopScreen(),
      'safari' => const SafariHuntScreen(),
      _ => throw ArgumentError('Unknown game id: $id'),
    };
  }

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
          'Hoorof ${Art.emoji('land-hoorof')}',
          style: WqTheme.headingStyle(22),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Arabic Letter Adventure — pick a game!',
              style:
                  WqTheme.headingStyle(17).copyWith(color: WqColors.softInk),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: _kCards.map((card) {
                  return LandGameCard(
                    key: Key('hrf-${card.id}'),
                    title: card.title,
                    subtitle: card.sub,
                    icon: card.emoji,
                    color: card.color,
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => _screenFor(card.id),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

