import 'dart:math';
import 'dart:ui';

/// A single drifting collectible in a [DriftField].
class DriftItem {
  DriftItem({
    required this.id,
    required this.char,
    required this.pos,
    required this.velocity,
    this.collected = false,
  });

  final int id;
  final String char;

  /// Current center position in field-local coordinates.
  Offset pos;

  /// Current velocity in pixels per second.
  Offset velocity;

  /// Whether this item has been collected.
  bool collected;
}

/// Pure-Dart engine for a drift-collect mini-game.
///
/// Items are placed at random positions within [bounds] (padded by [itemRadius])
/// and given slow random velocities. Each [tick] moves items and bounces them
/// off the field edges. [collectAt] marks items within [dragRadius] of [dragPos]
/// as collected and returns their ids. [allCollected] signals when the game is won.
///
/// Inject a seeded [Random] for deterministic testing.
class DriftField {
  /// Creates a [DriftField] with [chars.length] items at random positions.
  ///
  /// Each item starts within the field padded by [itemRadius] and is given a
  /// random velocity in the range 30–80 px/s.
  DriftField({
    required List<String> chars,
    required Size bounds,
    required double itemRadius,
    required Random random,
  })  : _bounds = bounds,
        _itemRadius = itemRadius {
    _items = List.generate(chars.length, (i) {
      final x = itemRadius + random.nextDouble() * (bounds.width - 2 * itemRadius);
      final y = itemRadius + random.nextDouble() * (bounds.height - 2 * itemRadius);
      final angle = random.nextDouble() * 2 * pi;
      final speed = 30 + random.nextDouble() * 50; // px/s
      return DriftItem(
        id: i,
        char: chars[i],
        pos: Offset(x, y),
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
      );
    });
  }

  final Size _bounds;
  final double _itemRadius;
  late final List<DriftItem> _items;

  /// All items in this field. Callers may read but should not modify directly.
  List<DriftItem> get items => List.unmodifiable(_items);

  /// Advances all uncollected items by [dtSeconds] seconds.
  ///
  /// Items bounce elastically off the field edges: when an item crosses an
  /// edge the relevant velocity component is sign-flipped and the position is
  /// clamped to the edge, so items always remain within bounds.
  void tick(double dtSeconds) {
    for (final item in _items) {
      if (item.collected) continue;

      var x = item.pos.dx + item.velocity.dx * dtSeconds;
      var y = item.pos.dy + item.velocity.dy * dtSeconds;
      var vx = item.velocity.dx;
      var vy = item.velocity.dy;

      // Horizontal bounce.
      if (x < _itemRadius) {
        x = _itemRadius;
        vx = vx.abs(); // flip to positive
      } else if (x > _bounds.width - _itemRadius) {
        x = _bounds.width - _itemRadius;
        vx = -vx.abs(); // flip to negative
      }

      // Vertical bounce.
      if (y < _itemRadius) {
        y = _itemRadius;
        vy = vy.abs();
      } else if (y > _bounds.height - _itemRadius) {
        y = _bounds.height - _itemRadius;
        vy = -vy.abs();
      }

      item.pos = Offset(x, y);
      item.velocity = Offset(vx, vy);
    }
  }

  /// Collects uncollected items whose center is within [dragRadius] of [dragPos].
  ///
  /// Returns the ids of newly collected items. An item that has already been
  /// collected will never appear in the result.
  List<int> collectAt(Offset dragPos, double dragRadius) {
    final newlyCollected = <int>[];
    for (final item in _items) {
      if (item.collected) continue;
      final dx = item.pos.dx - dragPos.dx;
      final dy = item.pos.dy - dragPos.dy;
      if (sqrt(dx * dx + dy * dy) < dragRadius) {
        item.collected = true;
        newlyCollected.add(item.id);
      }
    }
    return newlyCollected;
  }

  /// `true` once every item has been collected.
  bool get allCollected => _items.every((item) => item.collected);
}
