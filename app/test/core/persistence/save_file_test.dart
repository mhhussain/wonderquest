import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';

void main() {
  group('SaveFileStore', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('(a) load from empty directory returns initial with non-empty profileId',
        () async {
      final store = SaveFileStore(tempDir);
      final data = await store.load();

      expect(data.profileId, isNotEmpty);
      expect(data.profileId, isA<String>());
      // Profile ID should be a UUID-like string (36 chars with hyphens)
      expect(data.profileId.length, greaterThan(0));
    });

    test('(b) save then load round-trips data', () async {
      final store = SaveFileStore(tempDir);

      // Create and save data
      final original = SaveData.initial(profileId: 'test-profile-123');
      final modified = original.copyWith(
        name: 'TestPlayer',
        xp: 500,
        level: 5,
        stars: 10,
      );
      await store.save(modified);

      // Load it back
      final loaded = await store.load();

      expect(loaded, equals(modified));
      expect(loaded.name, equals('TestPlayer'));
      expect(loaded.xp, equals(500));
      expect(loaded.level, equals(5));
      expect(loaded.stars, equals(10));
    });

    test('(c) load with garbage file returns initial and renames to .corrupt.json',
        () async {
      final store = SaveFileStore(tempDir);

      // Write garbage data
      final saveFile = File('${tempDir.path}/wonderquest_save.json');
      await saveFile.writeAsString('{ invalid json ]');

      // Load should return initial
      final data = await store.load();
      expect(data.profileId, isNotEmpty);

      // Original file should be renamed to .corrupt.json
      final corruptFile =
          File('${tempDir.path}/wonderquest_save.corrupt.json');
      expect(corruptFile.existsSync(), isTrue);

      // Original save.json should not exist
      expect(saveFile.existsSync(), isFalse);
    });

    test('(d) after save, no .tmp file remains', () async {
      final store = SaveFileStore(tempDir);
      final data = SaveData.initial(profileId: 'test-profile');

      await store.save(data);

      final tmpFile = File('${tempDir.path}/wonderquest_save.json.tmp');
      expect(tmpFile.existsSync(), isFalse);
    });

    test('(e) load with valid JSON but wrong shape (list) returns initial and quarantines',
        () async {
      final store = SaveFileStore(tempDir);

      // Write valid JSON but wrong shape (list instead of object)
      final saveFile = File('${tempDir.path}/wonderquest_save.json');
      await saveFile.writeAsString('[1, 2, 3]');

      // Load should return initial
      final data = await store.load();
      expect(data.profileId, isNotEmpty);

      // Original file should be renamed to .corrupt.json
      final corruptFile =
          File('${tempDir.path}/wonderquest_save.corrupt.json');
      expect(corruptFile.existsSync(), isTrue);

      // Original save.json should not exist
      expect(saveFile.existsSync(), isFalse);
    });
  });
}
