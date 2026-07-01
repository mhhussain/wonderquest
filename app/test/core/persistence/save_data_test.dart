import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';

void main() {
  group('SaveData', () {
    test('initial() creates instance with schema defaults', () {
      final saveData = SaveData.initial(profileId: 'test-profile-1');

      expect(saveData.schemaVersion, 1);
      expect(saveData.profileId, 'test-profile-1');
      expect(saveData.name, 'Hassan');
      expect(saveData.xp, 0);
      expect(saveData.level, 1);
      expect(saveData.stars, 0);
      expect(saveData.eggs, 0);
      expect(saveData.streak, 0);
      expect(saveData.soundOn, true);
      expect(saveData.hatched, <String>[]);
      expect(saveData.stickers, <String>[]);
      expect(saveData.animalsFound, <String>[]);
      expect(saveData.lettersMastered, <String>[]);
      expect(saveData.lettersLearning, <String>[]);
      expect(saveData.numbersMastered, <String>[]);
      expect(saveData.minutesToday, 0);
      expect(saveData.week, [0, 0, 0, 0, 0, 0, 0]);
      expect(saveData.levels, <String, List<bool>>{});
      expect(saveData.world.visited, <String, bool>{});
      expect(saveData.world.points, 0);
      expect(saveData.world.discovery, <String, bool>{});
    });

    test('initial() includes all 7 progress keys at 0', () {
      final saveData = SaveData.initial(profileId: 'test-profile-1');

      expect(saveData.progress.length, 7);
      expect(saveData.progress['letter'], 0);
      expect(saveData.progress['arabic'], 0);
      expect(saveData.progress['number'], 0);
      expect(saveData.progress['math'], 0);
      expect(saveData.progress['animal'], 0);
      expect(saveData.progress['world'], 0);
      expect(saveData.progress['find'], 0);
    });

    test('toJson() and fromJson() round-trip fully-populated instance', () {
      final original = const SaveData(
        schemaVersion: 1,
        profileId: 'test-profile-1',
        name: 'Hassan',
        xp: 150,
        level: 3,
        stars: 5,
        eggs: 10,
        streak: 7,
        soundOn: false,
        hatched: ['dino1', 'dino2'],
        stickers: ['sticker1'],
        animalsFound: ['animal1', 'animal2', 'animal3'],
        lettersMastered: ['A', 'B'],
        lettersLearning: ['C'],
        numbersMastered: ['1', '2', '3'],
        progress: {
          'letter': 50,
          'arabic': 25,
          'number': 75,
          'math': 30,
          'animal': 60,
          'world': 40,
          'find': 20,
        },
        minutesToday: 45,
        lastPlayedDate: '2024-01-15',
        week: [10, 15, 20, 5, 30, 25, 40],
        levels: {
          'big': [true, false, true],
          'match': [true, true, false, true],
        },
        world: WorldState(
          visited: {'location1': true, 'location2': false},
          points: 100,
          discovery: {'card1': true, 'card2': true},
        ),
      );

      final json = original.toJson();
      final restored = SaveData.fromJson(json);

      expect(restored, original);
      expect(restored.schemaVersion, original.schemaVersion);
      expect(restored.profileId, original.profileId);
      expect(restored.name, original.name);
      expect(restored.xp, original.xp);
      expect(restored.level, original.level);
      expect(restored.stars, original.stars);
      expect(restored.eggs, original.eggs);
      expect(restored.streak, original.streak);
      expect(restored.soundOn, original.soundOn);
      expect(restored.hatched, original.hatched);
      expect(restored.stickers, original.stickers);
      expect(restored.animalsFound, original.animalsFound);
      expect(restored.lettersMastered, original.lettersMastered);
      expect(restored.lettersLearning, original.lettersLearning);
      expect(restored.numbersMastered, original.numbersMastered);
      expect(restored.progress, original.progress);
      expect(restored.minutesToday, original.minutesToday);
      expect(restored.lastPlayedDate, original.lastPlayedDate);
      expect(restored.week, original.week);
      expect(restored.levels, original.levels);
      expect(restored.world.visited, original.world.visited);
      expect(restored.world.points, original.world.points);
      expect(restored.world.discovery, original.world.discovery);
    });

    test('fromJson() merges defaults for missing keys', () {
      final s = SaveData.fromJson({
        'schemaVersion': 1,
        'profileId': 'p1',
        'stars': 3,
      });

      expect(s.schemaVersion, 1);
      expect(s.profileId, 'p1');
      expect(s.stars, 3);
      expect(s.name, 'Hassan');
      expect(s.level, 1);
      expect(s.xp, 0);
      expect(s.eggs, 0);
      expect(s.streak, 0);
      expect(s.soundOn, true);
      expect(s.hatched, <String>[]);
      expect(s.stickers, <String>[]);
      expect(s.animalsFound, <String>[]);
      expect(s.lettersMastered, <String>[]);
      expect(s.lettersLearning, <String>[]);
      expect(s.numbersMastered, <String>[]);
      expect(s.progress['arabic'], 0);
      expect(s.progress.length, 7);
      expect(s.week, hasLength(7));
      expect(s.minutesToday, 0);
      expect(s.lastPlayedDate, isNotNull);
      expect(s.levels, <String, List<bool>>{});
      expect(s.world.visited, <String, bool>{});
      expect(s.world.points, 0);
      expect(s.world.discovery, <String, bool>{});
    });

    test('copyWith() changes only specified fields', () {
      final original = SaveData.initial(profileId: 'test-1');
      final modified = original.copyWith(stars: 5);

      expect(modified.stars, 5);
      expect(modified.profileId, original.profileId);
      expect(modified.name, original.name);
      expect(modified.xp, original.xp);
      expect(modified.level, original.level);
      expect(modified.eggs, original.eggs);
      expect(modified.streak, original.streak);
      expect(modified.soundOn, original.soundOn);
    });

    test('copyWith() with multiple fields', () {
      final original = SaveData.initial(profileId: 'test-1');
      final modified = original.copyWith(
        stars: 10,
        xp: 200,
        level: 5,
        soundOn: false,
      );

      expect(modified.stars, 10);
      expect(modified.xp, 200);
      expect(modified.level, 5);
      expect(modified.soundOn, false);
      expect(modified.profileId, original.profileId);
    });

    test('== operator compares by value', () {
      final save1 = SaveData.initial(profileId: 'test-1');
      final save2 = SaveData.initial(profileId: 'test-1');

      expect(save1, save2);
    });

    test('== operator returns false for different instances', () {
      final save1 = SaveData.initial(profileId: 'test-1');
      final save2 = save1.copyWith(stars: 5);

      expect(save1 == save2, false);
    });

    test('hashCode is consistent for equal instances', () {
      final save1 = SaveData.initial(profileId: 'test-1');
      final save2 = SaveData.initial(profileId: 'test-1');

      expect(save1.hashCode, save2.hashCode);
    });
  });
}
