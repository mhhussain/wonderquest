import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/art.dart';
import '../core/audio/sfx_service.dart';
import '../domain/drift_field.dart';
import '../theme/wq_colors.dart';

/// Drift-collect mini-game widget.
///
/// Renders [itemChars] as slowly-drifting items within the available space.
/// The player drags the [mascotKey] glyph (96 px) to collect items on overlap.
/// Each collection fires [Sfx.pop]. When all items are collected,
/// [onAllCollected] is called after a short delay.
///
/// Driven by a [Ticker] (Flutter's vsync-based game loop) that advances the
/// [DriftField] engine and checks overlaps each frame.
class DriftFieldWidget extends ConsumerStatefulWidget {
  const DriftFieldWidget({
    super.key,
    required this.itemChars,
    required this.mascotKey,
    required this.onAllCollected,
    this.random,
  });

  /// Characters to place as collectible items.
  final List<String> itemChars;

  /// Art key for the draggable mascot (e.g. `'rexy'`).
  final String mascotKey;

  /// Called once (after a short delay) when all items have been collected.
  final VoidCallback onAllCollected;

  /// Injected [Random] for deterministic tests. Defaults to [Random()].
  @visibleForTesting
  final Random? random;

  @override
  ConsumerState<DriftFieldWidget> createState() => _DriftFieldWidgetState();
}

class _DriftFieldWidgetState extends ConsumerState<DriftFieldWidget>
    with TickerProviderStateMixin {
  static const _itemRadius = 24.0;
  static const _mascotRadius = 48.0; // half of 96 px mascot
  static const _collectRadius = 60.0;

  DriftField? _engine;
  late Ticker _ticker;
  Duration? _lastElapsed;

  Offset _mascotPos = Offset.zero;
  bool _initialized = false;
  bool _done = false;
  int _collectedCount = 0;
  Size _fieldSize = Size.zero;

  /// Pop-scale-out animation controllers keyed by item id.
  final Map<int, AnimationController> _popAnims = {};

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    for (final ctrl in _popAnims.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Engine init
  // ---------------------------------------------------------------------------

  void _initEngine(Size bounds) {
    _fieldSize = bounds;
    _engine = DriftField(
      chars: widget.itemChars,
      bounds: bounds,
      itemRadius: _itemRadius,
      random: widget.random ?? Random(),
    );
    _mascotPos = Offset(bounds.width / 2, bounds.height * 0.75);
    if (!_ticker.isActive) _ticker.start();
  }

  // ---------------------------------------------------------------------------
  // Ticker callback
  // ---------------------------------------------------------------------------

  void _onTick(Duration elapsed) {
    if (_engine == null || !mounted) return;

    // On the very first tick establish the time baseline; skip to next frame
    // so dt is always a real measured delta and never 0.
    if (_lastElapsed == null) {
      _lastElapsed = elapsed;
      return;
    }

    final dtMicros = (elapsed - _lastElapsed!).inMicroseconds;
    _lastElapsed = elapsed;

    // Cap to 50 ms to avoid large jumps after the app is backgrounded.
    final dt = (dtMicros / 1e6).clamp(0.0, 0.05);

    _engine!.tick(dt);

    final newIds = _engine!.collectAt(_mascotPos, _collectRadius);
    if (newIds.isNotEmpty) {
      final sfx = ref.read(sfxServiceProvider);
      for (final id in newIds) {
        sfx.play(Sfx.pop);
        _startPopAnim(id);
      }
    }

    setState(() {
      _collectedCount = _engine!.items.where((i) => i.collected).length;
    });

    if (_engine!.allCollected && !_done) {
      _done = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onAllCollected();
      });
    }
  }

  void _startPopAnim(int id) {
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _popAnims.remove(id));
        ctrl.dispose();
      }
    });
    _popAnims[id] = ctrl;
    ctrl.forward();
  }

  // ---------------------------------------------------------------------------
  // Gesture
  // ---------------------------------------------------------------------------

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _mascotPos = Offset(
        (_mascotPos.dx + details.delta.dx).clamp(0, _fieldSize.width),
        (_mascotPos.dy + details.delta.dy).clamp(0, _fieldSize.height),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 800,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 600,
        );

        // Initialise once on first layout; post-frame so setState is safe.
        if (!_initialized) {
          _initialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _initEngine(size));
          });
        }

        final engine = _engine;
        final n = widget.itemChars.length;

        return ColoredBox(
          color: WqColors.sky.withValues(alpha: 0.25),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Drifting items.
              if (engine != null)
                for (final item in engine.items)
                  if (!item.collected || _popAnims.containsKey(item.id))
                    Positioned(
                      key: ValueKey('drift-item-${item.id}'),
                      left: item.pos.dx - _itemRadius,
                      top: item.pos.dy - _itemRadius,
                      child: _DriftItemGlyph(
                        item: item,
                        popAnim: _popAnims[item.id],
                      ),
                    ),

              // Draggable mascot.
              Positioned(
                left: _mascotPos.dx - _mascotRadius,
                top: _mascotPos.dy - _mascotRadius,
                child: GestureDetector(
                  key: const ValueKey('drift-mascot'),
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: _onPanUpdate,
                  child: SizedBox(
                    width: _mascotRadius * 2,
                    height: _mascotRadius * 2,
                    child: Center(
                      child: Art.glyph(widget.mascotKey, size: _mascotRadius * 2),
                    ),
                  ),
                ),
              ),

              // Count badge (top-right HUD).
              Positioned(
                top: 8,
                right: 8,
                child: _CountBadge(count: _collectedCount, total: n),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.total});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: WqColors.teal,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        '$count/$total',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: WqColors.card,
        ),
      ),
    );
  }
}

/// Renders a single drifting item, with optional pop-scale animation on collect.
class _DriftItemGlyph extends StatelessWidget {
  const _DriftItemGlyph({required this.item, required this.popAnim});

  final DriftItem item;
  final AnimationController? popAnim;

  @override
  Widget build(BuildContext context) {
    Widget glyph = Art.glyph(item.char, size: 48);

    if (popAnim != null) {
      glyph = AnimatedBuilder(
        animation: popAnim!,
        builder: (_, child) {
          final t = popAnim!.value;
          return Opacity(
            opacity: (1.0 - t).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 1.0 + t * 0.5,
              child: child,
            ),
          );
        },
        child: glyph,
      );
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: Center(child: glyph),
    );
  }
}
