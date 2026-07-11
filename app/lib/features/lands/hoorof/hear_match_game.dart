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
import '../../../core/progress_keys.dart';

/// Hoorof — Game 3: Hear & Match.
///
/// 8 rounds: each round plays the Arabic letter name and presents 3 glyph
/// choices. The correct answer plus 2 distractors from the same confusable
/// family ([hrfFamily]) are shown. Correct tap advances; wrong tap flashes
/// red and resets.
///
/// All 8 target letters' indices are marked done in `levels['hrf-hear']`
/// upon completion.
class HearMatchScreen extends ConsumerStatefulWidget {
  const HearMatchScreen({
    super.key,
    @visibleForTesting this.debugRounds,
  });

  /// Inject deterministic rounds in tests (bypasses shuffle).
  @visibleForTesting
  final List<ArabicLetter>? debugRounds;

  @override
  ConsumerState<HearMatchScreen> createState() => _HearMatchScreenState();
}

class _HearMatchScreenState extends ConsumerState<HearMatchScreen> {
  static const _kRounds = 8;

  late List<ArabicLetter> _rounds;
  late List<List<String>> _options; // options[roundIdx]
  int _roundIdx = 0;
  String? _picked; // null = no pick yet
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
      _rounds = List<ArabicLetter>.from(widget.debugRounds!);
    } else {
      final pool = List<ArabicLetter>.from(kArabicLetters)..shuffle(Random());
      _rounds = pool.take(_kRounds).toList();
    }
    _options = _rounds.map(_buildOptions).toList();
    _scheduleSpeak(0);
  }

  /// Builds 3 options for [letter]: correct + 2 from the same confusable family.
  ///
  /// If the family has fewer than 2 other members, fills with random non-family
  /// letters.
  static List<String> _buildOptions(ArabicLetter letter) {
    final family = hrfFamily(letter.g);
    final shuffledFamily = List<String>.from(family)..shuffle(Random());
    final picks = <String>[];

    for (final f in shuffledFamily) {
      if (picks.length >= 2) break;
      picks.add(f);
    }

    // Fill remaining slots with non-family, non-target letters.
    if (picks.length < 2) {
      final extra = kArabicLetters
          .map((l) => l.g)
          .where((g) => g != letter.g && !picks.contains(g))
          .toList()
        ..shuffle(Random());
      for (final g in extra) {
        if (picks.length >= 2) break;
        picks.add(g);
      }
    }

    return ([letter.g, ...picks])..shuffle(Random());
  }

  void _scheduleSpeak(int idx) {
    if (idx >= _rounds.length) return;
    final letter = _rounds[idx];
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        unawaited(
          ref.read(ttsServiceProvider).speakArabic(letter.nm, letter.tr),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Choice handling
  // ---------------------------------------------------------------------------

  Future<void> _choose(String g) async {
    if (_picked != null) return; // already picked this round
    final correct = _rounds[_roundIdx].g;
    final ok = g == correct;
    setState(() => _picked = g);

    if (ok) {
      final letter = _rounds[_roundIdx];
      unawaited(ref.read(sfxServiceProvider).play(Sfx.ding));
      unawaited(
        ref.read(ttsServiceProvider).speakArabic(
          'أَحْسَنْت! ${letter.nm}',
          'Yes! ${letter.tr}',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;
      final next = _roundIdx + 1;
      if (next >= _rounds.length) {
        unawaited(_onComplete());
      } else {
        setState(() {
          _roundIdx = next;
          _picked = null;
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

    for (final letter in _rounds) {
      final idx = kArabicLetters.indexWhere((l) => l.g == letter.g);
      if (idx >= 0) {
        await ref
            .read(saveControllerProvider.notifier)
            .markLevelDone('hrf-hear', idx, kArabicLetters.length);
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
        stars: 4,
        xp: 28,
        egg: true,
        sticker: '🎧',
        progressKey: ProgressKeys.arabic,
        progressTo: pt,
      ),
      onPlayAgain: () {
        if (mounted) {
          setState(() {
            _roundIdx = 0;
            _picked = null;
            _completing = false;
          });
          _initRounds();
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
    final letter = _rounds[_roundIdx];
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
        title: Text('🎧 Hear & Match', style: WqTheme.headingStyle(20)),
        actions: [
          // Round progress dots
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_rounds.length, (k) {
                Color c;
                if (k < _roundIdx) {
                  c = WqColors.green;
                } else if (k == _roundIdx) {
                  c = WqColors.grape;
                } else {
                  c = WqColors.lines;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: c,
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruction
            Text(
              'Tap the letter you hear',
              textAlign: TextAlign.center,
              style: WqTheme.headingStyle(18).copyWith(color: WqColors.softInk),
            ),
            const SizedBox(height: 24),

            // Listen button
            Center(
              child: SizedBox(
                height: 72,
                width: 180,
                child: ElevatedButton.icon(
                  key: const Key('hear-listen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WqColors.grape,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                  ),
                  onPressed: () => unawaited(
                    ref.read(ttsServiceProvider).speakArabic(letter.nm, letter.tr),
                  ),
                  icon: const Text('🔊', style: TextStyle(fontSize: 24)),
                  label: Text(
                    'Listen',
                    style: WqTheme.headingStyle(20).copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // 3 glyph choice buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: options.map((g) {
                final isPicked = _picked == g;
                final isCorrect = g == letter.g;
                Color bg;
                if (isPicked && isCorrect) {
                  bg = WqColors.green;
                } else if (isPicked && !isCorrect) {
                  bg = WqColors.coral;
                } else {
                  bg = WqColors.backgroundAlt;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GestureDetector(
                    key: Key('hear-choice-$g'),
                    onTap: () => unawaited(_choose(g)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: WqColors.lines, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        g,
                        textDirection: TextDirection.rtl,
                        style: arabicGlyphStyle(
                          70,
                          color:
                              isPicked ? Colors.white : WqColors.teal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
