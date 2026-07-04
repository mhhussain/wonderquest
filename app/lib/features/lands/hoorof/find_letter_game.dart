import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/arabic_letters.dart';
import '../../../core/save_controller.dart';
import '../../../domain/reward.dart';
import '../../../domain/spot_scene_engine.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/reward_modal.dart';
import '../../../widgets/spot_scene.dart';
import 'hoorof_utils.dart';

/// Hoorof — Game 5: Find the Letter.
///
/// 4 rounds: each round places the target Arabic glyph among same-family
/// look-alikes using [SpotScene]. On completing all rounds, marks the 4
/// target letters in `levels['hrf-find']` and shows the reward modal.
class FindLetterScreen extends ConsumerStatefulWidget {
  const FindLetterScreen({
    super.key,
    @visibleForTesting this.debugRounds,
  });

  /// Inject deterministic rounds for tests.
  @visibleForTesting
  final List<ArabicLetter>? debugRounds;

  @override
  ConsumerState<FindLetterScreen> createState() => _FindLetterScreenState();
}

class _FindLetterScreenState extends ConsumerState<FindLetterScreen> {
  static const _kRounds = 4;

  late List<ArabicLetter> _rounds;
  int _roundIdx = 0;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
  }

  void _initRounds() {
    if (widget.debugRounds != null) {
      _rounds = List<ArabicLetter>.from(widget.debugRounds!);
    } else {
      final pool = List<ArabicLetter>.from(kArabicLetters)..shuffle(Random());
      _rounds = pool.take(_kRounds).toList();
    }
    _roundIdx = 0;
    _completing = false;
  }

  /// Decoys for [letter]: same-family look-alikes + filler non-family letters.
  ///
  /// Family members are repeated twice to ensure they appear often enough.
  List<String> _decoys(ArabicLetter letter) {
    final fam = hrfFamily(letter.g);
    final extra = kArabicLetters
        .map((l) => l.g)
        .where((g) => g != letter.g && !fam.contains(g))
        .toList()
      ..shuffle(Random());
    return [...fam, ...extra.take(6), ...fam];
  }

  Future<void> _onRoundComplete() async {
    if (_completing) return;
    final next = _roundIdx + 1;
    if (next < _kRounds) {
      setState(() => _roundIdx = next);
      return;
    }
    _completing = true;

    for (final letter in _rounds) {
      final idx = kArabicLetters.indexWhere((l) => l.g == letter.g);
      if (idx >= 0) {
        await ref
            .read(saveControllerProvider.notifier)
            .markLevelDone('hrf-find', idx, kArabicLetters.length);
      }
    }
    if (!mounted) {
      _completing = false;
      return;
    }

    final levels = ref.read(saveControllerProvider).requireValue.levels;
    final pt = arabicProgressTo(levels);

    await showRewardModal(
      context,
      ref,
      Reward(
        stars: 3,
        xp: 28,
        egg: true,
        sticker: '🔎',
        progressKey: 'arabic',
        progressTo: pt,
      ),
      onPlayAgain: () {
        if (mounted) {
          setState(_initRounds);
        }
      },
    );
    if (mounted) Navigator.of(context).pop();
    _completing = false;
  }

  @override
  Widget build(BuildContext context) {
    final letter = _rounds[_roundIdx];

    return Scaffold(
      backgroundColor: WqColors.backgroundAlt,
      appBar: AppBar(
        backgroundColor: WqColors.backgroundAlt,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '🔎 Find the Letter (${_roundIdx + 1}/$_kRounds)',
          style: WqTheme.headingStyle(18),
        ),
      ),
      body: SpotScene(
        key: ValueKey('hrf-find-$_roundIdx'),
        goals: [
          SpotGoal(
            char: letter.g,
            count: 3 + (_roundIdx % 2),
            label: letter.tr,
          ),
        ],
        mode: SpotMode.find,
        decoys: _decoys(letter),
        decoyCount: 24,
        bg: WqColors.backgroundAlt,
        onComplete: _onRoundComplete,
      ),
    );
  }
}
