import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/domain/drift_field.dart';

void main() {
  const bounds = Size(400, 300);
  const itemRadius = 20.0;

  DriftField makeField(List<String> chars, {int seed = 0}) {
    return DriftField(
      chars: chars,
      bounds: bounds,
      itemRadius: itemRadius,
      random: Random(seed),
    );
  }

  group('DriftField engine', () {
    test('tick moves items by velocity × dt', () {
      final field = makeField(['🐋']);
      final item = field.items.first;

      final initialPos = item.pos;
      field.tick(0.1);

      // Item should have moved (unless velocity happens to be exactly zero,
      // which is virtually impossible with random generation).
      expect(
        field.items.first.pos,
        isNot(equals(initialPos)),
        reason: 'Item should move after a tick',
      );
    });

    test('items start within bounds padded by itemRadius', () {
      final field = makeField(['🐋', '🦑', '🐙']);
      for (final item in field.items) {
        expect(item.pos.dx, greaterThanOrEqualTo(itemRadius));
        expect(item.pos.dy, greaterThanOrEqualTo(itemRadius));
        expect(item.pos.dx, lessThanOrEqualTo(bounds.width - itemRadius));
        expect(item.pos.dy, lessThanOrEqualTo(bounds.height - itemRadius));
      }
    });

    test('item heading past left edge bounces: vx flips positive, pos clamped', () {
      // Place item near left edge heading left.
      final field = DriftField(
        chars: ['🐋'],
        bounds: bounds,
        itemRadius: itemRadius,
        random: Random(0),
      );
      final item = field.items.first;

      // Force item to be near left edge with leftward velocity.
      item.pos = const Offset(itemRadius + 1, 150);
      item.velocity = const Offset(-100, 0); // heading left

      field.tick(1.0); // large dt → would fly past edge

      expect(
        field.items.first.velocity.dx,
        greaterThan(0),
        reason: 'vx should flip to positive after bouncing off left edge',
      );
      expect(
        field.items.first.pos.dx,
        greaterThanOrEqualTo(itemRadius),
        reason: 'x should not go below itemRadius',
      );
    });

    test('item heading past right edge bounces: vx flips negative, pos clamped', () {
      final field = makeField(['🐋']);
      final item = field.items.first;

      item.pos = const Offset(379, 150); // bounds.width(400) - itemRadius(20) - 1
      item.velocity = const Offset(100, 0); // heading right

      field.tick(1.0);

      expect(
        field.items.first.velocity.dx,
        lessThan(0),
        reason: 'vx should flip to negative after bouncing off right edge',
      );
      expect(
        field.items.first.pos.dx,
        lessThanOrEqualTo(bounds.width - itemRadius),
        reason: 'x should not exceed bounds.width - itemRadius',
      );
    });

    test('item heading past top edge bounces: vy flips positive, pos clamped', () {
      final field = makeField(['🐋']);
      final item = field.items.first;

      item.pos = const Offset(200, itemRadius + 1);
      item.velocity = const Offset(0, -100); // heading up

      field.tick(1.0);

      expect(
        field.items.first.velocity.dy,
        greaterThan(0),
        reason: 'vy should flip to positive after bouncing off top edge',
      );
      expect(
        field.items.first.pos.dy,
        greaterThanOrEqualTo(itemRadius),
        reason: 'y should not go above itemRadius',
      );
    });

    test('item heading past bottom edge bounces: vy flips negative, pos clamped', () {
      final field = makeField(['🐋']);
      final item = field.items.first;

      item.pos = const Offset(200, 279); // bounds.height(300) - itemRadius(20) - 1
      item.velocity = const Offset(0, 100); // heading down

      field.tick(1.0);

      expect(
        field.items.first.velocity.dy,
        lessThan(0),
        reason: 'vy should flip to negative after bouncing off bottom edge',
      );
      expect(
        field.items.first.pos.dy,
        lessThanOrEqualTo(bounds.height - itemRadius),
        reason: 'y should not exceed bounds.height - itemRadius',
      );
    });

    test('collectAt returns ids of items within dragRadius', () {
      final field = makeField(['🐋', '🦑']);

      // Place item 0 at a known location.
      field.items[0].pos = const Offset(100, 100);
      // Place item 1 far away.
      field.items[1].pos = const Offset(350, 250);

      final collected = field.collectAt(const Offset(100, 100), 60);

      expect(collected, contains(0), reason: 'Item 0 is at dragPos — should be collected');
      expect(collected, isNot(contains(1)), reason: 'Item 1 is far away — should not be collected');
    });

    test('collectAt never returns the same id twice (idempotent)', () {
      final field = makeField(['🐋']);
      field.items.first.pos = const Offset(100, 100);

      final first = field.collectAt(const Offset(100, 100), 60);
      expect(first, equals([0]));

      final second = field.collectAt(const Offset(100, 100), 60);
      expect(second, isEmpty, reason: 'Already-collected item must not be returned again');
    });

    test('collected items are skipped by tick', () {
      final field = makeField(['🐋']);
      final item = field.items.first;
      item.pos = const Offset(100, 100);

      // Collect the item.
      field.collectAt(const Offset(100, 100), 60);
      expect(item.collected, isTrue);

      final posAfterCollection = item.pos;
      field.tick(1.0); // should NOT move collected items

      expect(
        field.items.first.pos,
        equals(posAfterCollection),
        reason: 'Collected items should not move during tick',
      );
    });

    test('allCollected is false initially', () {
      final field = makeField(['🐋', '🦑', '🐙']);
      expect(field.allCollected, isFalse);
    });

    test('allCollected becomes true after collecting every item', () {
      final field = makeField(['🐋', '🦑']);

      // Place items at known locations and collect each.
      field.items[0].pos = const Offset(50, 50);
      field.items[1].pos = const Offset(50, 50);

      field.collectAt(const Offset(50, 50), 80);

      expect(field.allCollected, isTrue, reason: 'All items collected → allCollected should be true');
    });

    test('allCollected remains false until ALL items are collected', () {
      final field = makeField(['🐋', '🦑', '🐙']);

      // Place item 0 at collection point, others far away.
      field.items[0].pos = const Offset(100, 100);
      field.items[1].pos = const Offset(350, 250);
      field.items[2].pos = const Offset(300, 200);

      field.collectAt(const Offset(100, 100), 60); // collects only item 0

      expect(
        field.allCollected,
        isFalse,
        reason: 'Items 1 and 2 are still uncollected',
      );
    });
  });
}
