import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/world_content.dart';
import '../../../core/audio/sfx_service.dart';
import '../../../core/audio/tts_service.dart';
import '../../../domain/spot_scene_engine.dart';
import '../../../theme/wq_colors.dart';
import '../../../widgets/drift_field_widget.dart';
import '../../../widgets/spot_scene.dart';

// ---------------------------------------------------------------------------
// Dispatcher
// ---------------------------------------------------------------------------

/// Routes a [MiniGameSpec] to the correct mini-game widget.
///
/// Each game calls [onWin] once when the player succeeds.
class MiniGameWidget extends ConsumerWidget {
  const MiniGameWidget({
    super.key,
    required this.game,
    required this.color,
    required this.color2,
    required this.onWin,
  });

  final MiniGameSpec game;
  final Color color;
  final Color color2;
  final VoidCallback onWin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (game.type) {
      case MiniGameType.collect:
        return _CollectGame(
            game: game, color: color, color2: color2, onWin: onWin);
      case MiniGameType.order:
        return _OrderGame(
            game: game, color: color, color2: color2, onWin: onWin);
      case MiniGameType.build:
        return _BuildGame(
            game: game, color: color, color2: color2, onWin: onWin);
      case MiniGameType.decorate:
        return _DecorateGame(
            game: game, color: color, color2: color2, onWin: onWin);
      case MiniGameType.find:
        return _FindGame(
            game: game, color: color, color2: color2, onWin: onWin);
    }
  }
}

// ---------------------------------------------------------------------------
// Collect game — DriftFieldWidget
// ---------------------------------------------------------------------------

class _CollectGame extends ConsumerStatefulWidget {
  const _CollectGame({
    required this.game,
    required this.color,
    required this.color2,
    required this.onWin,
  });

  final MiniGameSpec game;
  final Color color;
  final Color color2;
  final VoidCallback onWin;

  @override
  ConsumerState<_CollectGame> createState() => _CollectGameState();
}

class _CollectGameState extends ConsumerState<_CollectGame> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final say = widget.game.params['say'] as String? ?? '';
      if (say.isNotEmpty) {
        ref.read(ttsServiceProvider).speak(say);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.game.params;
    final who = p['who'] as String? ?? '🦖';
    final item = p['item'] as String? ?? '⭐';
    final n = (p['n'] as int?) ?? 6;
    final items = List.filled(n, item);

    return DriftFieldWidget(
      key: const Key('collect-game'),
      mascotKey: who,
      itemChars: items,
      onAllCollected: widget.onWin,
    );
  }
}

// ---------------------------------------------------------------------------
// Order game — tap items smallest→largest
// ---------------------------------------------------------------------------

class _OrderGame extends ConsumerStatefulWidget {
  const _OrderGame({
    required this.game,
    required this.color,
    required this.color2,
    required this.onWin,
  });

  final MiniGameSpec game;
  final Color color;
  final Color color2;
  final VoidCallback onWin;

  @override
  ConsumerState<_OrderGame> createState() => _OrderGameState();
}

class _OrderGameState extends ConsumerState<_OrderGame> {
  late List<Map<String, Object>> _items;
  late List<Map<String, Object>> _shuffled;
  int _nextExpected = 0;
  final Set<int> _done = {};
  int? _shaking; // index of the wrong-tapped item
  bool _won = false;

