import 'dart:async';
import 'dart:math' show sin, pi;

import 'package:flutter/material.dart';

import '../../../content/math_content.dart';
import '../../../core/art.dart';
import '../../../theme/wq_colors.dart';

// ============================================================
// Shared tap-to-count object group
// ============================================================

/// A grid of tappable emoji objects with count badges.
///
/// Used by Zoo (count), Dino Snack (add), and Treasure Hunt (add) scenes.
class ObjGroup extends StatelessWidget {
  const ObjGroup({
    super.key,
    required this.emoji,
    required this.count,
    required this.counted,
    required this.baseOffset,
    required this.onTap,
  });

  /// The emoji character to render for each item.
  final String emoji;

  /// Total number of objects in this group.
  final int count;

  /// Global tap IDs that have been counted (across all groups).
  final List<int> counted;

  /// Added to the local index `k` to produce a unique tap ID (`baseOffset + k`).
  final int baseOffset;

  final void Function(int id) onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: List.generate(count, (k) {
        final id = baseOffset + k;
        final isCounted = counted.contains(id);
        final tallyPos = counted.indexOf(id) + 1;
        return GestureDetector(
          key: Key('math-obj-$id'),
          onTap: () => onTap(id),
          child: SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedScale(
                  scale: isCounted ? 1.18 : 1.0,
                  duration: const Duration(milliseconds: 160),
                  child: Text(emoji, style: const TextStyle(fontSize: 44)),
                ),
                if (isCounted)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: WqColors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$tallyPos',
                          style: const TextStyle(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ============================================================
// 1. Count the Zoo — tap each animal, then pick the number
// ============================================================

/// Theatric for the Zoo Count station.
///
/// Shows [problem.a] zoo animals (from [problem.obj]). Each is tappable;
/// a count badge appears on each tapped object. When [solved] the count
/// is revealed large and celebratory.
class ZooCountScene extends StatelessWidget {
  const ZooCountScene({
    super.key,
    required this.problem,
    required this.counted,
    required this.onTap,
    required this.solved,
  });

  final MathProblem problem;
  final List<int> counted;
  final void Function(int id) onTap;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ObjGroup(
          emoji: problem.obj,
          count: problem.a,
          counted: counted,
          baseOffset: 0,
          onTap: onTap,
        ),
        if (solved) ...[
          const SizedBox(height: 10),
          Text(
            key: const Key('math-equation'),
            '${problem.a} ${problem.obj}!',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 52,
              color: WqColors.orange,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// 2. Dino Snack Time — addition with two fruit groups
// ============================================================

/// Theatric for the Dino Snack Time station.
///
/// Shows Rex + group A of fruits ➕ group B of fruits. Both groups are
/// tap-to-count. When [solved] the equation is revealed.
class DinoSnackScene extends StatelessWidget {
  const DinoSnackScene({
    super.key,
    required this.problem,
    required this.counted,
    required this.onTap,
    required this.solved,
  });

  final MathProblem problem;
  final List<int> counted;
  final void Function(int id) onTap;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Art.glyph('rexy', size: 48),
            const SizedBox(width: 8),
            ObjGroup(
              emoji: problem.obj,
              count: problem.a,
              counted: counted,
              baseOffset: 0,
              onTap: onTap,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('➕', style: TextStyle(fontSize: 36)),
            ),
            ObjGroup(
              emoji: problem.obj,
              count: problem.b,
              counted: counted,
              baseOffset: 100,
              onTap: onTap,
            ),
          ],
        ),
        if (solved) ...[
          const SizedBox(height: 10),
          Text(
            key: const Key('math-equation'),
            '${problem.a} + ${problem.b} = ${problem.answer}',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 52,
              color: WqColors.green,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// 3. Treasure Hunt — addition with gems inside a chest
// ============================================================

/// Theatric for the Treasure Hunt station.
///
/// Shows two gem groups inside a rendered treasure chest (domed lid,
/// gold straps, lock, light velvet tray). When [solved] the equation
/// is revealed below the chest.
class TreasureHuntScene extends StatelessWidget {
  const TreasureHuntScene({
    super.key,
    required this.problem,
    required this.counted,
    required this.onTap,
    required this.solved,
  });

  final MathProblem problem;
  final List<int> counted;
  final void Function(int id) onTap;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TreasureChest(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ObjGroup(
                emoji: problem.obj,
                count: problem.a,
                counted: counted,
                baseOffset: 0,
                onTap: onTap,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '➕',
                  style: TextStyle(
                    fontSize: 30,
                    color: Color(0xFF7a4e1d),
                  ),
                ),
              ),
              ObjGroup(
                emoji: problem.obj,
                count: problem.b,
                counted: counted,
                baseOffset: 100,
                onTap: onTap,
              ),
            ],
          ),
        ),
        if (solved) ...[
          const SizedBox(height: 10),
          Text(
            key: const Key('math-equation'),
            '${problem.a} + ${problem.b} = ${problem.answer}',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 52,
              color: WqColors.teal,
            ),
          ),
        ],
      ],
    );
  }
}

/// Treasure chest rendered from pure Flutter containers.
///
/// Domed lid (large top radius), gold-coloured vertical straps, a small
/// lock in the centre-bottom, and a light velvet-tinted tray inside.
class _TreasureChest extends StatelessWidget {
  const _TreasureChest({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: const Color(0xFFC67C2A), // warm wood brown
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border.all(color: const Color(0xFF8B5E0A), width: 3),
      ),
      child: Stack(
        children: [
          // Velvet tray interior
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 20, 40, 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF6B3FA0).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
          // Left gold strap
          Positioned(
            left: 18,
            top: 0,
            bottom: 0,
            child: Container(width: 8, color: const Color(0xFFFFD700)),
          ),
          // Right gold strap
          Positioned(
            right: 18,
            top: 0,
            bottom: 0,
            child: Container(width: 8, color: const Color(0xFFFFD700)),
          ),
          // Lock (centre-bottom)
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF8B5E0A),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 4. Lost Dino Eggs — subtraction with staggered hatch animation
// ============================================================

/// Theatric for the Lost Dino Eggs station.
///
/// Shows [problem.a] eggs in total. The last [problem.b] eggs animate:
/// shake → 💥 crack → baby dino pops out (staggered 400 ms apart).
/// When [solved] the subtraction equation is revealed.
class LostDinoEggsScene extends StatefulWidget {
  const LostDinoEggsScene({
    super.key,
    required this.problem,
    required this.solved,
  });

  final MathProblem problem;
  final bool solved;

  @override
  State<LostDinoEggsScene> createState() => _LostDinoEggsSceneState();
}

class _LostDinoEggsSceneState extends State<LostDinoEggsScene>
    with TickerProviderStateMixin {
  late final List<AnimationController> _hatchCtrl;
  final List<Timer> _startTimers = [];
  static const List<String> _babies = ['🦕', '🦖', '🐉'];

  @override
  void initState() {
    super.initState();
    final numHatch = widget.problem.b;
    _hatchCtrl = List.generate(numHatch, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );
      final t = Timer(Duration(milliseconds: 200 + i * 400), () {
        if (mounted) ctrl.forward();
      });
      _startTimers.add(t);
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final t in _startTimers) {
      t.cancel();
    }
    for (final c in _hatchCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.problem.a;
    final remaining = widget.problem.answer; // total - take

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(total, (k) {
            final hatchIdx = k - remaining; // index into _hatchCtrl
            final isHatching = k >= remaining;

            if (isHatching && hatchIdx < _hatchCtrl.length) {
              final ctrl = _hatchCtrl[hatchIdx];
              final baby = _babies[hatchIdx % _babies.length];
              return AnimatedBuilder(
                animation: ctrl,
                builder: (context2, child2) {
                  final t = ctrl.value;
                  if (t < 0.6) {
                    // Phase 1 (0–0.3): shake; Phase 2 (0.3–0.6): crack flash
                    final shake = t < 0.3 ? sin(t * pi * 10) * 5.0 : 0.0;
                    return Transform.translate(
                      offset: Offset(shake, 0),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Text('🥚', style: TextStyle(fontSize: 44)),
                            if (t >= 0.3)
                              const Text('💥', style: TextStyle(fontSize: 28)),
                          ],
                        ),
                      ),
                    );
                  } else {
                    // Phase 3 (0.6–1.0): baby dino pops up
                    final popT = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: popT,
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: Center(
                          child: Text(baby, style: const TextStyle(fontSize: 44)),
                        ),
                      ),
                    );
                  }
                },
              );
            } else {
              // Remaining eggs — static
              return const SizedBox(
                width: 64,
                height: 64,
                child: Center(
                  child: Text('🥚', style: TextStyle(fontSize: 44)),
                ),
              );
            }
          }),
        ),
        if (widget.solved) ...[
          const SizedBox(height: 10),
          Text(
            key: const Key('math-equation'),
            '${widget.problem.a} − ${widget.problem.b} = ${widget.problem.answer}',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 52,
              color: WqColors.coral,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// 5. Cookie Math — subtraction with monkey swing-in animation
// ============================================================

/// Theatric for the Cookie Math station.
///
/// A monkey (🐵) swings in from off-screen on a vine using a curved
/// slide animation. The last [problem.b] cookies fade to 15 % opacity
/// to show they have been eaten. When [solved] the equation is revealed.
class CookieMathScene extends StatefulWidget {
  const CookieMathScene({
    super.key,
    required this.problem,
    required this.solved,
  });

  final MathProblem problem;
  final bool solved;

  @override
  State<CookieMathScene> createState() => _CookieMathSceneState();
}

class _CookieMathSceneState extends State<CookieMathScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _monkeyCtrl;
  late final Animation<Offset> _slideAnim;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _monkeyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(2.0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _monkeyCtrl, curve: Curves.elasticOut),
    );
    _startTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _monkeyCtrl.forward();
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _monkeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.problem.a;
    final remaining = widget.problem.answer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Monkey swings in on a vine
        SlideTransition(
          position: _slideAnim,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌿', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 4),
              Art.glyph('monkey', size: 44),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Cookies — eaten ones fade to 15 % opacity
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(total, (k) {
            final isEaten = k >= remaining;
            return SizedBox(
              key: Key('cookie-$k'),
              width: 64,
              height: 64,
              child: Center(
                child: AnimatedOpacity(
                  opacity: isEaten ? 0.15 : 1.0,
                  duration: const Duration(milliseconds: 600),
                  child: const Text('🍪', style: TextStyle(fontSize: 44)),
                ),
              ),
            );
          }),
        ),
        if (widget.solved) ...[
          const SizedBox(height: 10),
          Text(
            key: const Key('math-equation'),
            '${widget.problem.a} − ${widget.problem.b} = ${widget.problem.answer}',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w800,
              fontSize: 52,
              color: WqColors.yellow,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// 6. More or Less — compare two groups (tap a panel)
// ============================================================

/// Theatric for the More or Less station.
///
/// Shows two large tappable panels (A and B) each filled with
/// [problem.a] and [problem.b] emoji objects respectively. Tapping
/// a panel calls [onChoose] with `true` for A and `false` for B.
/// Border turns green / coral after an answer. The winning side
/// shows its count when [correct] is true.
class MoreOrLessScene extends StatelessWidget {
  const MoreOrLessScene({
    super.key,
    required this.problem,
    required this.wantMore,
    required this.onChoose,
    required this.correct,
    required this.pickedA,
  });

  final MathProblem problem;

  /// `true` = prompt asks for MORE; `false` = prompt asks for FEWER.
  final bool wantMore;

  final void Function(bool choseA) onChoose;

  /// `null` = not yet answered; `true` = last pick was correct;
  /// `false` = last pick was wrong.
  final bool? correct;

  /// `null` = not yet picked; `true` = A was picked; `false` = B was picked.
  final bool? pickedA;

  Color _border(bool isA) {
    final wasPicked = isA ? pickedA == true : pickedA == false;
    if (!wasPicked || correct == null) return Colors.transparent;
    return correct! ? WqColors.green : WqColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    final aIsSolved = correct == true && pickedA == true;
    final bIsSolved = correct == true && pickedA == false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ComparePanel(
          key: const Key('compare-panel-A'),
          emoji: problem.obj,
          count: problem.a,
          borderColor: _border(true),
          solved: aIsSolved,
          onTap: () => onChoose(true),
        ),
        _ComparePanel(
          key: const Key('compare-panel-B'),
          emoji: problem.obj,
          count: problem.b,
          borderColor: _border(false),
          solved: bIsSolved,
          onTap: () => onChoose(false),
        ),
      ],
    );
  }
}

class _ComparePanel extends StatelessWidget {
  const _ComparePanel({
    super.key,
    required this.emoji,
    required this.count,
    required this.borderColor,
    required this.solved,
    required this.onTap,
  });

  final String emoji;
  final int count;
  final Color borderColor;
  final bool solved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 260,
        constraints: const BoxConstraints(minHeight: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: WqColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(
                count,
                (_) => Text(emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            if (solved) ...[
              const SizedBox(height: 8),
              Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: WqColors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
