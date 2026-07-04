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

/// Desert / oasis deco glyphs for the safari scene background.
const _kSafariDeco = [
  '🌴',
  '🐪',
  '🏜️',
  '⛺',
  '🌵',
  '🪨',
  '☀️',
  '🐫',
  '🧺',
  '🫖',
];

/// Safari round pool: 6 common letters used as targets.
const _kSafariPool = ['ا', 'ب', 'م', 'ل', 'س', 'ت'];

/// Desert background color (sand tone).
const _kSandBg = Color(0xFFF2D98C);

/// Hoorof — Game 8: Safari Letter Hunt.
///
/// 3 rounds of [SpotScene] with a desert / oasis theme (sand background,
/// palm / cactus deco). Target letters are drawn from common Arabic letters;
/// decoys are same-family look-alikes mixed with desert deco.
class SafariHuntScreen extends ConsumerStatefulWidget {
  const SafariHuntScreen({super.key});

  @override
  ConsumerState<SafariHuntScreen> createState() => _SafariHuntScreenState();
}

class _SafariHuntScreenState extends ConsumerState<SafariHuntScreen> {
  static const _kRounds = 3;

  late List<ArabicLetter> _rounds;
  int _roundIdx = 0;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
  }

  void _initRounds() {
    final glyphs = List<String>.from(_kSafariPool)..shuffle(Random());
    _rounds = glyphs
        .take(_kRounds)
        .map((g) => kArabicLetters.firstWhere((l) => l.g == g))
        .toList();
    _roundIdx = 0;
    _completing = false;
  }

  /// Decoys for [letter]: same family + desert deco glyphs.
  List<String> _decoys(ArabicLetter letter) {
    final fam = hrfFamily(letter.g);
    return [...fam, ..._kSafariDeco, ...fam];
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
            .markLevelDone('hrf-safari', idx, kArabicLetters.length);
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
        xp: 30,
        egg: true,
        sticker: '🐪',
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
      backgroundColor: _kSandBg,
      appBar: AppBar(
        backgroundColor: _kSandBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '🐪 Safari Letter Hunt (${_roundIdx + 1}/$_kRounds)',
          style: WqTheme.headingStyle(18),
        ),
      ),
      body: SpotScene(
        key: ValueKey('hrf-safari-$_roundIdx'),
        goals: [
          SpotGoal(
            char: letter.g,
            count: 3,
            label: letter.tr,
          ),
        ],
        mode: SpotMode.find,
        decoys: _decoys(letter),
        decoyCount: 22,
        bg: _kSandBg,
        deco: _kSafariDeco,
        onComplete: _onRoundComplete,
      ),
    );
  }
}
