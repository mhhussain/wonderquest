import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/art.dart';
import '../core/save_controller.dart';
import '../domain/level_dealer.dart';
import '../theme/wq_colors.dart';

// ---------------------------------------------------------------------------
// LevelSelect
// ---------------------------------------------------------------------------

/// Grid of "Game N" tiles with a ⭐ badge on completed ones.
///
/// Reads `saveControllerProvider.value?.levels[typeId]` to determine which
/// games are done. Calls [onPlay] with the chosen game index when a tile is
/// tapped.
///
/// The grid has at most 5 columns and centres inside the available width.
/// Each tile is at least 80 × 80 logical pixels (well above the 64 px
/// hit-target floor).
class LevelSelect extends ConsumerWidget {
  const LevelSelect({
    super.key,
    required this.typeId,
    required this.games,
    required this.title,
    required this.color,
    required this.onPlay,
  });

  /// Unique identifier for this game type (matches `SaveData.levels` key).
  final String typeId;

  /// Total number of game tiles to display.
  final int games;

  /// Human-readable heading shown above the grid (e.g. `'Letter Adventure'`).
  final String title;

  /// Background colour for each tile (comes from the land's WqColors entry).
  final Color color;

  /// Called with the zero-based game index when the user picks a tile.
  final void Function(int gameIndex) onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveControllerProvider).value;
    final done = save?.levels[typeId] ?? <bool>[];

    final doneCount = done.where((b) => b).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    color: WqColors.ink,
                  ),
                ),
              ),
              Text(
                '$doneCount / $games done',
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: WqColors.softInk,
                ),
              ),
            ],
          ),
        ),

        // ── Grid ────────────────────────────────────────────────────────────
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _LevelGrid(
                games: games,
                done: done,
                color: color,
                onPlay: onPlay,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Internal: renders the tappable tile grid.
class _LevelGrid extends StatelessWidget {
  const _LevelGrid({
    required this.games,
    required this.done,
    required this.color,
    required this.onPlay,
  });

  final int games;
  final List<bool> done;
  final Color color;
  final void Function(int) onPlay;

  @override
  Widget build(BuildContext context) {
    final cols = games.clamp(1, 5);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = cols * 168.0;
        final width = constraints.maxWidth.clamp(0.0, maxWidth);
        return SizedBox(
          width: width,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: games,
            itemBuilder: (context, index) {
              final isDone = index < done.length && done[index];
              return _LevelTile(
                key: ValueKey('level-tile-$index'),
                index: index,
                isDone: isDone,
                color: color,
                onTap: () => onPlay(index),
              );
            },
          ),
        );
      },
    );
  }
}

/// One "Game N" tile with optional ⭐ badge.
class _LevelTile extends StatelessWidget {
  const _LevelTile({
    super.key,
    required this.index,
    required this.isDone,
    required this.color,
    required this.onTap,
  });

  final int index;
  final bool isDone;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shadowColor = HSLColor.fromColor(color)
        .withLightness(
          (HSLColor.fromColor(color).lightness - 0.15).clamp(0.0, 1.0),
        )
        .toColor();

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: shadowColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Game number label
                Text(
                  'Game ${index + 1}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                // ⭐ badge, top-right corner when complete
                if (isDone)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Art.glyph('star', size: 22),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GameDeck
// ---------------------------------------------------------------------------

/// Deals [perGame] questions from [pool] once (seeded by `typeId + gameIndex`
/// so re-entry always produces the same deck), then steps the child through
/// them one at a time via [questionBuilder].
///
/// Shows a row of progress dots (filled = answered). Calls [onComplete] after
/// the last question is answered. The caller is responsible for calling
/// `markLevelDone` and showing the [RewardModal].
///
/// Seeding formula (verbatim from spec):
/// ```dart
/// Random(typeId.hashCode ^ gameIndex)
/// ```
class GameDeck<T> extends StatefulWidget {
  const GameDeck({
    super.key,
    required this.typeId,
    required this.gameIndex,
    required this.pool,
    required this.games,
    required this.perGame,
    required this.questionBuilder,
    required this.onComplete,
  });

  /// Game type identifier, used for seeding and save-state lookup.
  final String typeId;

  /// Zero-based index of this game (used for seeding).
  final int gameIndex;

  /// Full question pool for this game type.
  final List<T> pool;

  /// Total number of games in this level (passed to [dealGames]).
  final int games;

  /// Number of questions per game (also the number of dot indicators).
  final int perGame;

  /// Build the question UI. Call [advance] when the player answers correctly.
  final Widget Function(BuildContext context, T item, void Function() advance)
      questionBuilder;

  /// Fired once after all [perGame] questions have been answered.
  final void Function() onComplete;

  @override
  State<GameDeck<T>> createState() => _GameDeckState<T>();
}

class _GameDeckState<T> extends State<GameDeck<T>> {
  late final List<T> _deck;
  int _current = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    // Deterministic seeding per spec: typeId.hashCode ^ gameIndex
    final rng = Random(widget.typeId.hashCode ^ widget.gameIndex);
    final all = dealGames<T>(
      pool: widget.pool,
      games: widget.games,
      perGame: widget.perGame,
      random: rng,
    );
    _deck = all[widget.gameIndex];
  }

  void _advance() {
    if (_completed) return;
    final next = _current + 1;
    if (next >= _deck.length) {
      setState(() {
        _current = next;
        _completed = true;
      });
      widget.onComplete();
    } else {
      setState(() => _current = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_completed || _current >= _deck.length) {
      // Transient state while onComplete navigates away.
      return const SizedBox.shrink();
    }

    final item = _deck[_current];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Progress dots ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _ProgressDots(
            total: _deck.length,
            answered: _current,
          ),
        ),

        // ── Question content ─────────────────────────────────────────────
        Expanded(
          child: widget.questionBuilder(context, item, _advance),
        ),
      ],
    );
  }
}

/// A row of circular dot indicators: filled = answered, outline = pending.
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.total, required this.answered});

  final int total;
  final int answered;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isFilled = i < answered;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? WqColors.teal : Colors.transparent,
              border: Border.all(
                color: WqColors.teal,
                width: 2,
              ),
            ),
          ),
        );
      }),
    );
  }
}
