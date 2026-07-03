import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/spot_scenes_content.dart';
import '../../../domain/reward.dart';
import '../../../domain/spot_scene_engine.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/reward_modal.dart';
import '../../../widgets/spot_scene.dart';
import 'spot_me_screen.dart';

/// Count It If You Can: presents SpotScene in [SpotMode.count] mode.
///
/// Each round picks a random count (3–8) for the target emoji and drops it
/// into a busy scene. The child taps each instance to build a tally; items
/// get numbered badges when found. Five shuffled rounds → reward modal.
class CountItScreen extends ConsumerStatefulWidget {
  const CountItScreen({super.key});

  @override
  ConsumerState<CountItScreen> createState() => _CountItScreenState();
}

class _CountItScreenState extends ConsumerState<CountItScreen> {
  late List<SpotCountRound> _rounds;
  late List<int> _counts; // one random count per round
  int _roundIndex = 0;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
  }

  void _initRounds() {
    final rng = Random();
    _rounds = List<SpotCountRound>.from(kSpotCountRounds)..shuffle(rng);
    _rounds = _rounds.take(5).toList();
    // Choose a random count (3–8) for each round.
    _counts = List.generate(_rounds.length, (_) => 3 + rng.nextInt(6));
  }

  Future<void> _onRoundComplete() async {
    if (_animating) return;
    _animating = true;

    if (_roundIndex + 1 < _rounds.length) {
      setState(() {
        _roundIndex++;
        _animating = false;
      });
      return;
    }

    final count = ref
        .read(spotMeSessionCountProvider.notifier)
        .increment();
    final title = detectiveTitleForCount(count);

    if (!mounted) {
      _animating = false;
      return;
    }

    await showRewardModal(
      context,
      ref,
      Reward(
        stars: 3,
        xp: 26,
        sticker: title ?? '🔢',
        progressKey: 'find',
        progressTo: 50,
      ),
      onPlayAgain: () {
        if (mounted) {
          setState(() {
            _roundIndex = 0;
            _animating = false;
            _initRounds();
          });
        }
      },
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_roundIndex];
    final scene = kSceneMap[round.sceneKey]!;
    final n = _counts[_roundIndex];

    return Scaffold(
      backgroundColor: scene.bg,
      appBar: AppBar(
        backgroundColor: scene.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: scene.dark ? WqColors.card : WqColors.ink,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '🔢 Count It (${_roundIndex + 1}/${_rounds.length})',
          style: WqTheme.headingStyle(20).copyWith(
            color: scene.dark ? WqColors.card : WqColors.ink,
          ),
        ),
      ),
      body: SpotScene(
        key: ValueKey('count-$_roundIndex-$n'),
        goals: [SpotGoal(char: round.char, count: n, label: round.label)],
        mode: SpotMode.count,
        decoys: round.deco,
        decoyCount: 20,
        bg: scene.bg,
        onComplete: _onRoundComplete,
      ),
    );
  }
}
