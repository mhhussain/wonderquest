import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/math_content.dart';
import '../../../core/art.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
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
                      (s) => _StationCard(
                        key: Key('station-${s.id}'),
                        station: s,
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

// ---------------------------------------------------------------------------
// Station card tile
// ---------------------------------------------------------------------------

class _StationCard extends StatelessWidget {
  const _StationCard({
    super.key,
    required this.station,
    required this.onTap,
  });

  final MathStation station;
  final VoidCallback onTap;

  String get _sub {
    switch (station.type) {
      case MathType.add:     return 'Adding';
      case MathType.sub:     return 'Taking away';
      case MathType.count:   return 'Counting';
      case MathType.compare: return 'More or less';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: station.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
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
              Text(station.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 6),
              Text(
                station.title,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Text(
                _sub,
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
