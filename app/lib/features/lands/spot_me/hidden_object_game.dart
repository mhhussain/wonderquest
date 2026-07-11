import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/spot_scenes_content.dart';
import '../../../core/art.dart';
import '../../../domain/reward.dart';
import '../../../domain/spot_scene_engine.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/reward_modal.dart';
import '../../../widgets/spot_scene.dart';
import 'spot_me_screen.dart';
import '../../../core/progress_keys.dart';

// ---------------------------------------------------------------------------
// Hidden Object Hunt
// ---------------------------------------------------------------------------

/// Hidden Object Hunt: multi-goal SpotScene rounds in sequence.
///
/// Shuffles [kHuntRounds], picks 4, runs SpotScene for each. Scene decoys are
/// the scene's ambient deco list minus any chars used as targets.  On the
/// last round's completion the reward modal is shown and the screen pops.
class HiddenObjectScreen extends ConsumerStatefulWidget {
  const HiddenObjectScreen({super.key});

  @override
  ConsumerState<HiddenObjectScreen> createState() => _HiddenObjectScreenState();
}

class _HiddenObjectScreenState extends ConsumerState<HiddenObjectScreen> {
  late List<HuntRound> _rounds;
  int _roundIndex = 0;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
  }

  void _initRounds() {
    final rng = Random();
    _rounds = List<HuntRound>.from(kHuntRounds)..shuffle(rng);
    _rounds = _rounds.take(4).toList();
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

    // All rounds done.
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
        xp: 30,
        egg: true,
        sticker: title ?? '🔍',
        progressKey: ProgressKeys.find,
        progressTo: 60,
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
    final targetChars = round.goals.map((g) => g.char).toSet();
    final decoys =
        scene.deco.where((d) => !targetChars.contains(d)).toList();

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
          '${Art.emoji('land-find')} Hidden Hunt '
          '(${_roundIndex + 1}/${_rounds.length})',
          style: WqTheme.headingStyle(20).copyWith(
            color: scene.dark ? WqColors.card : WqColors.ink,
          ),
        ),
      ),
      body: SpotScene(
        key: ValueKey('hunt-$_roundIndex'),
        goals: round.goals,
        mode: SpotMode.find,
        decoys: decoys,
        decoyCount: 28,
        bg: scene.bg,
        onComplete: _onRoundComplete,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animal Tracker
// ---------------------------------------------------------------------------

/// Animal Tracker: like Hidden Object Hunt but uses [kAnimalRounds] (3
/// scenes, each with 4 animal types as goals).
class AnimalTrackerScreen extends ConsumerStatefulWidget {
  const AnimalTrackerScreen({super.key});

  @override
  ConsumerState<AnimalTrackerScreen> createState() =>
      _AnimalTrackerScreenState();
}

class _AnimalTrackerScreenState extends ConsumerState<AnimalTrackerScreen> {
  late List<HuntRound> _rounds;
  int _roundIndex = 0;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
  }

  void _initRounds() {
    final rng = Random();
    _rounds = List<HuntRound>.from(kAnimalRounds)..shuffle(rng);
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
        xp: 28,
        egg: true,
        sticker: title ?? '🐾',
        progressKey: ProgressKeys.find,
        progressTo: 55,
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
    final targetChars = round.goals.map((g) => g.char).toSet();
    final decoys = [
      ...round.extraDeco,
      ...scene.deco.where((d) => !targetChars.contains(d)),
    ];

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
          '🐾 Animal Tracker (${_roundIndex + 1}/${_rounds.length})',
          style: WqTheme.headingStyle(20).copyWith(
            color: scene.dark ? WqColors.card : WqColors.ink,
          ),
        ),
      ),
      body: SpotScene(
        key: ValueKey('animal-$_roundIndex'),
        goals: round.goals,
        mode: SpotMode.find,
        decoys: decoys,
        decoyCount: 22,
        bg: scene.bg,
        onComplete: _onRoundComplete,
      ),
    );
  }
}

