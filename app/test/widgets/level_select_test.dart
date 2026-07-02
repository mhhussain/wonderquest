import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';
import 'package:wonder_quest/widgets/level_select.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// In-memory [SaveFileStore] — same pattern as hud_test.dart.
/// Uses [Future.value] (microtask-based) so FakeAsync zone can resolve it.
class _MemStore extends SaveFileStore {
  _MemStore() : super(Directory.systemTemp);

  SaveData? _seeded;

  @override
  Future<SaveData> load() =>
      Future.value(_seeded ?? SaveData.initial(profileId: 'mem'));

  @override
  Future<void> save(SaveData data) async => _seeded = data;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps [child] in a ProviderScope + MaterialApp using [store].
Widget _harness({required _MemStore store, required Widget child}) {
  return ProviderScope(
    overrides: [saveStoreProvider.overrideWithValue(store)],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

/// Settles the async provider after pump (2 pumps needed for AsyncNotifier).
Future<void> _settleProvider(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LevelSelect', () {
    testWidgets('renders correct number of game tiles (10 tiles)', (tester) async {
      final store = _MemStore();
      const typeId = 'letter';
      const games = 10;

      await tester.pumpWidget(
        _harness(
          store: store,
          child: LevelSelect(
            typeId: typeId,
            games: games,
            title: 'Letter Adventure',
            color: const Color(0xFF4AA8E0),
            onPlay: (_) {},
          ),
        ),
      );
      await _settleProvider(tester);

      // Should have exactly 10 tiles, one per game.
      expect(find.byKey(const ValueKey('level-tile-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('level-tile-9')), findsOneWidget);
      expect(find.byKey(const ValueKey('level-tile-10')), findsNothing);

      // The tiles show "Game N" labels.
      expect(find.text('Game 1'), findsOneWidget);
      expect(find.text('Game 10'), findsOneWidget);
    });

    testWidgets('stars completed tiles from seeded save data', (tester) async {
      final store = _MemStore();
      const typeId = 'letter';
      const games = 5;

      // Seed: games 0 and 2 are done, 1/3/4 are not.
      await store.save(
        SaveData.initial(profileId: 'test').copyWith(
          levels: {
            typeId: [true, false, true, false, false],
          },
        ),
      );

      await tester.pumpWidget(
        _harness(
          store: store,
          child: LevelSelect(
            typeId: typeId,
            games: games,
            title: 'Letter Adventure',
            color: const Color(0xFF4AA8E0),
            onPlay: (_) {},
          ),
        ),
      );
      await _settleProvider(tester);

      // 2 out of 5 done — header counter.
      expect(find.text('2 / 5 done'), findsOneWidget);

      // Stars come from Art.glyph('star') which renders '⭐'.
      // Tile 0 (done) and tile 2 (done) should each show a star.
      // Tile 1 (not done) should not.
      // We verify by counting star emoji occurrences.
      expect(find.text('⭐'), findsNWidgets(2));
    });

    testWidgets('calls onPlay with correct index when tile is tapped',
        (tester) async {
      final store = _MemStore();
      int? tappedIndex;

      await tester.pumpWidget(
        _harness(
          store: store,
          child: LevelSelect(
            typeId: 'math',
            games: 4,
            title: 'Math Lab',
            color: const Color(0xFFFF8A3D),
            onPlay: (i) => tappedIndex = i,
          ),
        ),
      );
      await _settleProvider(tester);

      // Tap game 2 (index 1).
      await tester.tap(find.byKey(const ValueKey('level-tile-1')));
      await tester.pump();

      expect(tappedIndex, equals(1));
    });

    testWidgets('shows 0 / N done when no levels saved for typeId',
        (tester) async {
      final store = _MemStore();

      await tester.pumpWidget(
        _harness(
          store: store,
          child: LevelSelect(
            typeId: 'unknown-type',
            games: 3,
            title: 'Unknown',
            color: const Color(0xFF7BC043),
            onPlay: (_) {},
          ),
        ),
      );
      await _settleProvider(tester);

      expect(find.text('0 / 3 done'), findsOneWidget);
      // No stars when nothing is done.
      expect(find.text('⭐'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // GameDeck
  // -------------------------------------------------------------------------

  group('GameDeck', () {
    /// Minimal string pool for tests.
    const pool = ['A', 'B', 'C', 'D', 'E'];

    testWidgets(
        'advances through all perGame questions and calls onComplete once',
        (tester) async {
      const perGame = 3;
      int completeCalls = 0;
      final advanced = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameDeck<String>(
              typeId: 'test',
              gameIndex: 0,
              pool: pool,
              games: 2,
              perGame: perGame,
              questionBuilder: (ctx, item, advance) {
                return ElevatedButton(
                  key: ValueKey('q-$item'),
                  onPressed: () {
                    advanced.add(item);
                    advance();
                  },
                  child: Text(item),
                );
              },
              onComplete: () => completeCalls++,
            ),
          ),
        ),
      );

      // Answer all perGame questions.
      for (int i = 0; i < perGame; i++) {
        // Find the currently visible question button and tap it.
        final buttons = tester.widgetList<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(buttons, isNotEmpty,
            reason: 'Expected a question button on step $i');
        await tester.tap(find.byType(ElevatedButton).first);
        await tester.pump();
      }

      // onComplete fires exactly once.
      expect(completeCalls, equals(1));
      // All perGame questions were answered.
      expect(advanced.length, equals(perGame));
    });

    testWidgets('shows progress dots row with correct total count',
        (tester) async {
      const perGame = 4;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameDeck<String>(
              typeId: 'test-dots',
              gameIndex: 0,
              pool: pool,
              games: 2,
              perGame: perGame,
              questionBuilder: (ctx, item, advance) =>
                  Text(item, key: ValueKey('item-$item')),
              onComplete: () {},
            ),
          ),
        ),
      );

      // The _ProgressDots widget renders `perGame` Container dots.
      // Each dot is a Container with BoxDecoration — count them.
      final containers = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      expect(containers, findsNWidgets(perGame));
    });

    testWidgets('is deterministic: same typeId+gameIndex always deals same deck',
        (tester) async {
      const perGame = 3;
      final seenItems1 = <String>[];
      final seenItems2 = <String>[];

      // First deck — key 'run1' so Flutter creates a fresh state.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameDeck<String>(
              key: const ValueKey('run1'),
              typeId: 'det-test',
              gameIndex: 2,
              pool: pool,
              games: 4,
              perGame: perGame,
              questionBuilder: (ctx, item, advance) {
                seenItems1.add(item);
                // Auto-advance so we drain the deck quickly.
                Future.microtask(advance);
                return Text(item);
              },
              onComplete: () {},
            ),
          ),
        ),
      );
      // Each pump: microtask runs advance() → setState dirty → next pump rebuilds.
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Second deck — key 'run2' forces a new element + state (no state reuse).
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameDeck<String>(
              key: const ValueKey('run2'),
              typeId: 'det-test',
              gameIndex: 2,
              pool: pool,
              games: 4,
              perGame: perGame,
              questionBuilder: (ctx, item, advance) {
                seenItems2.add(item);
                Future.microtask(advance);
                return Text(item);
              },
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Both runs must produce the same ordered deck of perGame questions.
      expect(seenItems1.take(perGame).toList(),
          equals(seenItems2.take(perGame).toList()));
    });

    testWidgets('onComplete is not called more than once', (tester) async {
      const perGame = 2;
      int completeCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameDeck<String>(
              typeId: 'once',
              gameIndex: 0,
              pool: pool,
              games: 1,
              perGame: perGame,
              questionBuilder: (ctx, item, advance) {
                return ElevatedButton(
                  onPressed: advance,
                  child: Text(item),
                );
              },
              onComplete: () => completeCalls++,
            ),
          ),
        ),
      );

      // Answer all questions.
      for (int i = 0; i < perGame; i++) {
        final btn = find.byType(ElevatedButton);
        if (btn.evaluate().isEmpty) break;
        await tester.tap(btn.first);
        await tester.pump();
      }

      // Try tapping again (deck is exhausted — SizedBox.shrink shown).
      // onComplete should still only be 1.
      expect(completeCalls, equals(1));
    });
  });
}
