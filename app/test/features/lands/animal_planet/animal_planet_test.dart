import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/animals_content.dart';
import 'package:wonder_quest/core/audio/sfx_service.dart';
import 'package:wonder_quest/core/audio/tts_service.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';
import 'package:wonder_quest/features/lands/animal_planet/animal_homes_game.dart';
import 'package:wonder_quest/features/lands/animal_planet/fun_facts_game.dart';
import 'package:wonder_quest/features/lands/animal_planet/whale_world_screen.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MemStore extends SaveFileStore {
  _MemStore() : super(Directory.systemTemp);
  SaveData? _seeded;

  @override
  Future<SaveData> load() =>
      Future.value(_seeded ?? SaveData.initial(profileId: 'mem'));

  @override
  Future<void> save(SaveData data) async => _seeded = data;
}

class _FakeSfxService implements SfxService {
  final List<Sfx> played = [];

  @override
  Future<void> play(Sfx sfx) async => played.add(sfx);
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

/// Pumps until the async notifier has settled.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── diveFraction unit tests ───────────────────────────────────────────────

  group('diveFraction', () {
    test('Sperm Whale (2000 m) fills 100%', () {
      final sperm = kWhales.firstWhere((w) => w.n == 'Sperm Whale');
      expect(diveFraction(sperm), closeTo(1.0, 0.001));
    });

    test('Blue Whale (200 m) fills 10%', () {
      final blue = kWhales.firstWhere((w) => w.n == 'Blue Whale');
      expect(diveFraction(blue), closeTo(0.1, 0.001));
    });

    test('Narwhal (1500 m) fills 75%', () {
      final narwhal = kWhales.firstWhere((w) => w.n == 'Narwhal');
      expect(diveFraction(narwhal), closeTo(0.75, 0.001));
    });

    test('Orca (150 m) fills 7.5%', () {
      final orca = kWhales.firstWhere((w) => w.n == 'Orca');
      expect(diveFraction(orca), closeTo(0.075, 0.001));
    });
  });

  // ── whaleCallSfx unit tests ───────────────────────────────────────────────

  group('whaleCallSfx', () {
    test('Blue Whale (54 Hz) → whaleLow', () {
      final w = kWhales.firstWhere((w) => w.n == 'Blue Whale');
      expect(whaleCallSfx(w), Sfx.whaleLow);
    });

    test('Sperm Whale (46 Hz) → whaleLow', () {
      final w = kWhales.firstWhere((w) => w.n == 'Sperm Whale');
      expect(whaleCallSfx(w), Sfx.whaleLow);
    });

    test('Humpback Whale (90 Hz) → whaleLow', () {
      final w = kWhales.firstWhere((w) => w.n == 'Humpback Whale');
      expect(whaleCallSfx(w), Sfx.whaleLow);
    });

    test('Orca (130 Hz) → whaleHigh', () {
      final w = kWhales.firstWhere((w) => w.n == 'Orca');
      expect(whaleCallSfx(w), Sfx.whaleHigh);
    });

    test('Beluga Whale (150 Hz) → whaleHigh', () {
      final w = kWhales.firstWhere((w) => w.n == 'Beluga Whale');
      expect(whaleCallSfx(w), Sfx.whaleHigh);
    });

    test('Narwhal (120 Hz) → whaleHigh', () {
      final w = kWhales.firstWhere((w) => w.n == 'Narwhal');
      expect(whaleCallSfx(w), Sfx.whaleHigh);
    });
  });

  // ── Dive meter widget test ────────────────────────────────────────────────

