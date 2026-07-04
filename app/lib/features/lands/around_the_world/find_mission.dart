import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/world_content.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/save_controller.dart';
import '../../../domain/reward.dart';
import '../../../domain/spot_scene_engine.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/reward_modal.dart';
import '../../../widgets/spot_scene.dart';

// ---------------------------------------------------------------------------
// FindMissionScreen
// ---------------------------------------------------------------------------

/// Hidden-discovery find mission using [SpotScene].
///
/// Targets are the continent's mission emoji; decoys are drawn from the
/// continent's other animals plus scenery.
class FindMissionScreen extends ConsumerStatefulWidget {
  const FindMissionScreen({
    super.key,
    required this.continent,
    required this.onBack,
    required this.onComplete,
  });

  final Continent continent;
  final VoidCallback onBack;

  /// Called after the reward modal is dismissed.
  final VoidCallback onComplete;

  @override
  ConsumerState<FindMissionScreen> createState() => _FindMissionScreenState();
}

class _FindMissionScreenState extends ConsumerState<FindMissionScreen> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final m = widget.continent.mission;
      ref
          .read(ttsServiceProvider)
          .speak('Find ${m.count} ${m.n}!');
    });
  }

  Future<void> _onComplete() async {
    if (_done) return;
    _done = true;

    final c = widget.continent;

    // Grant stamp + wonder card (matches prototype missionDone logic).
    await ref.read(saveControllerProvider.notifier).visitContinent(c.id);
    await ref.read(saveControllerProvider.notifier).collectWonderCard(c.id);

    if (!mounted) return;

    // Compute progress after marking this continent visited.
    final visited =
        ref.read(saveControllerProvider).value?.world.visited ?? {};
    final progressTo =
        ((visited.length / 7) * 100).round().clamp(0, 100);

    await showRewardModal(
      context,
      ref,
      Reward(
        stars: 5,
        xp: 60,
        egg: true,
        sticker: c.badge,
        progressKey: 'world',
        progressTo: progressTo,
      ),
    );

    if (mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.continent;
    final m = c.mission;

    // Decoy pool: all continent animal emojis except the target, plus scenery
    final decoys = [
      ...c.animals
          .map((a) => a.emoji)
          .where((e) => e != m.find),
      '🌳', '🌴', '🪨', '🌾', '🌸', '⛰️', '🌵', '🍃', '🪵', '🌿',
    ];

    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        leading: IconButton(
          key: const Key('find-mission-back'),
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: widget.onBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔍 Hidden Discovery', style: WqTheme.headingStyle(20)),
            Text(
              'Find all the ${m.find} ${m.n}!',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: WqColors.softInk,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              c.color2.withValues(alpha: 0.2),
              c.color.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SpotScene(
          goals: [SpotGoal(char: m.find, count: m.count, label: m.n)],
          mode: SpotMode.find,
          decoys: decoys,
          decoyCount: 20,
          bg: c.color2.withValues(alpha: 0.15),
          onComplete: _onComplete,
        ),
      ),
    );
  }
}
