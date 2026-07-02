import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/lands.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';
import 'package:wonder_quest/features/map/expedition_map_screen.dart';

// ---------------------------------------------------------------------------
// In-memory SaveFileStore (avoids real dart:io under FakeAsync)
// See also app/test/widgets/hud_test.dart for the pattern rationale.
// ---------------------------------------------------------------------------

class _MemStore extends SaveFileStore {
  _MemStore() : super(Directory.systemTemp);

  SaveData? _data;

  @override
  Future<SaveData> load() =>
      Future.value(_data ?? SaveData.initial(profileId: 'map-test'));

  @override
  Future<void> save(SaveData data) async => _data = data;
}

// ---------------------------------------------------------------------------
// Helper: pump the map screen with an optional pre-seeded store
// ---------------------------------------------------------------------------

Widget _mapApp(_MemStore store) {
  return ProviderScope(
    overrides: [saveStoreProvider.overrideWithValue(store)],
    child: const MaterialApp(
      home: ExpeditionMapScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ExpeditionMapScreen', () {
    late _MemStore store;

    setUp(() => store = _MemStore());

    // ── Test 1: 13 land cards render ────────────────────────────────────────

    testWidgets('renders exactly 13 land cards', (tester) async {
      await tester.pumpWidget(_mapApp(store));
      await tester.pump(); // Let AsyncNotifier.build() resolve
      await tester.pump();

      // The registry must define exactly 13 lands.
      expect(kLands.length, 13);

      // GridView is lazy — scroll to each card so it enters the widget tree.
      for (final land in kLands) {
        await tester.scrollUntilVisible(
          find.byKey(Key('land-card-${land.id}')),
          200.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          find.byKey(Key('land-card-${land.id}')),
          findsOneWidget,
          reason: 'expected card for land "${land.id}"',
        );
      }
    });

    // ── Test 2: locked card shows 🔒 and tap is a no-op ─────────────────────

    testWidgets('locked card shows lock glyph and does not navigate on tap',
        (tester) async {
      await tester.pumpWidget(_mapApp(store));
      await tester.pump();
      await tester.pump();

      // The first locked land is 'dino' (index 7 in kLands).
      final dinoCard = find.byKey(const Key('land-card-dino'));
      expect(dinoCard, findsOneWidget);

      // The lock emoji should be visible somewhere in the card subtree.
      // Art.emoji('lock') = '🔒'
      expect(find.text('🔒'), findsWidgets);

      // Tap the locked card — should be a no-op (no navigation).
      await tester.tap(dinoCard);
      await tester.pumpAndSettle();

      // We should still be on the map (My Stuff button visible, no new route).
      expect(find.byKey(const Key('my-stuff-btn')), findsOneWidget);
    });

    // ── Test 3: tapping a playable card navigates to placeholder screen ──────

    testWidgets('tapping a playable card pushes the placeholder route',
        (tester) async {
      await tester.pumpWidget(_mapApp(store));
      await tester.pump();
      await tester.pump();

      // Tap the 'letter' land card (first playable, no builder yet → placeholder).
      await tester.tap(find.byKey(const Key('land-card-letter')));
      await tester.pumpAndSettle();

      // Placeholder screen should be on the navigator stack.
      expect(find.text('Coming in a later task'), findsOneWidget);

      // Map's My Stuff button should no longer be visible.
      expect(find.byKey(const Key('my-stuff-btn')), findsNothing);
    });

    // ── Test 4: Hatch button decrements eggs and adds a dino ─────────────────

    testWidgets('Hatch! with eggs=1 decrements eggs and adds a hatched dino',
        (tester) async {
      // Seed: 1 egg, no dinos hatched yet.
      await store.save(
        SaveData.initial(profileId: 'hatch-test').copyWith(eggs: 1),
      );

      await tester.pumpWidget(_mapApp(store));
      await tester.pump();
      await tester.pump();

      // Open the My Stuff / Collections modal.
      await tester.tap(find.byKey(const Key('my-stuff-btn')));
      await tester.pump(); // Dialog starts to build
      await tester.pump(); // Dialog finishes building

      expect(find.byKey(const Key('collections-modal')), findsOneWidget);
      expect(find.byKey(const Key('hatch-btn')), findsOneWidget);

      // Tap Hatch!
      await tester.tap(find.byKey(const Key('hatch-btn')));
      // Drain the SaveController._update async chain.
      await tester.pump();
      await tester.pump();

      // Read the updated save state from the container.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ExpeditionMapScreen)),
      );
      final save = container.read(saveControllerProvider).requireValue;

      expect(save.eggs, 0, reason: 'egg should be consumed');
      expect(save.hatched.length, 1, reason: 'one dino should be hatched');

      // The hatched dino name must be one of the kDinos roster.
      final dinoNames = kDinos.map((d) => d.name).toList();
      expect(dinoNames, contains(save.hatched.first));
    });
  });
}
