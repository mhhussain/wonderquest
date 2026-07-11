import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/world_content.dart';
import 'package:wonder_quest/core/audio/sfx_service.dart';
import 'package:wonder_quest/core/audio/tts_service.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';
import 'package:wonder_quest/features/lands/around_the_world/mini_games.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MemStore extends SaveFileStore {
  _MemStore() : super(Directory.systemTemp);
  SaveData? _seeded;

  @override
  Future<SaveData> load() =>
      Future.value(_seeded ?? SaveData.initial(profileId: 'test-world'));

  @override
  Future<void> save(SaveData data) async => _seeded = data;
}

class _FakeSfxService implements SfxService {
  final List<Sfx> played = [];

  @override
  Future<void> play(Sfx sfx) async => played.add(sfx);

  @override
  Future<void> playWhaleCall(double baseFreqHz) async {}
}

class _FakeTtsBackend implements TtsBackend {
  final List<String> spoken = [];

  @override
  Future<dynamic> getVoices() async => <Map<String, String>>[];
  @override
  Future<void> setLanguage(String locale) async {}
  @override
  Future<void> setSpeechRate(double rate) async {}
  @override
  Future<void> setPitch(double pitch) async {}
  @override
  Future<dynamic> speak(String text) async {
    spoken.add(text);
    return 1;
  }
  @override
  Future<void> stop() async {}
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

Widget _harness({
  required Widget child,
  required _MemStore store,
  required _FakeSfxService fakeSfx,
  required _FakeTtsBackend fakeTts,
}) {
  return ProviderScope(
    overrides: [
      saveStoreProvider.overrideWithValue(store),
      ttsServiceProvider.overrideWith(
        (ref) => TtsService(fakeTts, soundOn: () => true),
      ),
      sfxServiceProvider.overrideWithValue(fakeSfx),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── Content integrity ────────────────────────────────────────────────────

  group('kContinents', () {
    test('has exactly 7 continents', () {
      expect(kContinents.length, equals(7));
    });

    test('each continent has a unique id', () {
      final ids = kContinents.map((c) => c.id).toSet();
      expect(ids.length, equals(7));
    });

    test('each continent has 6 animals', () {
      for (final c in kContinents) {
        expect(
          c.animals.length,
          equals(6),
          reason: '${c.name} should have 6 animals',
        );
      }
    });

    test('each continent mission count is between 1 and 6', () {
      for (final c in kContinents) {
        expect(
          c.mission.count,
          inInclusiveRange(1, 6),
          reason: '${c.name} mission count out of range',
        );
      }
    });
  });

  group('kDiscoveryCards', () {
    test('has exactly 21 cards (3 per continent)', () {
      expect(kDiscoveryCards.length, equals(21));
    });

    test('each continent has exactly 3 cards', () {
      for (final c in kContinents) {
        final cards =
            kDiscoveryCards.where((card) => card.id.startsWith(c.id)).toList();
        expect(
          cards.length,
          equals(3),
          reason: '${c.name} should have 3 discovery cards',
        );
      }
    });

    test('all card ids are unique', () {
      final ids = kDiscoveryCards.map((c) => c.id).toSet();
      expect(ids.length, equals(21));
    });

    test('all card game params have a say field', () {
      for (final card in kDiscoveryCards) {
        expect(
          card.game.params.containsKey('say'),
          isTrue,
          reason: 'Card ${card.id} game params missing "say" field',
        );
      }
    });
  });

  group('kWorldFacts', () {
    test('has exactly 21 facts (3 per continent)', () {
      expect(kWorldFacts.length, equals(21));
    });
  });

  group('kWorldWonders', () {
    test('has exactly 7 wonders', () {
      expect(kWorldWonders.length, equals(7));
    });
  });

  // ── SaveController: visitContinent ────────────────────────────────────────

  group('SaveController.visitContinent', () {
    test('sets world.visited[id] = true on first visit', () async {
      final store = _MemStore();
      final container = ProviderContainer(
        overrides: [saveStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      // Wait for build to complete
      await container.read(saveControllerProvider.future);

      // Initially, world.visited should be empty
      expect(container.read(saveControllerProvider).value?.world.visited,
          isEmpty);

      // Visit Africa
      await container
          .read(saveControllerProvider.notifier)
          .visitContinent('africa');

      final visited =
          container.read(saveControllerProvider).value?.world.visited;
      expect(visited?['africa'], isTrue);
      expect(visited?.length, equals(1));
    });

    test('visiting the same continent twice does not duplicate', () async {
      final store = _MemStore();
      final container = ProviderContainer(
        overrides: [saveStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(saveControllerProvider.future);

      await container
          .read(saveControllerProvider.notifier)
          .visitContinent('asia');
      await container
          .read(saveControllerProvider.notifier)
          .visitContinent('asia');

      final visited =
          container.read(saveControllerProvider).value?.world.visited;
      expect(visited?.length, equals(1));
      expect(visited?['asia'], isTrue);
    });

    test('visiting multiple continents accumulates correctly', () async {
      final store = _MemStore();
      final container = ProviderContainer(
        overrides: [saveStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(saveControllerProvider.future);

      for (final id in ['africa', 'asia', 'europe']) {
        await container
            .read(saveControllerProvider.notifier)
            .visitContinent(id);
      }

      final visited =
          container.read(saveControllerProvider).value?.world.visited;
      expect(visited?.length, equals(3));
    });
  });

  // ── SaveController: collectDiscoveryCard ──────────────────────────────────

  group('SaveController.collectDiscoveryCard', () {
    test('sets world.discovery[cardId] = true', () async {
      final store = _MemStore();
      final container = ProviderContainer(
        overrides: [saveStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(saveControllerProvider.future);

      await container
          .read(saveControllerProvider.notifier)
          .collectDiscoveryCard('africa-0');

      final discovery =
          container.read(saveControllerProvider).value?.world.discovery;
      expect(discovery?['africa-0'], isTrue);
    });

    test('card win persists across state re-reads', () async {
      final store = _MemStore();
      final container = ProviderContainer(
        overrides: [saveStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(saveControllerProvider.future);

      await container
          .read(saveControllerProvider.notifier)
          .collectDiscoveryCard('samerica-1');

      // Re-read state
      final discovery =
          container.read(saveControllerProvider).value?.world.discovery;
      expect(discovery?['samerica-1'], isTrue);

      // Collecting a second card doesn't remove the first
      await container
          .read(saveControllerProvider.notifier)
          .collectDiscoveryCard('samerica-2');

      final discovery2 =
          container.read(saveControllerProvider).value?.world.discovery;
      expect(discovery2?['samerica-1'], isTrue);
      expect(discovery2?['samerica-2'], isTrue);
    });
  });

  // ── Order mini-game: wrong-order taps rejected ────────────────────────────

  group('Order mini-game', () {
    test('order game items have strictly ascending s values', () {
      // africa-1 card: order game, items smallest→tallest
      final orderCard = kDiscoveryCards[1]; // africa-1 Tallest Animal
      expect(orderCard.game.type, equals(MiniGameType.order));

      final rawItems = orderCard.game.params['items'] as List<Object>;
      final items = rawItems.cast<Map<String, Object>>().toList();

      // Sort by 's' to get the correct play order
      items.sort((a, b) => (a['s'] as int).compareTo(b['s'] as int));
      expect(items.length, equals(4));

      // Verify 's' values are strictly ascending
      for (int i = 1; i < items.length; i++) {
        expect(
          (items[i]['s'] as int) > (items[i - 1]['s'] as int),
          isTrue,
          reason: 'Items should have strictly ascending s-values for ordering',
        );
      }
    });

    test('all order games in kDiscoveryCards have valid items list', () {
      final orderCards =
          kDiscoveryCards.where((c) => c.game.type == MiniGameType.order);
      for (final card in orderCards) {
        final rawItems = card.game.params['items'] as List<Object>?;
        expect(rawItems, isNotNull,
            reason: 'Card ${card.id} order game must have items');
        expect(rawItems!.length, greaterThanOrEqualTo(2),
            reason: 'Card ${card.id} order game must have ≥2 items');

        // Each item must have 'e' (emoji) and 's' (sort key)
        for (final raw in rawItems) {
          final item = raw as Map<String, Object>;
          expect(item.containsKey('e'), isTrue,
              reason: 'Card ${card.id} item missing "e" field');
          expect(item.containsKey('s'), isTrue,
              reason: 'Card ${card.id} item missing "s" field');
        }
      }
    });

    testWidgets(
        'order game: seeded shuffle — wrong-order tap fires Sfx.wrong, '
        'correct-order tap fires Sfx.pop', (tester) async {
      final store = _MemStore();
      final fakeSfx = _FakeSfxService();
      final fakeTts = _FakeTtsBackend();

      bool won = false;

      // antarctica-2: fish(1)→dolphin(2)→shark(3)→whale(4)
      final orderCard = kDiscoveryCards.firstWhere(
        (c) => c.id == 'antarctica-2',
      );
      expect(orderCard.game.type, equals(MiniGameType.order));

      // Reproduce the widget's shuffle with the same seed so we know
      // exactly which on-screen index is the correct first tap.
      const seed = 42;
      final rawItems = orderCard.game.params['items'] as List<Object>;
      final sortedItems = rawItems.cast<Map<String, Object>>().toList()
        ..sort((a, b) => (a['s'] as int).compareTo(b['s'] as int));
      final shuffled = List<Map<String, Object>>.from(sortedItems)
        ..shuffle(Random(seed));

      // The correct first tap is whichever shuffled index holds sortedItems[0].
      final correctIdx = shuffled.indexOf(sortedItems[0]);
      // Pick a wrong index: any index that is NOT the correct first.
      final wrongIdx = correctIdx == 0 ? 1 : 0;

      await tester.pumpWidget(
        _harness(
          child: MiniGameWidget(
            game: orderCard.game,
            color: Colors.blue,
            color2: Colors.lightBlue,
            onWin: () => won = true,
            random: Random(seed),
          ),
          store: store,
          fakeSfx: fakeSfx,
          fakeTts: fakeTts,
        ),
      );
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 100));

      // ── Wrong tap ──────────────────────────────────────────────────────────
      await tester.tap(find.byKey(Key('order-item-$wrongIdx')));
      await tester.pump(const Duration(milliseconds: 600)); // past shake timer

      expect(
        fakeSfx.played,
        contains(Sfx.wrong),
        reason: 'Tapping out-of-order should fire Sfx.wrong',
      );
      expect(won, isFalse,
          reason: 'Wrong tap must not advance progress to win');

      // ── Correct tap ────────────────────────────────────────────────────────
      fakeSfx.played.clear();
      await tester.tap(find.byKey(Key('order-item-$correctIdx')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        fakeSfx.played,
        contains(Sfx.pop),
        reason: 'Tapping the correct first item should fire Sfx.pop',
      );
    });
  });

  // ── Mission stamp grant: exactly once ─────────────────────────────────────
  // visitContinent is now called at find-mission completion (not on arrival).

  group('Mission stamp', () {
    test(
        'visitContinent grants stamp at mission completion and persists exactly once',
        () async {
      final store = _MemStore();
      final container = ProviderContainer(
        overrides: [saveStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(saveControllerProvider.future);

      // Arriving at a continent does NOT call visitContinent.
      // Stamp is granted at mission completion.
      await container
          .read(saveControllerProvider.notifier)
          .visitContinent('australia');

      final world = container.read(saveControllerProvider).value?.world;
      expect(world?.visited['australia'], isTrue,
          reason: 'Australia stamp should be granted after mission');

      // Duplicate call (idempotent) — should not change count.
      await container
          .read(saveControllerProvider.notifier)
          .visitContinent('australia');

      final world2 = container.read(saveControllerProvider).value?.world;
      expect(world2?.visited.length, equals(1),
          reason: 'Stamp count should not increase on duplicate visit');
    });
  });

  // ── SaveController: collectWonderCard ─────────────────────────────────────

  group('SaveController.collectWonderCard', () {
    test('adds continent id to world.cards on mission completion', () async {
      final store = _MemStore();
      final container = ProviderContainer(
        overrides: [saveStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(saveControllerProvider.future);

      expect(
        container.read(saveControllerProvider).value?.world.cards,
        isEmpty,
      );

      await container
          .read(saveControllerProvider.notifier)
          .collectWonderCard('africa');

      final cards =
          container.read(saveControllerProvider).value?.world.cards;
      expect(cards, contains('africa'));
      expect(cards?.length, equals(1));
    });

    test('collecting same continent id is deduped', () async {
      final store = _MemStore();
      final container = ProviderContainer(
        overrides: [saveStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(saveControllerProvider.future);

      await container
          .read(saveControllerProvider.notifier)
          .collectWonderCard('europe');
      await container
          .read(saveControllerProvider.notifier)
          .collectWonderCard('europe');

      final cards =
          container.read(saveControllerProvider).value?.world.cards;
      expect(cards?.length, equals(1),
          reason: 'Duplicate collectWonderCard calls must not add duplicates');
    });

    test('collecting multiple continents accumulates correctly', () async {
      final store = _MemStore();
      final container = ProviderContainer(
        overrides: [saveStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container.read(saveControllerProvider.future);

      for (final id in ['africa', 'asia', 'europe']) {
        await container
            .read(saveControllerProvider.notifier)
            .collectWonderCard(id);
      }

      final cards =
          container.read(saveControllerProvider).value?.world.cards;
      expect(cards?.length, equals(3));
      expect(cards, containsAll(['africa', 'asia', 'europe']));
    });
  });
}
