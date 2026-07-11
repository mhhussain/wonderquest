import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import 'ocean_facts_game.dart';
import 'whale_world_screen.dart';

// ---------------------------------------------------------------------------
// Sub-menu spec
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
    id: 'facts',
    title: 'Ocean Facts',
    sub: 'Amazing sea creatures',
    emoji: '🫧',
    color: WqColors.sky,
  ),
  _GameSpec(
    id: 'whales',
    title: 'Whale World',
    sub: 'Calls, dives & more',
    emoji: '🐋',
    color: WqColors.teal,
  ),
];

// ---------------------------------------------------------------------------
// UnderTheSeaScreen
// ---------------------------------------------------------------------------

/// Sub-menu for Under the Sea: Ocean Facts and Whale World.
class UnderTheSeaScreen extends ConsumerWidget {
  const UnderTheSeaScreen({super.key});

  Widget _screenFor(String id) {
    switch (id) {
      case 'facts':
        return const OceanFactsScreen();
      case 'whales':
        return const WhaleWorldScreen();
      default:
        throw ArgumentError('Unknown sub-game id: $id');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: WqColors.sky.withValues(alpha: 0.08),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Under the Sea 🌊', style: WqTheme.headingStyle(22)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dive in to meet amazing ocean animals!',
              style: WqTheme.headingStyle(18).copyWith(color: WqColors.softInk),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.4,
                children: _kGames
                    .map(
                      (spec) => _SeaCard(
                        key: Key('sea-game-${spec.id}'),
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
// Sea card tile
// ---------------------------------------------------------------------------

class _SeaCard extends StatelessWidget {
  const _SeaCard({super.key, required this.spec, required this.onTap});

  final _GameSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: spec.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: WqColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(spec.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 8),
              Text(
                spec.title,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              Text(
                spec.sub,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
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
