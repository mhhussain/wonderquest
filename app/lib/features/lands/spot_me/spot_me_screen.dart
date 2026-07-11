import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore_for_file: avoid_classes_with_only_static_members

import '../../../core/art.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import 'count_it_game.dart';
import 'detective_game.dart';
import 'hidden_object_game.dart';
import 'socks_game.dart';
import 'spot_difference_game.dart';

// ---------------------------------------------------------------------------
// Session-level detective title tracking
// ---------------------------------------------------------------------------

/// [Notifier] that tracks how many Spot Me games have been completed this
/// session.  Created with `isAutoDispose: true` so it resets when the land is
/// exited (no widgets are watching it).
class _SpotMeSessionNotifier extends Notifier<int> {
  @override
  int build() {
    // Keep the notifier alive for the full app session even though no widget
    // holds a persistent watch subscription (games use ref.read).
    ref.keepAlive();
    return 0;
  }

  /// Increments the session count and returns the new value.
  int increment() {
    state++;
    return state;
  }
}

/// Provider for the in-session Spot Me completion count.
final spotMeSessionCountProvider =
    NotifierProvider<_SpotMeSessionNotifier, int>(
  _SpotMeSessionNotifier.new,
  isAutoDispose: true,
);

/// Returns the detective-title sticker to award when [count] games have been
/// completed, or `null` if no threshold is crossed at this count.
String? detectiveTitleForCount(int count) {
  const thresholds = [
    (1, 'Junior Detective'),
    (3, 'Rookie Spotter'),
    (5, 'Scene Explorer'),
    (7, 'Ace Detective'),
    (9, 'Hidden Object Hero'),
  ];
  for (final (n, title) in thresholds) {
    if (count == n) return title;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Dashboard cards
// ---------------------------------------------------------------------------

class _CardSpec {
  final String id;
  final String title;
  final String sub;
  final String emoji;
  final Color color;

  const _CardSpec({
    required this.id,
    required this.title,
    required this.sub,
    required this.emoji,
    required this.color,
  });
}

const _kCards = <_CardSpec>[
  _CardSpec(
    id: 'hunt',
    title: 'Hidden Object Hunt',
    sub: 'Find the things',
    emoji: '🔍',
    color: WqColors.yellow,
  ),
  _CardSpec(
    id: 'socks',
    title: 'Match the Socks',
    sub: 'Find the pairs',
    emoji: '🧦',
    color: WqColors.grape,
  ),
  _CardSpec(
    id: 'count',
    title: 'Count It If You Can',
    sub: 'Tap and count',
    emoji: '🔢',
    color: WqColors.teal,
  ),
  _CardSpec(
    id: 'letter',
    title: 'Letter Detective',
    sub: 'Find the letters',
    emoji: '🔤',
    color: WqColors.orange,
  ),
  _CardSpec(
    id: 'shape',
    title: 'Shape Safari',
    sub: 'Find the shapes',
    emoji: '🔺',
    color: WqColors.grape,
  ),
  _CardSpec(
    id: 'animal',
    title: 'Animal Tracker',
    sub: 'Find the animals',
    emoji: '🐾',
    color: WqColors.green,
  ),
  _CardSpec(
    id: 'diff',
    title: 'Spot the Difference',
    sub: 'What changed?',
    emoji: '🆚',
    color: WqColors.coral,
  ),
  _CardSpec(
    id: 'color',
    title: 'Color Quest',
    sub: 'Find by color',
    emoji: '🎨',
    color: WqColors.pink,
  ),
  _CardSpec(
    id: 'number',
    title: 'Number Detective',
    sub: 'Find the numbers',
    emoji: '🕵️',
    color: WqColors.sky,
  ),
];

// ---------------------------------------------------------------------------
// SpotMeScreen
// ---------------------------------------------------------------------------

/// Entry screen for the Spot Me If You Can land.
///
/// Displays a 3×3 grid of game cards; each card navigates to the
/// corresponding game screen.  Tracks the in-session completion count and
/// awards detective-title stickers at thresholds.
class SpotMeScreen extends ConsumerWidget {
  const SpotMeScreen({super.key});

  Widget _gameScreenFor(String id) {
    switch (id) {
      case 'hunt':
        return const HiddenObjectScreen();
      case 'socks':
        return const SocksScreen();
      case 'count':
        return const CountItScreen();
      case 'letter':
        return const LetterDetectiveScreen();
      case 'shape':
        return const ShapeSafariScreen();
      case 'animal':
        return const AnimalTrackerScreen();
      case 'diff':
        return const SpotDifferenceScreen();
      case 'color':
        return const ColorQuestScreen();
      case 'number':
        return const NumberDetectiveScreen();
      default:
        throw ArgumentError('Unknown game id: $id');
    }
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
          'Spot Me If You Can! ${Art.emoji('land-find')}',
          style: WqTheme.headingStyle(22),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pick a detective game!',
              style: WqTheme.headingStyle(18).copyWith(color: WqColors.softInk),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.3,
                children: _kCards.map((card) {
                  return _GameCard(
                    key: Key('game-${card.id}'),
                    spec: card,
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => _gameScreenFor(card.id),
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

// ---------------------------------------------------------------------------
// Game card tile
// ---------------------------------------------------------------------------

class _GameCard extends StatelessWidget {
  const _GameCard({
    super.key,
    required this.spec,
    required this.onTap,
  });

  final _CardSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: spec.color,
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(spec.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 4),
              Text(
                spec.title,
                maxLines: 2,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              Text(
                spec.sub,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
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
