import 'dart:math';
import 'dart:ui';

/// A single goal for a SpotScene: find or count [count] items matching [char].
class SpotGoal {
  const SpotGoal({
    required this.char,
    required this.count,
    required this.label,
  });

  final String char;
  final int count;
  final String label;
}

/// Play mode for a SpotScene.
enum SpotMode { find, count }

/// A single item placed in the scatter scene.
class PlacedItem {
  const PlacedItem({
    required this.char,
    required this.pos,
    required this.size,
    required this.isTarget,
    required this.id,
  });

  final String char;
  final Offset pos;
  final double size;
  final bool isTarget;
  final int id;
}

/// Places items on a canvas using a jittered grid.
///
/// **Algorithm**: divide the canvas into `ceil(sqrt(total))` columns and
/// `ceil(total / cols)` rows. Shuffle all cells, assign one item per cell,
/// then jitter each item's position within 25 %–75 % of the cell dimensions.
/// This guarantees adjacent items are always at least **0.5 × minCellSize**
/// apart (proof: min gap along each axis is `cellDim × (1 + 0.25 − 0.75) =
/// 0.5 × cellDim ≥ 0.5 × minCellSize`).
class SpotSceneLayout {
  const SpotSceneLayout._();

  /// Default decoy pool used when [decoys] is empty.
  static const _defaultDecoys = ['🌿', '🍃', '☁️', '🪨'];

  /// Base item size in logical pixels (individual items vary ±20 %).
  static const _baseSize = 48.0;

  static List<PlacedItem> place({
    required List<SpotGoal> goals,
    required List<String> decoys,
    required int decoyCount,
    required Size canvas,
    required Random random,
  }) {
    // 1. Build the flat list of (char, isTarget) pairs.
    final items = <({String char, bool isTarget})>[];
    for (final goal in goals) {
      for (var k = 0; k < goal.count; k++) {
        items.add((char: goal.char, isTarget: true));
      }
    }
    final pool = decoys.isNotEmpty ? decoys : _defaultDecoys;
    for (var k = 0; k < decoyCount; k++) {
      final ch = pool[random.nextInt(pool.length)];
      items.add((char: ch, isTarget: false));
    }

    final n = items.length;
    if (n == 0) return [];

    // 2. Grid dimensions.
    final cols = sqrt(n.toDouble()).ceil().clamp(1, n);
    final rows = (n / cols).ceil();

    // 3. Shuffle cells and pick the first n.
    final cells = [
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < cols; c++) (r: r, c: c),
    ]..shuffle(random);
    final picked = cells.take(n).toList();

    // 4. Cell dimensions.
    final cw = canvas.width / cols;
    final ch = canvas.height / rows;

    // 5. Shuffle items so targets and decoys are interleaved randomly.
    items.shuffle(random);

    // 6. Place each item with jitter in [0.25, 0.75) of cell size.
    final placed = <PlacedItem>[];
    for (var i = 0; i < n; i++) {
      final cell = picked[i];
      final jx = 0.25 + random.nextDouble() * 0.5;
      final jy = 0.25 + random.nextDouble() * 0.5;
      final x = cell.c * cw + jx * cw;
      final y = cell.r * ch + jy * ch;
      // Size varies ±20 % around the base size.
      final size = _baseSize * (0.8 + random.nextDouble() * 0.4);
      placed.add(PlacedItem(
        char: items[i].char,
        pos: Offset(x, y),
        size: size,
        isTarget: items[i].isTarget,
        id: i,
      ));
    }
    return placed;
  }
}

/// Tracks tap state for a SpotScene session.
class SpotSceneState {
  SpotSceneState(this.goals, this.mode);

  final List<SpotGoal> goals;
  final SpotMode mode;

  /// `id → char` for every target that has been successfully tapped.
  final Map<int, String> _found = {};

  /// Tap [item].
  ///
  /// Returns `true` if [item] is an un-found target (first tap on this item).
  /// Returns `false` for decoys or already-found targets.
  bool tap(PlacedItem item) {
    if (!item.isTarget) return false;
    if (_found.containsKey(item.id)) return false;
    _found[item.id] = item.char;
    return true;
  }

  /// Number of found items for each target character.
  Map<String, int> get foundByChar {
    final map = <String, int>{};
    for (final char in _found.values) {
      map[char] = (map[char] ?? 0) + 1;
    }
    return map;
  }

  /// `true` once every goal's required [SpotGoal.count] has been found.
  bool get complete {
    final fbc = foundByChar;
    for (final goal in goals) {
      if ((fbc[goal.char] ?? 0) < goal.count) return false;
    }
    return true;
  }
}
