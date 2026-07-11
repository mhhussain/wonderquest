import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';
import 'package:wonder_quest/widgets/hud.dart';

/// In-memory [SaveFileStore] substitute that avoids real file I/O.
///
/// [testWidgets] runs inside Flutter's [FakeAsync] zone which processes
/// microtasks but does not drain real dart:io event-loop completions.
/// Using [Future.value] (microtask-based) lets [tester.pump()] fully
/// resolve the [AsyncNotifier] build in two calls.
class _MemStore extends SaveFileStore {
  // Super constructor needs a Directory but load/save are overridden.
  _MemStore() : super(Directory.systemTemp);

  SaveData? _seeded;

  @override
  Future<SaveData> load() =>
      Future.value(_seeded ?? SaveData.initial(profileId: 'mem'));

  @override
  Future<void> save(SaveData data) async => _seeded = data;
}

void main() {
  group('Hud', () {
    late _MemStore store;

    setUp(() {
      store = _MemStore();
    });

    testWidgets('shows Lv 2 and star count 7 from seeded save', (tester) async {
      // Seed the store: stars=7, level=2, xp=80.
      await store.save(SaveData.initial(profileId: 'hud-test').copyWith(
        level: 2,
        xp: 80,
        stars: 7,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            saveStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Hud(onParentTap: () {}),
            ),
          ),
        ),
      );

      // Let AsyncNotifier.build() / file load complete.
      await tester.pump();
      await tester.pump();

      expect(find.text('Lv 2'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('tapping sound toggle flips soundOn in provider', (tester) async {
      // Seed with soundOn=true (default).
      await store.save(SaveData.initial(profileId: 'hud-sound-test').copyWith(
        level: 2,
        xp: 80,
        stars: 7,
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            saveStoreProvider.overrideWithValue(store),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Hud(onParentTap: () {}),
            ),
          ),
        ),
      );

      // Let the async build complete.
      await tester.pump();
      await tester.pump();

      // Confirm initial soundOn=true.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Hud)),
      );
      expect(
        container.read(saveControllerProvider).requireValue.soundOn,
        isTrue,
      );

      // Tap the sound toggle.
      await tester.tap(find.byKey(const Key('hud-sound')));
      // Drain async chain in SaveController._update().
      await tester.pump();
      await tester.pump();

      // soundOn must have flipped to false.
      expect(
        container.read(saveControllerProvider).requireValue.soundOn,
        isFalse,
      );
    });
  });
}