  @override
  void initState() {
    super.initState();
    final rawItems = widget.game.params['items'];
    _items = (rawItems as List<Object>)
        .cast<Map<String, Object>>()
        .toList();
    // Sort by 's' to know correct order, then shuffle for display
    _items.sort((a, b) => (a['s'] as int).compareTo(b['s'] as int));
    _shuffled = List.from(_items)..shuffle(Random());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final say = widget.game.params['say'] as String? ?? '';
      if (say.isNotEmpty) {
        ref.read(ttsServiceProvider).speak(say);
      }
    });
  }

  void _tap(int shuffledIdx) {
    if (_won) return;
    final tappedItem = _shuffled[shuffledIdx];
    if (_done.contains(shuffledIdx)) return;

    final tappedOrder = _items.indexOf(tappedItem);
    if (tappedOrder == _nextExpected) {
      // Correct!
      ref.read(sfxServiceProvider).play(Sfx.pop);
      setState(() {
        _done.add(shuffledIdx);
        _nextExpected++;
      });
      if (_nextExpected >= _items.length) {
        _won = true;
        Future.delayed(const Duration(milliseconds: 600), widget.onWin);
      }
    } else {
      // Wrong order — shake the item
      ref.read(sfxServiceProvider).play(Sfx.wrong);
      setState(() => _shaking = shuffledIdx);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _shaking = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.game.params['say'] as String? ?? 'Tap in order!',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: WqColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(_shuffled.length, (i) {
              final item = _shuffled[i];
              final isDone = _done.contains(i);
              final isShaking = _shaking == i;
              return _OrderItem(
                key: ValueKey('order-item-$i'),
                emoji: item['e'] as String,
                done: isDone,
                shaking: isShaking,
                color: widget.color,
                onTap: () => _tap(i),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _items.length,
              (i) => Container(
                key: ValueKey('order-step-$i'),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      i < _nextExpected ? widget.color : WqColors.lines,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  const _OrderItem({
    super.key,
    required this.emoji,
    required this.done,
    required this.shaking,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final bool done;
  final bool shaking;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 100),
      offset: shaking ? const Offset(0.05, 0) : Offset.zero,
      curve: Curves.elasticIn,
      child: GestureDetector(
        onTap: done ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color:
                done ? color.withValues(alpha: 0.2) : WqColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done ? color : (shaking ? WqColors.coral : WqColors.lines),
              width: done ? 2.5 : (shaking ? 2.5 : 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x18000000),
                blurRadius: shaking ? 0 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 36)),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Build game — tap stack pieces bottom→top
// ---------------------------------------------------------------------------

class _BuildGame extends ConsumerStatefulWidget {
  const _BuildGame({
    required this.game,
    required this.color,
    required this.color2,
    required this.onWin,
  });

  final MiniGameSpec game;
  final Color color;
  final Color color2;
  final VoidCallback onWin;

  @override
  ConsumerState<_BuildGame> createState() => _BuildGameState();
}

class _BuildGameState extends ConsumerState<_BuildGame> {
  late List<String> _pieces;
  int _placed = 0;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    final rawPieces = widget.game.params['pieces'];
    _pieces = (rawPieces as List<Object>).cast<String>().toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final say = widget.game.params['say'] as String? ?? '';
      if (say.isNotEmpty) {
        ref.read(ttsServiceProvider).speak(say);
      }
    });
  }

  void _tapPiece(int index) {
    if (_won || index != _placed) {
      if (index != _placed) {
        ref.read(sfxServiceProvider).play(Sfx.wrong);
      }
      return;
    }
    ref.read(sfxServiceProvider).play(Sfx.pop);
    setState(() => _placed++);
    if (_placed >= _pieces.length) {
      _won = true;
      Future.delayed(const Duration(milliseconds: 800), widget.onWin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.game.params['say'] as String? ?? 'Tap each piece!',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: WqColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Build silhouette — pieces stack bottom-up
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tap the pieces in order!',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: WqColors.softInk,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(_pieces.length, (i) {
                    final isPlaced = i < _placed;
                    final isNext = i == _placed;
                    return GestureDetector(
                      key: ValueKey('build-piece-$i'),
                      onTap: () => _tapPiece(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isPlaced
                              ? widget.color.withValues(alpha: 0.2)
                              : WqColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isPlaced
                                ? widget.color
                                : (isNext
                                    ? WqColors.yellow
                                    : WqColors.lines),
                            width: isNext ? 3 : 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isPlaced ? _pieces[i] : '❓',
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Progress
          LinearProgressIndicator(
            value: _pieces.isEmpty ? 0 : _placed / _pieces.length,
            backgroundColor: WqColors.lines,
            valueColor: AlwaysStoppedAnimation<Color>(widget.color),
          ),
          const SizedBox(height: 8),
          Text(
            '$_placed / ${_pieces.length} pieces placed',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: WqColors.softInk,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Decorate game — tap 6 glowing spots
// ---------------------------------------------------------------------------

class _DecorateGame extends ConsumerStatefulWidget {
  const _DecorateGame({
    required this.game,
    required this.color,
    required this.color2,
    required this.onWin,
  });

  final MiniGameSpec game;
  final Color color;
  final Color color2;
  final VoidCallback onWin;

  @override
  ConsumerState<_DecorateGame> createState() => _DecorateGameState();
}

class _DecorateGameState extends ConsumerState<_DecorateGame> {
  late int _totalSpots;
  late String _spotEmoji;
  late String _baseEmoji;
  final Set<int> _placed = {};
  bool _won = false;

  @override
  void initState() {
    super.initState();
    final p = widget.game.params;
    _totalSpots = (p['n'] as int?) ?? 5;
    _spotEmoji = p['spot'] as String? ?? '⭐';
    _baseEmoji = p['base'] as String? ?? '🖼️';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final say = p['say'] as String? ?? '';
      if (say.isNotEmpty) {
        ref.read(ttsServiceProvider).speak(say);
      }
    });
  }

  void _tapSpot(int index) {
    if (_won || _placed.contains(index)) return;
    ref.read(sfxServiceProvider).play(Sfx.pop);
    setState(() => _placed.add(index));
    if (_placed.length >= _totalSpots) {
      _won = true;
      Future.delayed(const Duration(milliseconds: 600), widget.onWin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.game.params;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            p['say'] as String? ?? 'Tap the spots!',
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: WqColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Base object display
          Text(_baseEmoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 20),

          // Spots grid
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: List.generate(_totalSpots, (i) {
              final isPlaced = _placed.contains(i);
              return GestureDetector(
                key: ValueKey('decorate-spot-$i'),
                onTap: () => _tapSpot(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPlaced
                        ? widget.color.withValues(alpha: 0.2)
                        : WqColors.yellow.withValues(alpha: 0.15),
                    border: Border.all(
                      color: isPlaced ? widget.color : WqColors.yellow,
                      width: 2.5,
                    ),
                    boxShadow: isPlaced
                        ? null
                        : [
                            BoxShadow(
                              color:
                                  WqColors.yellow.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      isPlaced ? _spotEmoji : '✨',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            '${_placed.length} / $_totalSpots',
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Find game — mini SpotScene
// ---------------------------------------------------------------------------

class _FindGame extends ConsumerStatefulWidget {
  const _FindGame({
    required this.game,
    required this.color,
    required this.color2,
    required this.onWin,
  });

  final MiniGameSpec game;
  final Color color;
  final Color color2;
  final VoidCallback onWin;

  @override
  ConsumerState<_FindGame> createState() => _FindGameState();
}

class _FindGameState extends ConsumerState<_FindGame> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final say = widget.game.params['say'] as String? ?? '';
      if (say.isNotEmpty) {
        ref.read(ttsServiceProvider).speak(say);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.game.params;
    final target = p['target'] as String? ?? '❓';
    final n = (p['n'] as int?) ?? 4;
    final decoRaw = p['deco'] as List<Object>?;
    final deco = decoRaw?.cast<String>() ?? const <String>[];

    return SpotScene(
      key: const Key('find-mini-game'),
      goals: [SpotGoal(char: target, count: n, label: 'targets')],
      mode: SpotMode.find,
      decoys: deco.isNotEmpty ? deco : ['🌿', '🍃', '☁️', '🪨'],
      decoyCount: 16,
      bg: widget.color2.withValues(alpha: 0.15),
      onComplete: widget.onWin,
    );
  }
}
