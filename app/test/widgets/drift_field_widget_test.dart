import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/audio/sfx_service.dart';
import 'package:wonder_quest/widgets/drift_field_widget.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _FakeSfxService implements SfxService {
  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> playWhaleCall(double baseFreqHz) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap({
  required List<String> itemChars,
  required VoidCallback onAllCollected,
  Random? random,
}) {
  return ProviderScope(
    overrides: [
      sfxServiceProvider.overrideWithValue(_FakeSfxService()),
    ],
    child: MaterialApp(
      home: DriftFieldWidget(
        itemChars: itemChars,
        mascotKey: 'rexy',
        onAllCollected: onAllCollected,
        random: random,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DriftFieldWidget', () {
    testWidgets(
      'renders mascot and item glyphs after initialisation',
      (tester) async {
        // Seeded Random: an unseeded fallback occasionally spawns the item
        // within collect radius of the mascot, collecting it on tick 1.
        await tester.pumpWidget(_wrap(
          itemChars: const ['🐋'],
          onAllCollected: () {},
          random: Random(2),
        ));

        // post-frame callback → engine init, ticker.start()
        await tester.pump();
        // first tick (baseline) + rebuild with items
        await tester.pump();
        // second tick (items rendered at positions)
        await tester.pump();

        expect(
          find.byKey(const ValueKey('drift-mascot')),
          findsOneWidget,
          reason: 'mascot should be rendered',
        );
        expect(
          find.byKey(const ValueKey('drift-item-0')),
          findsOneWidget,
          reason: 'item 0 should be rendered',
        );
      },
    );

    testWidgets(
      'drag mascot onto item updates collected count text',
      (tester) async {
        var allCollectedCalled = false;

        // Use seeded Random so item placement is deterministic.
        // Both the widget and the mirror field use Random(1) independently,
        // producing identical starting positions.
        const seed = 1;

        await tester.pumpWidget(_wrap(
          itemChars: const ['🐋'],
          onAllCollected: () => allCollectedCalled = true,
          random: Random(seed),
        ));

        // post-frame → engine init
        await tester.pump();
        // first tick (baseline — skipped internally)
        await tester.pump();
        // second tick: items now rendered at their (slightly moved) positions
        await tester.pump();

        final item0 = find.byKey(const ValueKey('drift-item-0'));
        expect(item0, findsOneWidget, reason: 'item 0 must be in the tree');

        final mascotFinder = find.byKey(const ValueKey('drift-mascot'));
        expect(mascotFinder, findsOneWidget, reason: 'mascot must be in the tree');

        // Read current rendered positions from the widget tree.
        final item0Center = tester.getCenter(item0);
        final mascotCenter = tester.getCenter(mascotFinder);

        // Drag mascot to where item 0 currently is.
        await tester.drag(mascotFinder, item0Center - mascotCenter);

        // One more tick: collectAt fires with mascot at item 0's position.
        await tester.pump();

        // Count badge must now read 1/1.
        expect(
          find.text('1/1'),
          findsOneWidget,
          reason: 'count badge should show 1/1 after collecting the item',
        );

        // Allow the 500 ms onAllCollected delay to elapse.
        await tester.pump(const Duration(milliseconds: 600));
        expect(allCollectedCalled, isTrue, reason: 'onAllCollected should have fired');
      },
    );

    testWidgets(
      'count badge starts at 0/N',
      (tester) async {
        // Seeded Random: an unseeded fallback occasionally spawns an item
        // within collect radius of the mascot, making the badge read 1/3.
        await tester.pumpWidget(_wrap(
          itemChars: const ['🐋', '🦑', '🐙'],
          onAllCollected: () {},
          random: Random(2),
        ));

        // post-frame → engine init + rebuild.
        // Only 2 pumps: the first-tick handler just sets the baseline and returns
        // without calling collectAt, so count is guaranteed to be 0 here.
        await tester.pump();
        await tester.pump();

        expect(find.text('0/3'), findsOneWidget, reason: 'initial count should be 0/3');
      },
    );
  });
}
