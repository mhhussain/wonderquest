import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

// ---------------------------------------------------------------------------
// Balloon model
// ---------------------------------------------------------------------------

@immutable
class _Balloon {
  const _Balloon({
    required this.id,
    required this.glyph,
    required this.left,
    required this.color,
    required this.spawnMs,
    required this.durationMs,
  });

  final int id;
  final String glyph;

  /// Horizontal position as a fraction of screen width [0.06, 0.90].
  final double left;
  final Color color;

  /// Elapsed milliseconds at spawn time.
  final int spawnMs;

  /// Milliseconds the balloon takes to float from bottom to off-top.
  final int durationMs;

  /// Progress from 0 (just spawned, at bottom) to 1.0 (off-top, should remove).
  double progress(int elapsedMs) =>
      ((elapsedMs - spawnMs) / durationMs).clamp(0.0, 1.5);
}

const _kBalloonColors = [
  WqColors.orange,
  WqColors.teal,
  WqColors.green,
  WqColors.coral,
  WqColors.grape,
  WqColors.sky,
  WqColors.pink,
  WqColors.yellow,
];

// ---------------------------------------------------------------------------
// LetterPopScreen
// ---------------------------------------------------------------------------

/// Hoorof — Game 7: Letter Pop.
///
/// Arabic letter balloons float upward using a [Ticker]. The player pops the
/// balloon matching the announced target letter. After [_kGoal] correct pops
/// the game completes. Wrong taps remove the balloon and play [Sfx.wrong].
/// The target changes every 2 correct pops.
class LetterPopScreen extends ConsumerStatefulWidget {
  const LetterPopScreen({super.key, this.random});

  /// Injectable RNG for deterministic tests; defaults to an unseeded [Random].
  final Random? random;

  @override
  ConsumerState<LetterPopScreen> createState() => _LetterPopScreenState();
}

