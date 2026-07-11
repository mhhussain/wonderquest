import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/math_content.dart';
import '../../../core/art.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/land_game_card.dart';
import 'math_station_game.dart';

/// Entry screen for Little Math Lab — shows the 6 themed station cards.
///
/// Each card navigates to [MathStationScreen] which manages the
/// LevelSelect (4 games) → GameDeck (10 questions) → Reward cycle.
class MathLabScreen extends ConsumerWidget {
  const MathLabScreen({super.key});

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
          'Little Math Lab ${Art.emoji('land-math')}',
          style: WqTheme.headingStyle(24),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pick a station!',
              style: WqTheme.headingStyle(20).copyWith(color: WqColors.softInk),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: kMathStations
                    .map(
                      (s) => LandGameCard(
                        key: Key('station-${s.id}'),
                        title: s.title,
                        subtitle: _stationSub(s),
                        icon: s.emoji,
                        color: s.color,
                        iconSize: 36,
                        titleSize: 16,
                        subtitleSize: 12,
                        radius: 20,
                        padding: 14,
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => MathStationScreen(station: s),
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

/// Subtitle line for a station card, from its math type.
String _stationSub(MathStation station) {
  switch (station.type) {
    case MathType.add:     return 'Adding';
    case MathType.sub:     return 'Taking away';
    case MathType.count:   return 'Counting';
    case MathType.compare: return 'More or less';
  }
}
