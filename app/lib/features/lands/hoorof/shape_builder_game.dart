import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/arabic_letters.dart';
import '../../../core/audio/sfx_service.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/save_controller.dart';
import '../../../domain/reward.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/reward_modal.dart';
import 'hoorof_utils.dart';

/// All legal dots codes. Used to generate wrong options.
const _kAllDotCodes = ['1a', '2a', '3a', '1b', '2b', '0'];

/// Hoorof — Game 6: Shape Builder.
///
/// Shows the dotless base form of a letter (e.g. ٮ for ب/ت/ث/ن); the player
/// picks the correct dots option (labeled in English). Correct choice animates
/// the base → full letter and speaks the name. 6 rounds drawn from letters
/// with a [ArabicLetter.base] defined.
class ShapeBuilderScreen extends ConsumerStatefulWidget {
  const ShapeBuilderScreen({
    super.key,
    @visibleForTesting this.debugRounds,
  });

  /// Inject deterministic rounds for tests (bypasses shuffle).
  @visibleForTesting
  final List<ArabicLetter>? debugRounds;

  @override
  ConsumerState<ShapeBuilderScreen> createState() =>
      _ShapeBuilderScreenState();
}

class _ShapeBuilderScreenState extends ConsumerState<ShapeBuilderScreen> {
  static const _kRounds = 6;

  late List<ArabicLetter> _dotted;
  late List<List<String>> _options; // options[roundIdx]
  int _roundIdx = 0;
  String? _picked; // null = no pick yet
  bool _done = false; // correct pick made → show full letter
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _initRounds();
  }

  // ---------------------------------------------------------------------------
  // Round setup
  // ---------------------------------------------------------------------------

  void _initRounds() {
    if (widget.debugRounds != null) {
      _dotted = List<ArabicLetter>.from(widget.debugRounds!);
    } else {
      final pool = kArabicLetters.where((l) => l.base != null).toList()
        ..shuffle(Random());
      _dotted = pool.take(_kRounds).toList();
    }
    _options = _dotted.map(_buildOptions).toList();
    _roundIdx = 0;
    _picked = null;
    _done = false;
    _completing = false;
    _scheduleSpeak(0);
  }

  /// Builds 3 option strings for [letter]: correct dots + 2 wrong.
  static List<String> _buildOptions(ArabicLetter letter) {
    final correct = letter.dots!;
    final wrong = _kAllDotCodes.where((d) => d != correct).toList()
      ..shuffle(Random());
    return ([correct, ...wrong.take(2)])..shuffle(Random());
  }

  void _scheduleSpeak(int idx) {
    if (idx >= _dotted.length) return;
    final letter = _dotted[idx];
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        unawaited(
          ref.read(ttsServiceProvider).speakArabic(
            'أَضِف النُّقَط لِتَصْنَع ${letter.nm}',
            'Add the dots to make ${letter.tr}',
          ),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Choice handling
  // ---------------------------------------------------------------------------

  Future<void> _choose(String d) async {
    if (_done || _picked == d) return;
    final letter = _dotted[_roundIdx];
    final correct = letter.dots!;
    final ok = d == correct;
    setState(() => _picked = d);

    if (ok) {
      unawaited(ref.read(sfxServiceProvider).play(Sfx.ding));
      unawaited(
        ref.read(ttsServiceProvider).speakArabic(letter.nm, letter.tr),
      );
      setState(() => _done = true);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      if (!mounted) return;
      final next = _roundIdx + 1;
      if (next >= _dotted.length) {
        unawaited(_onComplete());
      } else {
        setState(() {
          _roundIdx = next;
          _picked = null;
          _done = false;
        });
        _scheduleSpeak(next);
      }
    } else {
      unawaited(ref.read(sfxServiceProvider).play(Sfx.wrong));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _picked = null);
    }
  }

  // ---------------------------------------------------------------------------
  // Completion
  // ---------------------------------------------------------------------------

  Future<void> _onComplete() async {
    if (_completing) return;
    _completing = true;

    for (final letter in _dotted) {
      final idx = kArabicLetters.indexWhere((l) => l.g == letter.g);
      if (idx >= 0) {
        await ref
            .read(saveControllerProvider.notifier)
            .markLevelDone('hrf-build', idx, kArabicLetters.length);
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
        xp: 26,
        sticker: '🖍️',
        progressKey: 'arabic',
        progressTo: pt,
      ),
      onPlayAgain: () {
        if (mounted) {
          setState(_initRounds);
          _completing = false;
        }
      },
    );
    if (mounted) Navigator.of(context).pop();
    _completing = false;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final letter = _dotted[_roundIdx];
    final options = _options[_roundIdx];

    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('🖍️ Shape Builder', style: WqTheme.headingStyle(20)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_dotted.length, (k) {
                Color c;
                if (k < _roundIdx) {
                  c = WqColors.green;
                } else if (k == _roundIdx) {
                  c = WqColors.pink;
                } else {
                  c = WqColors.lines;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target instruction
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Make:  ',
                  style:
                      WqTheme.headingStyle(20).copyWith(color: WqColors.softInk),
                ),
                Text(
                  letter.tr,
                  style: WqTheme.headingStyle(22),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => unawaited(
                    ref.read(ttsServiceProvider).speakArabic(letter.nm, letter.tr),
                  ),
                  child: const Text('🔊', style: TextStyle(fontSize: 24)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Base → full letter stage (AnimatedSwitcher)
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  _done ? letter.g : letter.base!,
                  key: ValueKey(_done ? 'done' : 'base'),
                  textDirection: TextDirection.rtl,
                  style: arabicGlyphStyle(
                    160,
                    color: _done ? WqColors.green : WqColors.softInk,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 3 dot option buttons (labeled in English)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: options.map((d) {
                final isPick = _picked == d;
                final isCorrect = d == letter.dots!;
                Color bg;
                if (isPick && isCorrect) {
                  bg = WqColors.green;
                } else if (isPick && !isCorrect) {
                  bg = WqColors.coral;
                } else {
                  bg = WqColors.backgroundAlt;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    key: Key('build-opt-$d'),
                    onTap: () => unawaited(_choose(d)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 120,
                      constraints: const BoxConstraints(minHeight: 80),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: WqColors.lines, width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Visual preview: base with dot indicator
                          Text(
                            letter.base!,
                            textDirection: TextDirection.rtl,
                            style: arabicGlyphStyle(
                              28,
                              color:
                                  isPick ? Colors.white : WqColors.softInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dotLabel(d),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isPick ? Colors.white : WqColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