class _LetterPopScreenState extends ConsumerState<LetterPopScreen>
    with SingleTickerProviderStateMixin {
  static const _kGoal = 6;
  static const _kMaxBalloons = 7;
  static const _kSpawnIntervalMs = 850;

  late Ticker _ticker;
  late final Random _rng = widget.random ?? Random();
  int _elapsedMs = 0;
  int _lastSpawnMs = -_kSpawnIntervalMs; // force immediate first spawn

  final List<_Balloon> _balloons = [];
  int _nextId = 0;

  late ArabicLetter _target;
  int _score = 0;
  bool _won = false;
  bool _completing = false;

  final Set<String> _poppedGlyphs = {};

  @override
  void initState() {
    super.initState();
    _target = kArabicLetters[_rng.nextInt(kArabicLetters.length)];
    _ticker = createTicker(_onTick)..start();
    _scheduleSpeak();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _scheduleSpeak() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        unawaited(
          ref.read(ttsServiceProvider).speakArabic(
            'جِد ${_target.nm}',
            'Find ${_target.tr}',
          ),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Ticker callback
  // ---------------------------------------------------------------------------

  void _onTick(Duration elapsed) {
    if (!mounted || _won) return;
    _elapsedMs = elapsed.inMilliseconds;

    // Spawn new balloon if enough time passed and not at cap.
    if (_elapsedMs - _lastSpawnMs >= _kSpawnIntervalMs &&
        _balloons.length < _kMaxBalloons) {
      _spawnBalloon();
      _lastSpawnMs = _elapsedMs;
    }

    // Remove balloons that have floated off-screen (progress ≥ 1.0).
    _balloons.removeWhere((b) => b.progress(_elapsedMs) >= 1.0);

    if (mounted) setState(() {});
  }

  void _spawnBalloon() {
    final isTarget = _rng.nextDouble() < 0.42;
    final glyph = isTarget
        ? _target.g
        : kArabicLetters
            .where((l) => l.g != _target.g)
            .toList()[_rng.nextInt(kArabicLetters.length - 1)]
            .g;

    _balloons.add(_Balloon(
      id: _nextId++,
      glyph: glyph,
      left: 0.06 + _rng.nextDouble() * 0.84,
      color: _kBalloonColors[_nextId % _kBalloonColors.length],
      spawnMs: _elapsedMs,
      durationMs: 6000 + _rng.nextInt(3000),
    ));
  }

  // ---------------------------------------------------------------------------
  // Tap handling
  // ---------------------------------------------------------------------------

  void _onTap(_Balloon b) {
    if (_won) return;

    _balloons.removeWhere((x) => x.id == b.id);

    if (b.glyph == _target.g) {
      // Correct!
      _score++;
      _poppedGlyphs.add(b.glyph);
      unawaited(ref.read(sfxServiceProvider).play(Sfx.pop));

      if (_score >= _kGoal && !_won) {
        _won = true;
        Future.delayed(
          const Duration(milliseconds: 600),
          () {
            if (mounted) unawaited(_onComplete());
          },
        );
      } else if (_score % 2 == 0) {
        // Change target every 2 correct pops.
        final pool = kArabicLetters.where((l) => l.g != _target.g).toList();
        _target = pool[_rng.nextInt(pool.length)];
        _scheduleSpeak();
      }
    } else {
      // Wrong tap.
      unawaited(ref.read(sfxServiceProvider).play(Sfx.wrong));
      unawaited(
        ref.read(ttsServiceProvider).speakArabic(
          'لا، حاوِل مَرَّة أُخْرَى',
          'No, try again',
        ),
      );
    }

    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Completion
  // ---------------------------------------------------------------------------

  Future<void> _onComplete() async {
    if (_completing) return;
    _completing = true;
    _ticker.stop();

    for (final g in _poppedGlyphs) {
      final idx = kArabicLetters.indexWhere((l) => l.g == g);
      if (idx >= 0) {
        await ref
            .read(saveControllerProvider.notifier)
            .markLevelDone('hrf-pop', idx, kArabicLetters.length);
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
        xp: 30,
        egg: true,
        sticker: '🎈',
        progressKey: ProgressKeys.arabic,
        progressTo: pt,
      ),
      onPlayAgain: () {
        if (mounted) {
          setState(() {
            _balloons.clear();
            _score = 0;
            _won = false;
            _poppedGlyphs.clear();
            _elapsedMs = 0;
            _lastSpawnMs = -_kSpawnIntervalMs;
            _target =
                kArabicLetters[_rng.nextInt(kArabicLetters.length)];
            _completing = false;
          });
          _ticker
            ..stop()
            ..start();
          _scheduleSpeak();
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
    return Scaffold(
      backgroundColor: WqColors.skyTint,
      appBar: AppBar(
        backgroundColor: WqColors.skyTint,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('🎈 Letter Pop', style: WqTheme.headingStyle(20)),
        actions: [
          // Target display
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Find  ',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    color: WqColors.softInk,
                  ),
                ),
                Text(
                  _target.g,
                  textDirection: TextDirection.rtl,
                  style: arabicGlyphStyle(32),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _scheduleSpeak,
                  child: const Text('🔊', style: TextStyle(fontSize: 20)),
                ),
              ],
            ),
          ),
          // Score counter
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: WqColors.coral,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🎈 $_score/$_kGoal',
                  style: WqTheme.headingStyle(16).copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final w = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Balloons
              ..._balloons.map((b) {
                const balloonH = 80.0;
                final progress = b.progress(_elapsedMs);
                final top = h - progress * (h + balloonH + 40) - balloonH / 2;
                final left = b.left * w - 36;

                return Positioned(
                  key: ValueKey('balloon-${b.id}'),
                  left: left,
                  top: top,
                  child: GestureDetector(
                    onTapUp: (_) => _onTap(b),
                    child: _BalloonWidget(
                      glyph: b.glyph,
                      color: b.color,
                      isTarget: b.glyph == _target.g,
                    ),
                  ),
                );
              }),

              // Hint at bottom
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Text(
                  '🎈 Pop the correct balloon before it floats away!',
                  textAlign: TextAlign.center,
                  style: WqTheme.body.copyWith(
                    fontSize: 15,
                    color: WqColors.softInk,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Balloon widget
// ---------------------------------------------------------------------------

class _BalloonWidget extends StatelessWidget {
  const _BalloonWidget({
    required this.glyph,
    required this.color,
    required this.isTarget,
  });

  final String glyph;
  final Color color;
  final bool isTarget;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Balloon circle
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: isTarget
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            glyph,
            textDirection: TextDirection.rtl,
            style: arabicGlyphStyle(36, color: Colors.white),
          ),
        ),
        // String
        Container(
          width: 2,
          height: 20,
          color: color.withValues(alpha: 0.7),
        ),
      ],
    );
  }
}
