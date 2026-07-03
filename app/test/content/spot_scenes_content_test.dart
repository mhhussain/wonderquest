import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/spot_scenes_content.dart';

void main() {
  group('Spot Scenes Content', () {
    group('kSpotScenes', () {
      test('has exactly 5 scenes', () {
        expect(kSpotScenes.length, equals(5));
      });

      test('contains Picnic, Carnival, Aquarium, Beach, Space', () {
        final names = kSpotScenes.map((s) => s.name).toSet();
        expect(names, containsAll([
          'Picnic Day',
          'Carnival',
          'Aquarium',
          'Beach Day',
          'Space Station',
        ]));
      });

      test('all scenes have non-empty name and emoji', () {
        for (final s in kSpotScenes) {
          expect(s.name.isNotEmpty, isTrue, reason: 'scene missing name');
          expect(s.emoji.isNotEmpty, isTrue, reason: '${s.name} missing emoji');
        }
      });

      test('all scenes have non-empty deco list', () {
        for (final s in kSpotScenes) {
          expect(s.deco.isNotEmpty, isTrue,
              reason: '${s.name} has empty deco list');
        }
      });

      test('Space scene has dark flag set to true', () {
        final space = kSpotScenes.firstWhere((s) => s.name == 'Space Station');
        expect(space.dark, isTrue);
      });

      test('non-space scenes have dark flag false', () {
        for (final s in kSpotScenes.where((s) => s.name != 'Space Station')) {
          expect(s.dark, isFalse, reason: '${s.name} should not be dark');
        }
      });

      test('Picnic scene has correct emoji', () {
        final picnic = kSpotScenes.firstWhere((s) => s.name == 'Picnic Day');
        expect(picnic.emoji, equals('🧺'));
      });

      test('Aquarium scene has correct emoji', () {
        final aq = kSpotScenes.firstWhere((s) => s.name == 'Aquarium');
        expect(aq.emoji, equals('🐠'));
      });
    });

    group('kSockLevels', () {
      test('has exactly 3 sock levels', () {
        expect(kSockLevels.length, equals(3));
      });

      test('levels progress color → pattern → both', () {
        expect(kSockLevels[0].by, equals('color'));
        expect(kSockLevels[1].by, equals('pattern'));
        expect(kSockLevels[2].by, equals('both'));
      });

      test('level pair counts are 4, 5, 6', () {
        expect(kSockLevels[0].pairs, equals(4));
        expect(kSockLevels[1].pairs, equals(5));
        expect(kSockLevels[2].pairs, equals(6));
      });

      test('all levels have non-empty say text', () {
        for (final level in kSockLevels) {
          expect(level.say.isNotEmpty, isTrue,
              reason: 'sock level missing say text');
        }
      });
    });

    group('kSockColors', () {
      test('has 8 sock colors', () {
        expect(kSockColors.length, equals(8));
      });
    });

    group('kSockPatterns', () {
      test('has 4 sock patterns', () {
        expect(kSockPatterns.length, equals(4));
      });

      test('contains solid, stripe, dots, zig', () {
        expect(kSockPatterns, containsAll(['solid', 'stripe', 'dots', 'zig']));
      });
    });

    group('kDetectiveTitles', () {
      test('is non-empty list', () {
        expect(kDetectiveTitles.isNotEmpty, isTrue);
      });

      test('first title is Junior Detective', () {
        expect(kDetectiveTitles.first, equals('Junior Detective'));
      });

      test('last title is Hidden Object Hero', () {
        expect(kDetectiveTitles.last, equals('Hidden Object Hero'));
      });

      test('has at least 3 titles in ladder', () {
        expect(kDetectiveTitles.length, greaterThanOrEqualTo(3));
      });
    });
  });
}
