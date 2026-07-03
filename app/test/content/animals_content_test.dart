import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/content/animals_content.dart';

void main() {
  group('Animals Content', () {
    group('kHabitats', () {
      test('has exactly 4 habitats', () {
        expect(kHabitats.length, equals(4));
      });

      test('habitat ids are unique', () {
        final ids = kHabitats.map((h) => h.id).toSet();
        expect(ids.length, equals(kHabitats.length));
      });

      test('contains ocean, jungle, arctic, savanna', () {
        final ids = kHabitats.map((h) => h.id).toSet();
        expect(ids, containsAll(['ocean', 'jungle', 'arctic', 'savanna']));
      });

      test('each habitat has non-empty name and emoji', () {
        for (final h in kHabitats) {
          expect(h.name.isNotEmpty, isTrue, reason: 'habitat ${h.id} name is empty');
          expect(h.emoji.isNotEmpty, isTrue, reason: 'habitat ${h.id} emoji is empty');
        }
      });
    });

    group('kAnimals', () {
      test('has exactly 12 animals', () {
        expect(kAnimals.length, equals(12));
      });

      test('all animal habitat ids match a kHabitats entry', () {
        final habitatIds = kHabitats.map((h) => h.id).toSet();
        for (final animal in kAnimals) {
          expect(
            habitatIds,
            contains(animal.habitat),
            reason: '${animal.name} has unknown habitat "${animal.habitat}"',
          );
        }
      });

      test('all animals have non-empty emoji, name, habitat, and fact', () {
        for (final a in kAnimals) {
          expect(a.emoji.isNotEmpty, isTrue, reason: '${a.name} missing emoji');
          expect(a.name.isNotEmpty, isTrue, reason: 'animal missing name');
          expect(a.habitat.isNotEmpty, isTrue, reason: '${a.name} missing habitat');
          expect(a.fact.isNotEmpty, isTrue, reason: '${a.name} missing fact');
        }
      });

      test('contains animals from each habitat', () {
        final habitatIds = kAnimals.map((a) => a.habitat).toSet();
        expect(habitatIds, containsAll(['ocean', 'jungle', 'arctic', 'savanna']));
      });

      test('contains Dolphin in ocean', () {
        final dolphin = kAnimals.firstWhere((a) => a.name == 'Dolphin');
        expect(dolphin.habitat, equals('ocean'));
      });

      test('contains Lion in savanna', () {
        final lion = kAnimals.firstWhere((a) => a.name == 'Lion');
        expect(lion.habitat, equals('savanna'));
      });

      test('contains Polar Bear in arctic', () {
        final pb = kAnimals.firstWhere((a) => a.name == 'Polar Bear');
        expect(pb.habitat, equals('arctic'));
      });
    });

    group('kOceanFacts', () {
      test('has 10 ocean facts (full raw pool)', () {
        expect(kOceanFacts.length, equals(10));
      });

      test('all ocean facts have non-empty e, n, f', () {
        for (final f in kOceanFacts) {
          expect(f.e.isNotEmpty, isTrue, reason: '${f.n} missing emoji');
          expect(f.n.isNotEmpty, isTrue, reason: 'ocean fact missing name');
          expect(f.f.isNotEmpty, isTrue, reason: '${f.n} missing fact text');
        }
      });

      test('contains Octopus fact', () {
        final oct = kOceanFacts.firstWhere((f) => f.n == 'Octopus');
        expect(oct.e, equals('🐙'));
      });

      test('contains Sea Otter fact with hands-holding detail', () {
        final otter = kOceanFacts.firstWhere((f) => f.n == 'Sea Otter');
        expect(otter.f, contains('hold hands'));
      });
    });

    group('kWhales', () {
      test('has exactly 6 whales', () {
        expect(kWhales.length, equals(6));
      });

      test('Sperm Whale dives 2000 m', () {
        final sperm = kWhales.firstWhere((w) => w.n == 'Sperm Whale');
        expect(sperm.diveM, equals(2000));
      });

      test('Blue Whale dives 200 m', () {
        final blue = kWhales.firstWhere((w) => w.n == 'Blue Whale');
        expect(blue.diveM, equals(200));
      });

      test('Narwhal dives 1500 m', () {
        final narwhal = kWhales.firstWhere((w) => w.n == 'Narwhal');
        expect(narwhal.diveM, equals(1500));
      });

      test('Orca dives 150 m', () {
        final orca = kWhales.firstWhere((w) => w.n == 'Orca');
        expect(orca.diveM, equals(150));
      });

      test('contains Blue, Humpback, Sperm, Orca, Beluga, Narwhal', () {
        final names = kWhales.map((w) => w.n).toSet();
        expect(names, containsAll([
          'Blue Whale', 'Humpback Whale', 'Sperm Whale',
          'Orca', 'Beluga Whale', 'Narwhal',
        ]));
      });

      test('all whales have non-empty e, n, f and valid baseFreq', () {
        for (final w in kWhales) {
          expect(w.e.isNotEmpty, isTrue, reason: '${w.n} missing emoji');
          expect(w.n.isNotEmpty, isTrue, reason: 'whale missing name');
          expect(w.f.isNotEmpty, isTrue, reason: '${w.n} missing fact');
          expect(w.baseFreq, greaterThan(0.0), reason: '${w.n} baseFreq must be positive');
          expect(w.diveM, greaterThan(0), reason: '${w.n} diveM must be positive');
        }
      });

      test('whale names are unique', () {
        final names = kWhales.map((w) => w.n).toSet();
        expect(names.length, equals(kWhales.length));
      });
    });
  });
}
