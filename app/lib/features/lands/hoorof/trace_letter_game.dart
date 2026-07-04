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
import '../../../widgets/trace_canvas.dart';
import 'hoorof_utils.dart';

/// Hoorof — Game 2: Trace the Letter.
///
/// Flow: ClusterPicker → for each letter in the cluster, show a [TraceCanvas]
/// using the NotoNaskhArabic font. Covering the guide fires a sparkle/confetti
/// (built into TraceCanvas) and unlocks the "Great!" button. Completing all
/// letters in the cluster triggers [showRewardModal].
class TraceLetterScreen extends ConsumerStatefulWidget {
  const TraceLetterScreen({super.key});

  @override
  ConsumerState<TraceLetterScreen> createState() => _TraceLetterScreenState();
}

class _TraceLetterScreenState extends ConsumerState<TraceLetterScreen> {
  List<String>? _cluster; // null = ClusterPicker
  int _letterIdx = 0;
  int _resetKey = 0;
  bool _covered = false;
  bool _completing = false;

  // ---------------------------------------------------------------------------
  // Cluster selection
  // ---------------------------------------------------------------------------

  void _onPickCluster(List<String> letters) {
    setState(() {
      _cluster = letters;
      _letterIdx = 0;
      _resetKey = 0;
      _covered = false;
    });
    _speakTrace(letters[0]);
  }

  void _speakTrace(String glyph) {
    final letter = kArabicLetters.firstWhere((l) => l.g == glyph);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        unawaited(
          ref.read(ttsServiceProvider).speakArabic(
            'اِرْسُم ${letter.nm}',
            'Trace ${letter.tr}',
          ),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Tracing callbacks
  // ---------------------------------------------------------------------------

  void _onCovered() {
    if (_covered) return;
    setState(() => _covered = true);

    final letter =
        kArabicLetters.firstWhere((l) => l.g == _cluster![_letterIdx]);
    unawaited(
      ref.read(ttsServiceProvider).speakArabic(letter.nm, letter.tr),
    );
  }

  void _onRestart() {
    setState(() {
      _resetKey++;
      _covered = false;
    });
  }

  void _onNext() {
    final cluster = _cluster!;
    final nextIdx = _letterIdx + 1;
    if (nextIdx >= cluster.length) {
      unawaited(_onComplete());
    } else {
      setState(() {
        _letterIdx = nextIdx;
        _resetKey = 0;
        _covered = false;
      });
      _speakTrace(cluster[nextIdx]);
    }
  }

  // ---------------------------------------------------------------------------
  // Completion
  // ---------------------------------------------------------------------------

  Future<void> _onComplete() async {
    if (_completing) return;
    _completing = true;

    final cluster = _cluster!;

    for (final g in cluster) {
      final idx = kArabicLetters.indexWhere((l) => l.g == g);
      if (idx >= 0) {
        await ref
            .read(saveControllerProvider.notifier)
            .markLevelDone('hrf-trace', idx, kArabicLetters.length);
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
        xp: 22,
        sticker: '✏️',
        progressKey: 'arabic',
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
      _resetKey = 0;
      _covered = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_cluster == null) {
      return ClusterPicker(
        title: 'Trace the Letter',
        emoji: '✏️',
        color: WqColors.green,
        onPick: _onPickCluster,
        onExit: () => Navigator.of(context).pop(),
      );
    }

    final cluster = _cluster!;
    final letter =
        kArabicLetters.firstWhere((l) => l.g == cluster[_letterIdx]);

    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: () => setState(() => _cluster = null),
        ),
        title: Text('✏️ Trace the Letter', style: WqTheme.headingStyle(20)),
        actions: [
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
            // Letter name + 🔊 button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(letter.tr, style: WqTheme.headingStyle(22)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => unawaited(
                    ref
                        .read(ttsServiceProvider)
                        .speakArabic(letter.nm, letter.tr),
                  ),
                  child: const Text('🔊', style: TextStyle(fontSize: 28)),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // TraceCanvas (Arabic font, NotoNaskhArabic)
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TraceCanvas(
                      key: ValueKey('hrf-trace-$_resetKey'),
                      glyph: letter.g,
                      fontFamily: 'NotoNaskhArabic',
                      onCovered: _onCovered,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Try again + Great! buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: OutlinedButton.icon(
                      key: const Key('trace-restart'),
                      onPressed: _onRestart,
                      icon: const Text('↺', style: TextStyle(fontSize: 20)),
                      label: const Text(
                        'Try again',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: WqColors.ink,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: WqColors.lines, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: ElevatedButton(
                      key: const Key('trace-next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _covered ? WqColors.green : WqColors.lines,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        textStyle: WqTheme.headingStyle(18).copyWith(
                          color: Colors.white,
                        ),
                      ),
                      onPressed: _covered ? _onNext : null,
                      child: Text(
                        _covered
                            ? (_letterIdx + 1 >= cluster.length
                                ? '✓ Done!'
                                : '✓ Great!')
                            : '… Trace the letter',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