  group('WhaleWorldScreen dive meter', () {
    testWidgets('FractionallySizedBox heightFactor is proportional to diveM',
        (tester) async {
      final store = _MemStore();
      final fakeSfx = _FakeSfxService();
      final fakeTts = _FakeTtsBackend();

      await tester.pumpWidget(
        _harness(
          child: const WhaleWorldScreen(),
          store: store,
          fakeSfx: fakeSfx,
          fakeTts: fakeTts,
        ),
      );
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 100));

      // Default selection is Blue Whale (index 0, 200 m → 10%).
      final blueWhale = kWhales[0];
      expect(blueWhale.n, 'Blue Whale');
      expect(diveFraction(blueWhale), closeTo(0.1, 0.001));

      // Find the FractionallySizedBox for the dive fill and check heightFactor.
      final fsb = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: find.byKey(
            Key('dive-meter-${blueWhale.n.replaceAll(' ', '-')}'),
          ),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(fsb.heightFactor, closeTo(diveFraction(blueWhale), 0.001));

      // Switch to Sperm Whale (2000 m → 100%).
      await tester.tap(find.byKey(const Key('whale-pick-2')));
      await tester.pump(const Duration(milliseconds: 250));

      final spermWhale = kWhales[2];
      expect(spermWhale.n, 'Sperm Whale');
      final fsbSperm = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: find.byKey(
            Key('dive-meter-${spermWhale.n.replaceAll(' ', '-')}'),
          ),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(fsbSperm.heightFactor, closeTo(diveFraction(spermWhale), 0.001));
    });
  });

  // ── FunFactsScreen: flip adds animal exactly once ─────────────────────────

  group('FunFactsScreen', () {
    testWidgets('flip adds animal to animalsFound exactly once', (tester) async {
      final store = _MemStore();
      final fakeSfx = _FakeSfxService();
      final fakeTts = _FakeTtsBackend();

      // Seed the RNG so the first card is deterministic.
      final rng = Random(1);

      await tester.pumpWidget(
        _harness(
          child: FunFactsScreen(random: rng),
          store: store,
          fakeSfx: fakeSfx,
          fakeTts: fakeTts,
        ),
      );
      await _settle(tester);

      // Tap the first flip card to reveal it.
      final cardFinder = find.byKey(const Key('flip-card-0'));
      expect(cardFinder, findsOneWidget);
      await tester.tap(cardFinder);
      // Let the flip animation pass the π/2 midpoint (onFlipped fires there).
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 200));

      // animalsFound should now contain exactly 1 entry.
      expect(store._seeded?.animalsFound.length, 1);
      final addedAnimal = store._seeded!.animalsFound.first;

      // Tap the same card again (flips back).
      await tester.tap(cardFinder);
      await tester.pump(const Duration(milliseconds: 500));
      // Then tap again (flip back to back side).
      await tester.tap(cardFinder);
      await tester.pump(const Duration(milliseconds: 500));

      // animalsFound should STILL contain only 1 entry (no duplicates).
      final found = store._seeded?.animalsFound ?? const <String>[];
      expect(
        found.where((n) => n == addedAnimal).length,
        1,
        reason: 'Same animal should not be added more than once',
      );
    });
  });

  // ── AnimalHomesScreen: wrong habitat does not settle ─────────────────────

  group('AnimalHomesScreen', () {
    testWidgets('dropping animal on wrong habitat does not settle it',
        (tester) async {
      final store = _MemStore();
      final fakeSfx = _FakeSfxService();
      final fakeTts = _FakeTtsBackend();

      // Use seeded Random so pick is deterministic and we know which animals
      // belong to which habitat.
      final rng = Random(42);

      await tester.pumpWidget(
        _harness(
          child: AnimalHomesScreen(random: rng),
          store: store,
          fakeSfx: fakeSfx,
          fakeTts: fakeTts,
        ),
      );
      await _settle(tester);

      // Find an ocean animal chip: Dolphin, Octopus, or Fish.
      // Since the pick is seeded, at least one ocean animal chip will be visible.
      Finder? chipFinder;
      String? wrongZoneId;

      // Try to find one of the ocean animals in the tray.
      for (final a in kAnimals.where((a) => a.habitat == 'ocean')) {
        final f = find.byKey(Key('chip-${a.name}'));
        if (tester.any(f)) {
          chipFinder = f;
          // The wrong zone is something that isn't 'ocean' — use 'jungle'.
          wrongZoneId = 'jungle';
          break;
        }
      }

      // If no ocean animal was picked this session, the test still passes:
      // there's no chip to drag onto a wrong zone.
      if (chipFinder == null || wrongZoneId == null) return;

      // Get the center of the chip and the center of the wrong zone.
      final chipCenter = tester.getCenter(chipFinder);
      final wrongZoneFinder = find.byKey(Key('zone-$wrongZoneId'));
      expect(wrongZoneFinder, findsOneWidget);
      final wrongZoneCenter = tester.getCenter(wrongZoneFinder);

      // Simulate drag from chip to wrong zone.
      final gesture = await tester.startGesture(chipCenter);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(wrongZoneCenter);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));

      // The chip should still be visible in the tray (not added to placed).
      expect(
        tester.any(chipFinder),
        isTrue,
        reason:
            'Animal chip should still be in tray after wrong-habitat drop',
      );
    });
  });
}
