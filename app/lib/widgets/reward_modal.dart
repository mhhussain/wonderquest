import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/art.dart';
import '../core/audio/sfx_service.dart';
import '../core/save_controller.dart';
import '../domain/reward.dart';
import '../theme/wq_colors.dart';
import 'wq_button.dart';

/// Applies [reward] and (unless [reward.silent]) shows a full-screen
/// celebration dialog with a confetti burst, a starburst behind Rexy, reward
/// pills for each nonzero component, and Map / Play-again buttons.
///
/// If [reward.silent] is `true` the reward is applied silently and the
/// function returns immediately — used by Discovery Cards which provide their
/// own inline celebration.
///
/// [onPlayAgain] fires when the child taps "▶ Play again". When `null` that
/// button is hidden.
Future<void> showRewardModal(
  BuildContext context,
  WidgetRef ref,
  Reward reward, {
  VoidCallback? onPlayAgain,
}) async {
  // Always apply the reward first, even for silent ones.
  await ref.read(saveControllerProvider.notifier).apply(reward);

  if (reward.silent) return;

  // Fire-and-forget fanfare: audio plays while the dialog is presented.
  unawaited(ref.read(sfxServiceProvider).play(Sfx.fanfare));

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RewardDialog(
      reward: reward,
      onPlayAgain: onPlayAgain,
    ),
  );
}

// ---------------------------------------------------------------------------
// Dialog
// ---------------------------------------------------------------------------

class _RewardDialog extends StatefulWidget {
  const _RewardDialog({required this.reward, this.onPlayAgain});

  final Reward reward;
  final VoidCallback? onPlayAgain;

  @override
  State<_RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<_RewardDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _particles = _Particle.generate(40, seed: 42);
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: WqColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: SizedBox(
        width: 480,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // ── Confetti (non-interactive overlay) ────────────────────────
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _confettiCtrl,
                    builder: (_, _) => CustomPaint(
                      painter: _ConfettiPainter(
                        progress: _confettiCtrl.value,
                        particles: _particles,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Main content ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Starburst + mascot
                    const _StarburstRexy(),
                    const SizedBox(height: 20),

                    // Reward pills (only when there is something to show)
                    if (_hasPills(widget.reward)) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _buildPills(widget.reward),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Buttons row
                    Row(
                      children: [
                        Expanded(
                          child: WqButton(
                            key: const Key('reward-map'),
                            label: 'Map',
                            emojiKey: Art.emoji('map'),
                            color: WqColors.teal,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                        if (widget.onPlayAgain != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: WqButton(
                              key: const Key('reward-play-again'),
                              label: 'Play again',
                              emojiKey: Art.emoji('play'),
                              color: WqColors.orange,
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onPlayAgain!();
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _hasPills(Reward r) =>
      r.stars > 0 || r.xp > 0 || r.egg || r.sticker != null || r.animal != null;

  static List<Widget> _buildPills(Reward reward) {
    final pills = <Widget>[];

    if (reward.stars > 0) {
      pills.add(_RewardPill(
        key: const Key('pill-stars'),
        label: '+${reward.stars}',
        artKey: 'star',
        artLeading: false,
      ));
    }

    if (reward.xp > 0) {
      pills.add(_RewardPill(
        key: const Key('pill-xp'),
        label: '+${reward.xp} XP',
      ));
    }

    if (reward.egg) {
      pills.add(const _RewardPill(
        key: Key('pill-egg'),
        label: 'New egg!',
        artKey: 'egg',
        artLeading: true,
      ));
    }

    if (reward.sticker != null) {
      pills.add(_RewardPill(
        key: const Key('pill-sticker'),
        label: reward.sticker!,
      ));
    }

    if (reward.animal != null) {
      pills.add(_RewardPill(
        key: const Key('pill-animal'),
        label: reward.animal!,
      ));
    }

    return pills;
  }
}

// ---------------------------------------------------------------------------
// Starburst + Rexy
// ---------------------------------------------------------------------------

class _StarburstRexy extends StatelessWidget {
  const _StarburstRexy();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CustomPaint(
            size: Size(140, 140),
            painter: _StarburstPainter(),
          ),
          Art.glyph(Art.mascot, size: 72),
        ],
      ),
    );
  }
}

class _StarburstPainter extends CustomPainter {
  const _StarburstPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = WqColors.yellow
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final innerR = outerR * 0.55;
    const numPoints = 12;

    final path = Path();
    for (var i = 0; i < numPoints * 2; i++) {
      final angle = (i * pi / numPoints) - pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarburstPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Reward pill
// ---------------------------------------------------------------------------

class _RewardPill extends StatelessWidget {
  const _RewardPill({
    super.key,
    required this.label,
    this.artKey,
    this.artLeading = false,
  });

  /// Text displayed in the pill (e.g. `'+3'`, `'+40 XP'`, `'New egg!'`).
  final String label;

  /// Optional [Art] semantic key for an emoji icon.
  final String? artKey;

  /// When `true` the emoji precedes the label; when `false` it follows.
  final bool artLeading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WqColors.backgroundAlt,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: WqColors.lines, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (artKey != null && artLeading) ...[
              Art.glyph(artKey!, size: 20),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: WqColors.ink,
              ),
            ),
            if (artKey != null && !artLeading) ...[
              const SizedBox(width: 6),
              Art.glyph(artKey!, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confetti particle + painter
// ---------------------------------------------------------------------------

class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.startRotation,
    required this.rotationSpeed,
  });

  /// Initial horizontal position as a fraction of canvas width in `[0, 1]`.
  final double x;

  /// Initial vertical position as a fraction of canvas height (negative = above).
  final double y;

  /// Horizontal drift per unit of animation progress.
  final double vx;

  /// Downward velocity per unit of animation progress.
  final double vy;

  final Color color;

  /// Width of the confetti rectangle in logical pixels.
  final double size;

  final double startRotation;
  final double rotationSpeed;

  static const List<Color> _palette = [
    WqColors.orange,
    WqColors.teal,
    WqColors.green,
    WqColors.coral,
    WqColors.grape,
    WqColors.yellow,
    WqColors.pink,
  ];

  /// Generates [count] particles using a seeded [Random] for determinism.
  static List<_Particle> generate(int count, {required int seed}) {
    final rng = Random(seed);
    return List.generate(count, (_) {
      return _Particle(
        x: rng.nextDouble(),
        y: -rng.nextDouble() * 0.3,
        vx: (rng.nextDouble() - 0.5) * 0.4,
        vy: 0.5 + rng.nextDouble() * 0.7,
        color: _palette[rng.nextInt(_palette.length)],
        size: 7 + rng.nextDouble() * 7,
        startRotation: rng.nextDouble() * 2 * pi,
        rotationSpeed: (rng.nextDouble() - 0.5) * 8,
      );
    });
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.progress,
    required this.particles,
  });

  /// Animation progress in `[0.0, 1.0]`.
  final double progress;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final x = (p.x + p.vx * progress) * size.width;
      final y = (p.y + p.vy * progress) * size.height;

      // Skip particles that have not yet entered or have exited the canvas.
      if (y > size.height + p.size || y < -p.size * 2) continue;

      final opacity = (1.0 - progress * 0.6).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.startRotation + p.rotationSpeed * progress);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size * 0.45,
      );
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
