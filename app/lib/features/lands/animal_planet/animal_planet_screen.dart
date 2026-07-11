import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/art.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import 'animal_homes_game.dart';
import 'fun_facts_game.dart';
import 'under_the_sea_screen.dart';

// ---------------------------------------------------------------------------
// Picker card spec
// ---------------------------------------------------------------------------

class _GameSpec {
  final String id;
  final String title;
  final String sub;
  final String emoji;
  final Color color;

  const _GameSpec({
    required this.id,
    required this.title,
    required this.sub,
    required this.emoji,
    required this.color,
  });
}

const _kGames = <_GameSpec>[
  _GameSpec(
    id: 'homes',
    title: 'Animal Homes',
    sub: 'Sort by habitat',
    emoji: '🏡',
    color: WqColors.green,
  ),
  _GameSpec(
    id: 'facts',
    title: 'Fun Facts',
    sub: 'Discover & collect',
    emoji: '💡',
    color: WqColors.pink,
  ),
  _GameSpec(
    id: 'sea',
    title: 'Under the Sea',
    sub: 'Ocean animals & whales',
    emoji: '🌊',
    color: WqColors.sky,
  ),
];

// ---------------------------------------------------------------------------
// AnimalPlanetScreen
// ---------------------------------------------------------------------------

/// Entry screen for Amazing Animal Planet — shows the 3 themed game cards.
class AnimalPlanetScreen extends ConsumerWidget {
  const AnimalPlanetScreen({super.key});

  Widget _screenFor(String id) {
    switch (id) {
      case 'homes':
        return const AnimalHomesScreen();
      case 'facts':
        return const FunFactsScreen();
      case 'sea':
        return const UnderTheSeaScreen();
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
          'Amazing Animal Planet ${Art.emoji('land-animal')}',
          style: WqTheme.headingStyle(22),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Meet animals and learn where they live!',
              style: WqTheme.headingStyle(18).copyWith(color: WqColors.softInk),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: _kGames
                    .map(
                      (spec) => _GameCard(
                        key: Key('game-${spec.id}'),
                        spec: spec,
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => _screenFor(spec.id),
                          ),
                        ),
                      ),
                    )
                    .toList(),
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
  const _GameCard({super.key, required this.spec, required this.onTap});

  final _GameSpec spec;
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(spec.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 6),
              Text(
                spec.title,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Text(
                spec.sub,
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
