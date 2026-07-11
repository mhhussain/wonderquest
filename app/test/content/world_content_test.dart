import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/world_content.dart';

void main() {
  group('World Content', () {
    group('kContinents', () {
      test('has exactly 7 continents', () {
        expect(kContinents.length, equals(7));
      });

      test('continent ids are unique', () {
        final ids = kContinents.map((c) => c.id).toSet();
        expect(ids.length, equals(kContinents.length));
      });

      test('contains all 7 expected continent ids', () {
        final ids = kContinents.map((c) => c.id).toSet();
        expect(ids, containsAll([
          'africa', 'asia', 'australia', 'antarctica',
          'namerica', 'samerica', 'europe',
        ]));
      });

      test('each continent has 6 animals', () {
        for (final c in kContinents) {
          expect(c.animals.length, equals(6),
              reason: '${c.name} must have exactly 6 animals');
        }
      });

      test('each continent has non-empty name, emoji, badge, theme', () {
        for (final c in kContinents) {
          expect(c.name.isNotEmpty, isTrue, reason: '${c.id} missing name');
          expect(c.emoji.isNotEmpty, isTrue, reason: '${c.id} missing emoji');
          expect(c.badge.isNotEmpty, isTrue, reason: '${c.id} missing badge');
          expect(c.theme.isNotEmpty, isTrue, reason: '${c.id} missing theme');
        }
      });

      test('every continent has non-empty blurb', () {
        for (final c in kContinents) {
          expect(c.blurb.isNotEmpty, isTrue,
              reason: '${c.id} has empty blurb');
        }
      });

      test('Africa has correct color2 hex and blurb', () {
        final africa = kContinents.firstWhere((c) => c.id == 'africa');
        expect(africa.color2.toARGB32(), equals(0xFFF2B441));
        expect(africa.blurb, equals("Let's go on a safari!"));
      });

      test('Antarctica has correct color2 hex and blurb', () {
        final ant = kContinents.firstWhere((c) => c.id == 'antarctica');
        expect(ant.color2.toARGB32(), equals(0xFF8FC4DE));
        expect(ant.blurb, equals('Explore the frozen ice!'));
      });

      test('Africa mission finds lions', () {
        final africa = kContinents.firstWhere((c) => c.id == 'africa');
        expect(africa.mission.find, equals('🦁'));
        expect(africa.mission.n, equals('lions'));
        expect(africa.mission.count, equals(4));
      });

      test('Antarctica mission finds penguins (count 5)', () {
        final ant = kContinents.firstWhere((c) => c.id == 'antarctica');
        expect(ant.mission.find, equals('🐧'));
        expect(ant.mission.count, equals(5));
      });

      test('all continents have valid mission with non-empty find and n', () {
        for (final c in kContinents) {
          expect(c.mission.find.isNotEmpty, isTrue,
              reason: '${c.id} mission.find is empty');
          expect(c.mission.n.isNotEmpty, isTrue,
              reason: '${c.id} mission.n is empty');
          expect(c.mission.count, greaterThan(0),
              reason: '${c.id} mission.count must be positive');
        }
      });
    });

    group('kDiscoveryCards', () {
      test('has exactly 21 cards (3 per continent)', () {
        expect(kDiscoveryCards.length, equals(21));
      });

      test('card ids are unique', () {
        final ids = kDiscoveryCards.map((c) => c.id).toSet();
        expect(ids.length, equals(kDiscoveryCards.length));
      });

      test('every card game.type is a valid MiniGameType', () {
        final validTypes = MiniGameType.values.toSet();
        for (final card in kDiscoveryCards) {
          expect(validTypes, contains(card.game.type),
              reason: '${card.id} has invalid game type');
        }
      });

      test('each continent has exactly 3 discovery cards', () {
        const continentIds = [
          'africa', 'asia', 'europe', 'namerica',
          'samerica', 'australia', 'antarctica',
        ];
        for (final contId in continentIds) {
          final cards = kDiscoveryCards.where((c) => c.id.startsWith(contId)).toList();
          expect(cards.length, equals(3),
              reason: '$contId should have exactly 3 cards');
        }
      });

      test('all cards have non-empty id, e, title, fact, sticker', () {
        for (final card in kDiscoveryCards) {
          expect(card.id.isNotEmpty, isTrue, reason: 'card missing id');
          expect(card.e.isNotEmpty, isTrue, reason: '${card.id} missing emoji');
          expect(card.title.isNotEmpty, isTrue, reason: '${card.id} missing title');
          expect(card.fact.isNotEmpty, isTrue, reason: '${card.id} missing fact');
          expect(card.sticker.isNotEmpty, isTrue, reason: '${card.id} missing sticker');
        }
      });

      test('all cards have non-empty game params say field', () {
        for (final card in kDiscoveryCards) {
          expect(card.game.params.containsKey('say'), isTrue,
              reason: '${card.id} game params missing say');
          expect(
            (card.game.params['say'] as String).isNotEmpty,
            isTrue,
            reason: '${card.id} say is empty',
          );
        }
      });

      test('Africa-0 is Sahara Desert collect game', () {
        final card = kDiscoveryCards.firstWhere((c) => c.id == 'africa-0');
        expect(card.title, equals('Sahara Desert'));
        expect(card.game.type, equals(MiniGameType.collect));
      });

      test('collect games have who, item, n params', () {
        final collectCards =
            kDiscoveryCards.where((c) => c.game.type == MiniGameType.collect);
        for (final card in collectCards) {
          expect(card.game.params.containsKey('who'), isTrue,
              reason: '${card.id} collect missing who');
          expect(card.game.params.containsKey('item'), isTrue,
              reason: '${card.id} collect missing item');
          expect(card.game.params.containsKey('n'), isTrue,
              reason: '${card.id} collect missing n');
        }
      });

      test('order games have items and say params', () {
        final orderCards =
            kDiscoveryCards.where((c) => c.game.type == MiniGameType.order);
        for (final card in orderCards) {
          expect(card.game.params.containsKey('items'), isTrue,
              reason: '${card.id} order missing items');
        }
      });

      test('find games have target, n, deco params', () {
        final findCards =
            kDiscoveryCards.where((c) => c.game.type == MiniGameType.find);
        for (final card in findCards) {
          expect(card.game.params.containsKey('target'), isTrue,
              reason: '${card.id} find missing target');
          expect(card.game.params.containsKey('deco'), isTrue,
              reason: '${card.id} find missing deco');
        }
      });
    });

    group('kWorldWonders', () {
      test('has exactly 7 world wonders', () {
        expect(kWorldWonders.length, equals(7));
      });

      test('all wonders have non-empty emoji and text', () {
        for (final w in kWorldWonders) {
          expect(w.e.isNotEmpty, isTrue, reason: 'wonder missing emoji');
          expect(w.t.isNotEmpty, isTrue, reason: 'wonder missing text');
        }
      });
    });

    group('kWorldFacts', () {
      test('kWorldFacts is non-empty', () {
        expect(kWorldFacts.isNotEmpty, isTrue);
      });

      test('kWorldFacts has 21 entries (3 per continent)', () {
        expect(kWorldFacts.length, equals(21));
      });

      test('all facts are non-empty strings', () {
        for (final f in kWorldFacts) {
          expect(f.isNotEmpty, isTrue, reason: 'world fact is empty');
        }
      });
    });
  });
}
