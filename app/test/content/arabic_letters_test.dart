import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/arabic_letters.dart';

void main() {
  group('ArabicLetter content', () {
    test('has exactly 28 letters', () {
      expect(kArabicLetters.length, 28);
    });

    test('letter ب (Baa) has correct record', () {
      final baa = kArabicLetters.firstWhere((l) => l.g == 'ب');
      expect(baa.g, 'ب');
      expect(baa.nm, 'بَاء');
      expect(baa.tr, 'Baa');
      expect(baa.snd, 'b');
      expect(baa.w, 'بَطَّة');
      expect(baa.wtr, 'batta (duck)');
      expect(baa.e, '🦆');
      expect(baa.base, 'ٮ');
      expect(baa.dots, '1b');
    });

    test('all letters with base form have valid dots code', () {
      final dotsRegex = RegExp(r'^([123][ab]|0)$');
      for (final letter in kArabicLetters) {
        if (letter.base != null) {
          expect(
            letter.dots,
            isNotNull,
            reason: 'Letter ${letter.g} has base but no dots code',
          );
          expect(
            dotsRegex.hasMatch(letter.dots!),
            true,
            reason: 'Letter ${letter.g} (${letter.tr}) has invalid dots code: "${letter.dots}"',
          );
        } else {
          expect(
            letter.dots,
            isNull,
            reason: 'Letter ${letter.g} has dots but no base form',
          );
        }
      }
    });

    test('confusable families are well-formed', () {
      expect(kArabicConfusableFamilies.length, 9);
      for (final family in kArabicConfusableFamilies) {
        expect(family.length, greaterThanOrEqualTo(2),
            reason: 'Family should have at least 2 letters');
      }
    });

    test('clusters cover all 28 letters exactly once', () {
      final allLettersInClusters = <String>{};
      for (final cluster in kArabicClusters) {
        for (final letter in cluster) {
          expect(
            allLettersInClusters.contains(letter),
            false,
            reason: 'Letter $letter appears multiple times across clusters',
          );
          allLettersInClusters.add(letter);
        }
      }

      final allLetterGlyphs = kArabicLetters.map((l) => l.g).toSet();
      expect(allLettersInClusters.length, 28);
      expect(allLettersInClusters, allLetterGlyphs);
    });

    test('all letters have required fields', () {
      for (final letter in kArabicLetters) {
        expect(letter.g, isNotEmpty);
        expect(letter.nm, isNotEmpty);
        expect(letter.tr, isNotEmpty);
        expect(letter.snd, isNotEmpty);
        expect(letter.w, isNotEmpty);
        expect(letter.wtr, isNotEmpty);
        expect(letter.e, isNotEmpty);
      }
    });

    test('confusable families contain only valid letters', () {
      final validGlyphs = kArabicLetters.map((l) => l.g).toSet();
      for (final family in kArabicConfusableFamilies) {
        for (final letter in family) {
          expect(
            validGlyphs.contains(letter),
            true,
            reason: 'Family contains invalid letter: $letter',
          );
        }
      }
    });

    test('clusters contain only valid letters', () {
      final validGlyphs = kArabicLetters.map((l) => l.g).toSet();
      for (final cluster in kArabicClusters) {
        for (final letter in cluster) {
          expect(
            validGlyphs.contains(letter),
            true,
            reason: 'Cluster contains invalid letter: $letter',
          );
        }
      }
    });
  });
}
