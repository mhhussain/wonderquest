import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/domain/reward.dart';
import 'package:wonder_quest/domain/reward_engine.dart';

void main() {
  group('xpForLevel', () {
    test('xpForLevel(1) == 100', () {
      expect(xpForLevel(1), 100);
    });

    test('xpForLevel(2) == 160', () {
      expect(xpForLevel(2), 160);
    });

    test('xpForLevel(3) == 220', () {
      expect(xpForLevel(3), 220);
    });

    test('xpForLevel(5) == 340', () {
      expect(xpForLevel(5), 340);
    });
  });

  group('applyReward', () {
    late SaveData initial;

    setUp(() {
      initial = SaveData.initial(profileId: 'test-profile');
    });

    test('stars are added', () {
      const reward = Reward(stars: 10);
      final result = applyReward(initial, reward);
      expect(result.stars, 10);
    });

    test('xp without level-up stays in xp', () {
      const reward = Reward(xp: 50);
      final result = applyReward(initial, reward);
      expect(result.xp, 50);
      expect(result.level, 1);
    });

    test('exact boundary XP (level 1 + 100xp → level 2, xp 0)', () {
      // Level 1, need 100 xp to level up to level 2
      // Start with 0 xp, add 100 xp (exactly xpForLevel(1))
      // 100 >= 100, so level up and subtract 100, leaving 0 xp
      const reward = Reward(xp: 100);
      final result = applyReward(initial, reward);
      expect(result.level, 2);
      expect(result.xp, 0);
    });

    test('single level-up leaves remainder (level 1 + 130xp → level 2, xp 30)', () {
      // Level 1, need 100 xp to level up to level 2
      // Start with 0 xp, add 130 xp
      // 130 >= 100, so level up and subtract 100, leaving 30 xp
      const reward = Reward(xp: 130);
      final result = applyReward(initial, reward);
      expect(result.level, 2);
      expect(result.xp, 30);
    });

    test('multi-level-up (level 1 + 300xp → level 3, xp 40)', () {
      // Level 1: need 100 xp to level 2
      // Level 2: need 160 xp to level 3
      // Start with 0 xp, add 300 xp
      // 300 >= 100 (level to 2), subtract 100, have 200
      // 200 >= 160 (level to 3), subtract 160, have 40
      // Total: level 3, xp 40
      const reward = Reward(xp: 300);
      final result = applyReward(initial, reward);
      expect(result.level, 3);
      expect(result.xp, 40);
    });

    test('egg increments eggs counter', () {
      const reward = Reward(egg: true);
      final result = applyReward(initial, reward);
      expect(result.eggs, 1);
    });

    test('egg: false does not increment eggs', () {
      const reward = Reward(egg: false);
      final result = applyReward(initial, reward);
      expect(result.eggs, 0);
    });

    test('sticker is appended if not already present', () {
      const reward = Reward(sticker: 'star-bronze');
      final result = applyReward(initial, reward);
      expect(result.stickers, ['star-bronze']);
    });

    test('sticker is not appended if already present', () {
      final existing = initial.copyWith(stickers: const ['star-bronze']);
      const reward = Reward(sticker: 'star-bronze');
      final result = applyReward(existing, reward);
      expect(result.stickers, ['star-bronze']);
    });

    test('multiple stickers dedupe correctly', () {
      final existing = initial.copyWith(stickers: const ['star-bronze', 'sun']);
      const reward = Reward(sticker: 'sun');
      final result = applyReward(existing, reward);
      expect(result.stickers, ['star-bronze', 'sun']);
    });

    test('animal is appended if not already present', () {
      const reward = Reward(animal: 'lion');
      final result = applyReward(initial, reward);
      expect(result.animalsFound, ['lion']);
    });

    test('animal is not appended if already present', () {
      final existing = initial.copyWith(animalsFound: const ['lion']);
      const reward = Reward(animal: 'lion');
      final result = applyReward(existing, reward);
      expect(result.animalsFound, ['lion']);
    });

    test('progress key updates to progressTo value', () {
      const reward = Reward(progressKey: 'letter', progressTo: 40);
      final result = applyReward(initial, reward);
      expect(result.progress['letter'], 40);
    });

    test('progress is monotonic: does not decrease', () {
      // First set letter to 40
      const reward1 = Reward(progressKey: 'letter', progressTo: 40);
      final intermediate = applyReward(initial, reward1);
      expect(intermediate.progress['letter'], 40);

      // Then try to set it to 20, should stay at 40
      const reward2 = Reward(progressKey: 'letter', progressTo: 20);
      final result = applyReward(intermediate, reward2);
      expect(result.progress['letter'], 40);
    });

    test('progress clamps at 100', () {
      const reward = Reward(progressKey: 'letter', progressTo: 150);
      final result = applyReward(initial, reward);
      expect(result.progress['letter'], 100);
    });

    test('progress clamps at 0', () {
      const reward = Reward(progressKey: 'letter', progressTo: -10);
      final result = applyReward(initial, reward);
      expect(result.progress['letter'], 0);
    });

    test('combined reward: stars + xp + level-up', () {
      const reward = Reward(stars: 5, xp: 130);
      final result = applyReward(initial, reward);
      expect(result.stars, 5);
      expect(result.level, 2);
      expect(result.xp, 30);
    });

    test('combined reward: xp + egg + sticker + progress', () {
      const reward = Reward(
        xp: 50,
        egg: true,
        sticker: 'trophy',
        progressKey: 'number',
        progressTo: 60,
      );
      final result = applyReward(initial, reward);
      expect(result.xp, 50);
      expect(result.eggs, 1);
      expect(result.stickers, ['trophy']);
      expect(result.progress['number'], 60);
    });

    test('silent flag does not affect state', () {
      const reward1 = Reward(stars: 10, silent: false);
      const reward2 = Reward(stars: 10, silent: true);
      final result1 = applyReward(initial, reward1);
      final result2 = applyReward(initial, reward2);
      expect(result1.stars, result2.stars);
    });

    test('xp rolls over across multiple levels starting from higher level', () {
      // Start at level 5, xp 0
      // Level 5 → 6 requires 100 + (5-1)*60 = 340 xp
      // Level 6 → 7 requires 100 + (6-1)*60 = 400 xp
      // Add 500 xp: 500 >= 340, subtract 340, have 160
      // 160 < 400, stop
      // Result: level 6, xp 160
      final existing = initial.copyWith(level: 5, xp: 0);
      const reward = Reward(xp: 500);
      final result = applyReward(existing, reward);
      expect(result.level, 6);
      expect(result.xp, 160);
    });

    test('all progress keys are preserved during updates', () {
      const reward = Reward(progressKey: 'letter', progressTo: 50);
      final result = applyReward(initial, reward);

      expect(result.progress['letter'], 50);
      expect(result.progress['arabic'], 0);
      expect(result.progress['number'], 0);
      expect(result.progress['math'], 0);
      expect(result.progress['animal'], 0);
      expect(result.progress['world'], 0);
      expect(result.progress['find'], 0);
    });

    test('reward with no changes returns equivalent state', () {
      const reward = Reward();
      final result = applyReward(initial, reward);

      expect(result.stars, initial.stars);
      expect(result.xp, initial.xp);
      expect(result.level, initial.level);
      expect(result.eggs, initial.eggs);
      expect(result.stickers, initial.stickers);
      expect(result.animalsFound, initial.animalsFound);
      expect(result.progress, initial.progress);
    });
  });
}
