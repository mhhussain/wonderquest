import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/arabic_letters.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/save_controller.dart';
import '../../../domain/reward.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/reward_modal.dart';
import 'hoorof_utils.dart';
import '../../../core/progress_keys.dart';

/// Hoorof — Game 1: Learn the Letter.
///
/// Flow: ClusterPicker → for each letter in the cluster, show the letter view
/// (giant tappable glyph + wobble + speak, example word). On completing all
/// letters in the cluster the game calls [showRewardModal] and marks the
/// letters in `levels['hrf-learn']`.
class LearnLetterScreen extends ConsumerStatefulWidget {
  const LearnLetterScreen({super.key});

  @override
  ConsumerState<LearnLetterScreen> createState() => _LearnLetterScreenState();
}

class _LearnLetterScreenState extends ConsumerState<LearnLetterScreen>
    with SingleTickerProviderStateMixin {
  List<String>? _cluster; // null = show ClusterPicker
  int _letterIdx = 0;
  bool _completing = false;

  // Wobble animation (damped rotation sequence on glyph tap)
  late final AnimationController _wobbleCtrl;
  late final Animation<double> _wobbleAnim;

  @override
  void initState() {
    super.initState();
    _wobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _wobbleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.18),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.18, end: -0.14),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.14, end: 0.08),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.08, end: -0.04),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.04, end: 0.0),
        weight: 30,
      ),
    ]).animate(_wobbleCtrl);
  }

  @override
  void dispose() {
    _wobbleCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Cluster selection
  // ---------------------------------------------------------------------------

  void _onPickCluster(List<String> letters) {
    setState(() {
      _cluster = letters;
      _letterIdx = 0;
    });
    _speakCurrent(letters[0]);
  }

  void _speakCurrent(String glyph) {
    final letter = kArabicLetters.firstWhere((l) => l.g == glyph);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        unawaited(
          ref
              .read(ttsServiceProvider)
              .speakArabic(letter.nm, letter.tr),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Game navigation
  // ---------------------------------------------------------------------------

  void _onTapGlyph() {
    _wobbleCtrl.forward(from: 0);
    final glyph = _cluster![_letterIdx];
    final letter = kArabicLetters.firstWhere((l) => l.g == glyph);
    unawaited(
      ref.read(ttsServiceProvider).speakArabic(letter.nm, letter.tr),
    );
  }

  void _onTapWord() {
    final glyph = _cluster![_letterIdx];
    final letter = kArabicLetters.firstWhere((l) => l.g == glyph);
    unawaited(
      ref.read(ttsServiceProvider).speakArabic(
        '${letter.nm}. ${letter.w}',
        '${letter.tr}. ${letter.wtr.split(' ').first}',
      ),
    );
  }

  void _onNext() {
    final cluster = _cluster!;
    final nextIdx = _letterIdx + 1;
    if (nextIdx >= cluster.length) {
      unawaited(_onComplete());
    } else {
      setState(() => _letterIdx = nextIdx);
      _speakCurrent(cluster[nextIdx]);
    }
  }

  // ---------------------------------------------------------------------------
  // Completion
  // ---------------------------------------------------------------------------

  Future<void> _onComplete() async {
    if (_completing) return;
    _completing = true;

    final cluster = _cluster!;

    // Mark each letter in the cluster as done for hrf-learn.
    for (final g in cluster) {
      final idx = kArabicLetters.indexWhere((l) => l.g == g);
      if (idx >= 0) {
        await ref
            .read(saveControllerProvider.notifier)
            .markLevelDone('hrf-learn', idx, kArabicLetters.length);
      }
    }
    if (!mounted) {
      _completing = false;
      return;
    }

    final levels =
        ref.read(saveControllerProvider).requireValue.levels;
    final pt = arabicProgressTo(levels);

    await showRewardModal(
      context,
      ref,
      Reward(
        stars: 3,
        xp: 20,
        sticker: '🔤',
        progressKey: ProgressKeys.arabic,
        progressTo: pt,
      ),
      onPlayAgain: () {
        if (mounted) _reset();
      },
    );
    if (mounted) _reset();
    _completing = false;
  }

  void _reset() {
    setState(() {
      _cluster = null;
      _letterIdx = 0;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_cluster == null) {
      return ClusterPicker(
        title: 'Learn the Letter',
        emoji: '🔤',
        color: WqColors.teal,
        onPick: _onPickCluster,
        onExit: () => Navigator.of(context).pop(),
      );
    }

    final cluster = _cluster!;
    final letter = kArabicLetters.firstWhere((l) => l.g == cluster[_letterIdx]);

    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: () => setState(() {
            _cluster = null;
          }),
        ),
        title: Text(
          '🔤 Learn the Letter',
          style: WqTheme.headingStyle(20),
        ),
        actions: [
          // Progress dots
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(cluster.length, (k) {
                Color dotColor;
                if (k < _letterIdx) {
                  dotColor = WqColors.green;
                } else if (k == _letterIdx) {
                  dotColor = WqColors.teal;
                } else {
                  dotColor = WqColors.lines;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Letter transliteration + sound button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${letter.tr}  ·  "${letter.snd}"',
                  style: WqTheme.headingStyle(22),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _onTapGlyph,
                  child: const Text(
                    '🔊',
                    style: TextStyle(fontSize: 28),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Giant tappable glyph
            Expanded(
              flex: 3,
              child: Center(
                child: GestureDetector(
                  onTap: _onTapGlyph,
                  child: AnimatedBuilder(
                    animation: _wobbleAnim,
                    builder: (_, child) => Transform.rotate(
                      angle: _wobbleAnim.value,
                      child: child,
                    ),
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: WqColors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: WqColors.teal.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter.g,
                        textDirection: TextDirection.rtl,
                        style: arabicGlyphStyle(140, color: WqColors.teal),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Example word card
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _onTapWord,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: WqColors.backgroundAlt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: WqColors.lines, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          letter.e,
                          style: const TextStyle(fontSize: 52),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                letter.w,
                                textDirection: TextDirection.rtl,
                                style: arabicGlyphStyle(30),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                letter.wtr,
                                style: WqTheme.body.copyWith(
                                  fontSize: 16,
                                  color: WqColors.softInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('🔊', style: TextStyle(fontSize: 22)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Next / Done button
            SizedBox(
              height: 64,
              child: ElevatedButton(
                key: const Key('learn-next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WqColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  textStyle: WqTheme.headingStyle(20).copyWith(
                    color: Colors.white,
                  ),
                ),
                onPressed: _onNext,
                child: Text(
                  _letterIdx + 1 >= cluster.length ? '✓ Done' : 'Next →',
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
