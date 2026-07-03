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

// ---------------------------------------------------------------------------
// DetectiveConfig — shared by Letter, Number, Shape detective games
// ---------------------------------------------------------------------------

/// Configuration for a single-target detective game.
///
/// Controls which round pool to draw from, display metadata, and the reward
/// payload.
class DetectiveConfig {
  const DetectiveConfig({
    required this.rounds,
    required this.title,
    required this.emoji,
    required this.color,
    required this.sticker,
    required this.xp,
    required this.progressTo,
  });

  /// The pool of rounds to shuffle and draw from.
  final List<DetectiveRound> rounds;

  /// Display title (e.g. 'Letter Detective').
  final String title;

  /// Leading emoji shown in the app bar.
  final String emoji;

  /// Primary color for the app bar and UI accents.
  final Color color;

  /// Sticker awarded on completion (unless a title sticker takes priority).
  final String sticker;

  /// XP awarded on completion.
  final int xp;

  /// Progress value to advance `find` progress bar to.
  final int progressTo;
}

// ---------------------------------------------------------------------------
// SingleFindScreen — generic single-target find game
// ---------------------------------------------------------------------------

/// Generic detective game: find all instances of one target character among
/// look-alike distractors.
///
/// Used for Letter Detective, Number Detective, and Shape Safari. Configured
/// via [DetectiveConfig].
///
/// Validates that the [DetectiveConfig.rounds] pool has no false positives
/// (target chars must not appear in their own decoy pool) — see tests.
class SingleFindScreen extends ConsumerStatefulWidget {
  const SingleFindScreen({super.key, required this.config});

  final DetectiveConfig config;

  @override
  ConsumerState<SingleFindScreen> createState() => _SingleFindScreenState();
}

class _SingleFindScreenState extends ConsumerState<SingleFindScreen> {
  late List<DetectiveRound> _rounds;
  int _roundIndex = 0;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
  }

  void _initRounds() {
    final rng = Random();
    _rounds = List<DetectiveRound>.from(widget.config.rounds)..shuffle(rng);
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

    final cfg = widget.config;

    await showRewardModal(
      context,
      ref,
      Reward(
        stars: 3,
        xp: cfg.xp,
        sticker: title ?? cfg.sticker,
        progressKey: 'find',
        progressTo: cfg.progressTo,
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
    final cfg = widget.config;

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
          '${cfg.emoji} ${cfg.title} '
          '(${_roundIndex + 1}/${_rounds.length})',
          style: WqTheme.headingStyle(18).copyWith(
            color: scene.dark ? WqColors.card : WqColors.ink,
          ),
        ),
      ),
      body: SpotScene(
        key: ValueKey('detective-$_roundIndex'),
        goals: [
          SpotGoal(
            char: round.target,
            count: round.n,
            label: round.label,
          ),
        ],
        mode: SpotMode.find,
        decoys: round.pool,
        decoyCount: 26,
        bg: scene.bg,
        onComplete: _onRoundComplete,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Concrete detective screens
// ---------------------------------------------------------------------------

/// Letter Detective: find all instances of a target letter among look-alikes.
class LetterDetectiveScreen extends StatelessWidget {
  const LetterDetectiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleFindScreen(
      config: DetectiveConfig(
        rounds: kLetterRounds,
        title: 'Letter Detective',
        emoji: '🔤',
        color: WqColors.orange,
        sticker: '🔤',
        xp: 28,
        progressTo: 55,
      ),
    );
  }
}

/// Number Detective: find all instances of a target digit.
class NumberDetectiveScreen extends StatelessWidget {
  const NumberDetectiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleFindScreen(
      config: DetectiveConfig(
        rounds: kNumberRounds,
        title: 'Number Detective',
        emoji: '🕵️',
        color: WqColors.sky,
        sticker: '🔢',
        xp: 28,
        progressTo: 50,
      ),
    );
  }
}

/// Shape Safari: find all instances of a target shape emoji.
class ShapeSafariScreen extends StatelessWidget {
  const ShapeSafariScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleFindScreen(
      config: DetectiveConfig(
        rounds: kShapeRounds,
        title: 'Shape Safari',
        emoji: '🔺',
        color: WqColors.grape,
        sticker: '🔺',
        xp: 26,
        progressTo: 50,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Color Quest
// ---------------------------------------------------------------------------

/// Color Quest: find all objects of a target color across shuffled rounds.
///
/// Each round picks N items from the target color group as individual goals
/// (each with count=1). All items from other color groups become decoys.
class ColorQuestScreen extends ConsumerStatefulWidget {
  const ColorQuestScreen({super.key});

  @override
  ConsumerState<ColorQuestScreen> createState() => _ColorQuestScreenState();
}

class _ColorQuestScreenState extends ConsumerState<ColorQuestScreen> {
  late List<ColorQuestRound> _rounds;
  late List<List<SpotGoal>> _goals; // goals[roundIdx]
  int _roundIndex = 0;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
  }

  void _initRounds() {
    final rng = Random();
    _rounds = List<ColorQuestRound>.from(kColorRounds)..shuffle(rng);

    _goals = _rounds.map((r) {
      final grp = kColorGroups[r.target]!;
      final shuffledItems = List<String>.from(grp.items)..shuffle(rng);
      return shuffledItems
          .take(r.n)
          .map(
            (item) => SpotGoal(char: item, count: 1, label: grp.label),
          )
          .toList();
    }).toList();
  }

  /// Decoys are all items from color groups OTHER than the target.
  List<String> _decoysFor(int roundIdx) {
    final target = _rounds[roundIdx].target;
    return kColorGroups.entries
        .where((e) => e.key != target)
        .expand((e) => e.value.items)
        .toList();
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
        sticker: title ?? '🎨',
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
    final goals = _goals[_roundIndex];
    final grp = kColorGroups[round.target]!;

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
        title: Row(
          children: [
            Text(
              '🎨 Color Quest — find ${grp.label} things '
              '(${_roundIndex + 1}/${_rounds.length})',
              style: WqTheme.headingStyle(16).copyWith(
                color: scene.dark ? WqColors.card : WqColors.ink,
              ),
            ),
          ],
        ),
      ),
      body: SpotScene(
        key: ValueKey('color-$_roundIndex'),
        goals: goals,
        mode: SpotMode.find,
        decoys: _decoysFor(_roundIndex),
        decoyCount: 20,
        bg: scene.bg,
        onComplete: _onRoundComplete,
      ),
    );
  }
}
