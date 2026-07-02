import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/art.dart';
import '../core/audio/sfx_service.dart';
import '../domain/spot_scene_engine.dart';
import '../theme/wq_colors.dart';

/// Renders a jittered-grid scatter scene for find/count games.
///
/// Items are placed using [SpotSceneLayout.place] and sized to fill the
/// available space via [LayoutBuilder]. Each item has a hit target of at
/// least 64 × 64 logical pixels.
///
/// Correct tap  → pop-scale animation + ring overlay + [Sfx.pop].
/// Wrong tap    → "👀" ripple at tap point + [Sfx.wrong].
/// Count mode   → running number label on each found item.
/// All goals met → [onComplete] called after a short delay.
class SpotScene extends ConsumerStatefulWidget {
  const SpotScene({
    super.key,
    required this.goals,
    required this.mode,
    required this.decoys,
    required this.decoyCount,
    required this.bg,
    this.deco = const [],
    required this.onComplete,
  });

  final List<SpotGoal> goals;
  final SpotMode mode;
  final List<String> decoys;
  final int decoyCount;
  final Color bg;

  /// Optional decorative (non-interactive) background glyphs.
  final List<String> deco;

  final VoidCallback onComplete;

  @override
  ConsumerState<SpotScene> createState() => _SpotSceneState();
}

class _SpotSceneState extends ConsumerState<SpotScene>
    with TickerProviderStateMixin {
  // Items placed by SpotSceneLayout — populated on first layout.
  List<PlacedItem> _items = const [];

  // Engine tracks found state.
  late SpotSceneState _engine;

  // IDs of tapped targets (found).
  final Set<int> _found = {};

  // Order in which targets were found (for count-mode labels).
  final List<int> _foundOrder = [];

  // Active bounce controllers: itemId → controller.
  final Map<int, AnimationController> _bounce = {};

  // Position of the current "wrong tap" ripple (null = hidden).
  Offset? _missPos;

  // Whether onComplete has already been scheduled.
  bool _done = false;

  // Whether items have been placed for this layout size.
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    _engine = SpotSceneState(widget.goals, widget.mode);
  }

  @override
  void dispose() {
    for (final ctrl in _bounce.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Placement
  // ---------------------------------------------------------------------------

  void _placeItems(Size canvasSize) {
    _items = SpotSceneLayout.place(
      goals: widget.goals,
      decoys: widget.decoys,
      decoyCount: widget.decoyCount,
      canvas: canvasSize,
      random: Random(),
    );
    _engine = SpotSceneState(widget.goals, widget.mode);
    _found.clear();
    _foundOrder.clear();
    _bounce.clear();
    _done = false;
  }

  // ---------------------------------------------------------------------------
  // Tap handling
  // ---------------------------------------------------------------------------

  void _onItemTap(PlacedItem item, TapUpDetails details) {
    if (_done) return;
    final sfx = ref.read(sfxServiceProvider);

    if (_engine.tap(item)) {
      // Correct tap: record, animate, play sound.
      sfx.play(Sfx.pop);
      _foundOrder.add(item.id);

      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      );
      ctrl.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() => _bounce.remove(item.id));
            ctrl.dispose();
          }
        }
      });

      setState(() {
        _found.add(item.id);
        _bounce[item.id] = ctrl;
      });
      ctrl.forward();

      if (_engine.complete && !_done) {
        _done = true;
        Future.delayed(
          const Duration(milliseconds: 600),
          widget.onComplete,
        );
      }
    } else if (!item.isTarget) {
      // Wrong tap: show ripple.
      sfx.play(Sfx.wrong);
      setState(() => _missPos = details.localPosition);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _missPos = null);
      });
    }
    // Already-found target: silently ignore.
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 1194,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 834,
        );

        // Place items once on first layout (post-frame to avoid build mutation).
        if (!_placed) {
          _placed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _placeItems(canvasSize));
            }
          });
        }

        return ColoredBox(
          color: widget.bg,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Goal chips header.
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: _GoalChipsBar(
                  goals: widget.goals,
                  foundByChar: _engine.foundByChar,
                  mode: widget.mode,
                ),
              ),

              // Scattered items.
              for (final item in _items) _buildItem(item),

              // Wrong-tap ripple.
              if (_missPos != null)
                Positioned(
                  left: _missPos!.dx - 24,
                  top: _missPos!.dy - 24,
                  child: const IgnorePointer(
                    child: _MissRipple(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItem(PlacedItem item) {
    final isFound = _found.contains(item.id);
    final bounceCtrl = _bounce[item.id];

    // Count-mode label: nth found.
    final foundIndex = _foundOrder.indexOf(item.id);
    final countLabel = (isFound && widget.mode == SpotMode.count)
        ? '${foundIndex + 1}'
        : null;

    Widget glyph = Art.glyph(item.char, size: item.size);

    // Pop-scale animation while the bounce controller is active.
    if (bounceCtrl != null) {
      glyph = AnimatedBuilder(
        animation: bounceCtrl,
        builder: (_, child) {
          final t = bounceCtrl.value;
          // 0→0.5: scale up 1.0→1.35; 0.5→1.0: scale back 1.35→1.0.
          final scale = t < 0.5
              ? 1.0 + 0.35 * (t / 0.5)
              : 1.35 - 0.35 * ((t - 0.5) / 0.5);
          return Transform.scale(scale: scale, child: child);
        },
        child: glyph,
      );
    }

    // Ring overlay for found targets.
    if (isFound) {
      glyph = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          glyph,
          // Ring.
          IgnorePointer(
            child: Container(
              width: item.size + 12,
              height: item.size + 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: WqColors.yellow,
                  width: 3,
                ),
              ),
            ),
          ),
          // Count-mode number badge.
          if (countLabel != null)
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: WqColors.yellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  countLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: WqColors.ink,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Tap target — ≥64 × 64 px.
    final hitSize = item.size.clamp(64.0, double.infinity);

    return Positioned(
      left: item.pos.dx - hitSize / 2,
      top: item.pos.dy - hitSize / 2,
      child: GestureDetector(
        key: ValueKey('spot-item-${item.id}'),
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _onItemTap(item, details),
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(child: glyph),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Goal chips header
// ---------------------------------------------------------------------------

class _GoalChipsBar extends StatelessWidget {
  const _GoalChipsBar({
    required this.goals,
    required this.foundByChar,
    required this.mode,
  });

  final List<SpotGoal> goals;
  final Map<String, int> foundByChar;
  final SpotMode mode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: goals.map((goal) {
          final found = foundByChar[goal.char] ?? 0;
          final done = found >= goal.count;
          return _GoalChip(goal: goal, found: found, done: done);
        }).toList(),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.goal,
    required this.found,
    required this.done,
  });

  final SpotGoal goal;
  final int found;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: done ? WqColors.green : WqColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done ? WqColors.green : WqColors.lines,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(goal.char, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 6),
            Text(
              '$found/${goal.count}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: done ? Colors.white : WqColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wrong-tap ripple
// ---------------------------------------------------------------------------

class _MissRipple extends StatefulWidget {
  const _MissRipple();

  @override
  State<_MissRipple> createState() => _MissRippleState();
}

class _MissRippleState extends State<_MissRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: child,
      ),
      child: const Text('👀', style: TextStyle(fontSize: 32)),
    );
  }
}
