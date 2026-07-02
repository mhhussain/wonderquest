import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/english_letters.dart';

void main() {
  group('English Letters Content', () {
    test('has 26 English letters A–Z', () {
      expect(kEnglishLetters.length, equals(26));
    });

    test('letter B has word "Bat" and phonetic "buh"', () {
      final letterB = kEnglishLetters.firstWhere((l) => l.u == 'B');
      expect(letterB.word, equals('Bat'));
      expect(letterB.ph, equals('buh'));
    });

    test('all 26 letters are A–Z in order', () {
      const expected = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];
      final actual = kEnglishLetters.map((l) => l.u).toList();
      expect(actual, equals(expected));
    });

    test('each letter has lowercase, word, emoji, and phonetic', () {
      for (final letter in kEnglishLetters) {
        expect(letter.l.length, equals(1));
        expect(letter.word.isNotEmpty, isTrue);
        expect(letter.emoji.isNotEmpty, isTrue);
        expect(letter.ph.isNotEmpty, isTrue);
      }
    });

    test('confusables map contains expected pairs', () {
      expect(kConfusables['b'], equals('d'));
      expect(kConfusables['d'], equals('b'));
      expect(kConfusables['p'], equals('q'));
      expect(kConfusables['q'], equals('p'));
      expect(kConfusables['g'], equals('q'));
      expect(kConfusables['m'], equals('w'));
      expect(kConfusables['a'], equals('e'));
      expect(kConfusables['e'], equals('a'));
    });

    test('match order has 20 letters', () {
      expect(kMatchOrder.length, equals(20));
    });

    test('all letters in match order are uppercase and unique', () {
      final uniqueLetters = kMatchOrder.toSet();
      expect(uniqueLetters.length, equals(20));
      for (final letter in kMatchOrder) {
        expect(letter, equals(letter.toUpperCase()));
      }
    });

    test('has 75 word families total', () {
      expect(kWordFamilies.length, equals(75));
    });

    test('has 55 single-letter onset families (easy)', () {
      final singleOnsetCount = kWordFamilies.where((w) => w.miss.length == 1).length;
      expect(singleOnsetCount, equals(55));
    });

    test('has 20 two-letter blend families (hard)', () {
      final blendCount = kWordFamilies.where((w) => w.miss.length == 2).length;
      expect(blendCount, equals(20));
    });

    test('every word family has emoji, word, end, miss, and distract', () {
      for (final family in kWordFamilies) {
        expect(family.emoji.isNotEmpty, isTrue);
        expect(family.word.isNotEmpty, isTrue);
        expect(family.end.isNotEmpty, isTrue);
        expect(family.miss.isNotEmpty, isTrue);
        expect(family.miss.length, isIn([1, 2])); // single or blend
        expect(family.distract.isNotEmpty, isTrue);
        expect(family.distract.length, equals(3)); // always 3 distractors
      }
    });

    test('every distract entry is a single uppercase letter or valid blend', () {
      final validBlends = {'FR', 'CR', 'FL', 'ST', 'DR', 'TR', 'CL', 'PL', 'SH', 'FI', 'SP', 'BR', 'SN', 'CH', 'BL'};
      for (final family in kWordFamilies) {
        for (final distract in family.distract) {
          final isValidLetter = distract.length == 1 && distract == distract.toUpperCase();
          final isValidBlend = distract.length == 2 && validBlends.contains(distract);
          expect(
            isValidLetter || isValidBlend,
            isTrue,
            reason: 'Invalid distract "$distract" in ${family.word}',
          );
        }
      }
    });

    test('word families have correct structure for BAT', () {
      final bat = kWordFamilies.firstWhere((w) => w.word == 'BAT');
      expect(bat.emoji, equals('🦇'));
      expect(bat.miss, equals(['B']));
      expect(bat.end, equals('AT'));
      expect(bat.distract, equals(['C', 'H', 'R']));
    });

    test('word families have correct structure for FROG (blend)', () {
      final frog = kWordFamilies.firstWhere((w) => w.word == 'FROG');
      expect(frog.emoji, equals('🐸'));
      expect(frog.miss, equals(['F', 'R']));
      expect(frog.end, equals('OG'));
      expect(frog.distract, equals(['C', 'L', 'S']));
    });

    test('no duplicate word families', () {
      final words = kWordFamilies.map((w) => w.word).toSet();
      expect(words.length, equals(kWordFamilies.length));
    });

    test('all word family words are uppercase', () {
      for (final family in kWordFamilies) {
        expect(family.word, equals(family.word.toUpperCase()));
      }
    });
  });
}
