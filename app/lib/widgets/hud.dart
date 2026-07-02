import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/art.dart';
import '../core/save_controller.dart';
import '../domain/reward_engine.dart';
import '../theme/wq_colors.dart';

/// Top status bar (height 72) that shows live game state from
/// [saveControllerProvider].
///
/// Displays:
/// - Mascot avatar (Rexy) with "Lv N" label
/// - XP progress bar (xp / xpForLevel(level) fraction)
/// - Streak, star and egg coin counts
/// - Sound toggle button (calls [SaveController.toggleSound])
/// - Parent gate button (calls [onParentTap])
///
/// All art is rendered through [Art]. Interactive hit targets are ≥ 64 px
/// (child-facing requirement). All colours come from [WqColors].
class Hud extends ConsumerWidget {
  const Hud({super.key, required this.onParentTap});

  final VoidCallback onParentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveControllerProvider).value;

    final level = save?.level ?? 1;
    final xp = save?.xp ?? 0;
    final streak = save?.streak ?? 0;
    final stars = save?.stars ?? 0;
    final eggs = save?.eggs ?? 0;
    final soundOn = save?.soundOn ?? true;

    final xpNeeded = xpForLevel(level);
    final xpFraction =
        xpNeeded > 0 ? (xp / xpNeeded).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      height: 72,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: WqColors.background,
          border: Border(
            bottom: BorderSide(color: WqColors.lines, width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // ── Avatar pill: mascot + "Lv N" ─────────────────────────────
              _AvatarPill(level: level),
              const SizedBox(width: 12),

              // ── XP progress bar ──────────────────────────────────────────
              _XpBar(fraction: xpFraction),
              const Spacer(),

              // ── Coin badges: streak, stars, eggs ─────────────────────────
              _Coin(artKey: '🔥', count: streak),
              const SizedBox(width: 8),
              _Coin(artKey: 'star', count: stars),
              const SizedBox(width: 8),
              _Coin(artKey: 'egg', count: eggs),
              const SizedBox(width: 12),

              // ── Sound toggle (≥ 64 px hit target) ───────────────────────
              GestureDetector(
                key: const Key('hud-sound'),
                onTap: () =>
                    ref.read(saveControllerProvider.notifier).toggleSound(),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Center(
                    child: Art.glyph(
                      soundOn ? 'sound-on' : 'sound-off',
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // ── Parent gate button (≥ 64 px hit target) ─────────────────
              GestureDetector(
                key: const Key('hud-parent'),
                onTap: onParentTap,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Center(
                    child: Art.glyph('parent', size: 32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private helper widgets ─────────────────────────────────────────────────────

/// Pill-shaped chip: mascot emoji + "Lv N" label.
class _AvatarPill extends StatelessWidget {
  const _AvatarPill({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WqColors.card,
        borderRadius: BorderRadius.circular(50),
        boxShadow: const [
          BoxShadow(
            color: WqColors.lines,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Art.glyph(Art.mascot, size: 36),
            const SizedBox(width: 8),
            Text(
              'Lv $level',
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: WqColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal XP progress bar (200 × 20 logical pixels).
class _XpBar extends StatelessWidget {
  const _XpBar({required this.fraction});

  /// Value in [0.0, 1.0].
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: fraction,
          backgroundColor: WqColors.lines,
          valueColor: const AlwaysStoppedAnimation<Color>(WqColors.teal),
          minHeight: 20,
        ),
      ),
    );
  }
}

/// Emoji + numeric count badge (e.g. ⭐ 7).
///
/// [artKey] is forwarded to [Art.glyph]; known semantic keys are translated
/// to their emoji, unknown keys (e.g. literal '🔥') pass through unchanged.
class _Coin extends StatelessWidget {
  const _Coin({required this.artKey, required this.count});

  final String artKey;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Art.glyph(artKey, size: 24),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: WqColors.ink,
          ),
        ),
      ],
    );
  }
}
