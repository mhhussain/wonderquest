import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';
import 'package:wonder_quest/domain/reward.dart';

void main() {
  group('SaveController', () {
    late Directory tempDir;
    late SaveFileStore store;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('save_controller_test_');
      store = SaveFileStore(tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    /// Creates a ProviderContainer with saveStoreProvider overridden to the
    /// temp-dir store. Uses ProviderContainer.test for auto-teardown.
    ProviderContainer makeContainer() {
      return ProviderContainer.test(
        overrides: [
          saveStoreProvider.overrideWithValue(store),
        ],
      );
    }

    test(
        '(a) apply(Reward(stars: 2)) persists — reload store returns stars=2',
        () async {
      final container = makeContainer();

      // Wait for build to finish (load + rollover)
      await container.read(saveControllerProvider.future);

      // Apply a reward of 2 stars
      await container.read(saveControllerProvider.notifier).apply(
            const Reward(stars: 2),
          );

      // In-memory state is updated
      final inMemory = container.read(saveControllerProvider).requireValue;
      expect(inMemory.stars, 2);

      // File was written: a fresh store from the same dir should see stars=2
      final freshStore = SaveFileStore(tempDir);
      final reloaded = await freshStore.load();
      expect(reloaded.stars, 2);
    });

    test(
        '(b) markLevelDone("big", 3, 10) yields a 10-length list with index 3 true',
        () async {
      final container = makeContainer();
      await container.read(saveControllerProvider.future);

      await container
          .read(saveControllerProvider.notifier)
          .markLevelDone('big', 3, 10);

      final s = container.read(saveControllerProvider).requireValue;
      expect(s.levels['big'], hasLength(10));
      expect(s.levels['big']![3], isTrue);
      for (var i = 0; i < 10; i++) {
        if (i != 3) expect(s.levels['big']![i], isFalse);
      }
    });

    test(
        '(c) hatchEgg decrements eggs and appends dino name',
        () async {
      // Pre-populate the store with 2 eggs
      final initial =
          SaveData.initial(profileId: 'egg-test').copyWith(eggs: 2);
      await store.save(initial);

      final container = makeContainer();
      await container.read(saveControllerProvider.future);

      await container
          .read(saveControllerProvider.notifier)
          .hatchEgg('trex');

      final s = container.read(saveControllerProvider).requireValue;
      expect(s.eggs, 1);
      expect(s.hatched, contains('trex'));
    });

    test(
        '(d) resetAllProgress keeps profileId and zeroes stars/xp',
        () async {
      const profileId = 'keep-this-id';
      final initial = SaveData.initial(profileId: profileId).copyWith(
        stars: 100,
        xp: 500,
        level: 5,
      );
      await store.save(initial);

      final container = makeContainer();
      await container.read(saveControllerProvider.future);

      await container
          .read(saveControllerProvider.notifier)
          .resetAllProgress();

      final s = container.read(saveControllerProvider).requireValue;
      expect(s.profileId, profileId);
      expect(s.stars, 0);
      expect(s.xp, 0);
      expect(s.level, 1);
    });
  });
}
