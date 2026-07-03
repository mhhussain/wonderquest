import 'package:flutter/material.dart';

import '../theme/wq_colors.dart';

/// An animal with habitat classification and a fun fact.
///
/// Used in Animal Planet's Habitat Hunt and the Around the World
/// continent animal lists (where habitat is set to '' for continent animals).
class Animal {
  final String emoji;
  final String name;
  final String habitat;
  final String fact;

  const Animal({
    required this.emoji,
    required this.name,
    required this.habitat,
    required this.fact,
  });

  @override
  String toString() =>
      'Animal(emoji: $emoji, name: $name, habitat: $habitat)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Animal &&
          runtimeType == other.runtimeType &&
          emoji == other.emoji &&
          name == other.name &&
          habitat == other.habitat &&
          fact == other.fact;

  @override
  int get hashCode =>
      emoji.hashCode ^ name.hashCode ^ habitat.hashCode ^ fact.hashCode;
}

/// A habitat category shown in Animal Planet's Habitat Hunt.
///
/// The 4 habitats are Ocean, Jungle, Arctic, and Savanna.
class Habitat {
  final String id;
  final String name;
  final String emoji;
  final Color color;

  const Habitat({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });

  @override
  String toString() => 'Habitat(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Habitat &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          emoji == other.emoji &&
          color == other.color;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ emoji.hashCode ^ color.hashCode;
}

/// A single ocean creature fact shown in the Ocean Facts activity.
///
/// Fields match the raw sea.jsx OCEAN_FACTS structure: e (emoji), n (name),
/// f (fact text).
class OceanFact {
  final String e;
  final String n;
  final String f;

  const OceanFact({required this.e, required this.n, required this.f});

  @override
  String toString() => 'OceanFact(e: $e, n: $n)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OceanFact &&
          runtimeType == other.runtimeType &&
          e == other.e &&
          n == other.n &&
          f == other.f;

  @override
  int get hashCode => e.hashCode ^ n.hashCode ^ f.hashCode;
}

/// A whale with dive depth, base call frequency, and a fun fact.
///
/// Used in the Whale World activity. Fields match raw sea.jsx WHALES: e, n, f,
/// color (as Color), dive → diveM (meters), base → baseFreq (Hz).
class Whale {
  final String e;
  final String n;
  final String f;
  final Color color;
  final int diveM;
  final double baseFreq;

  const Whale({
    required this.e,
    required this.n,
    required this.f,
    required this.color,
    required this.diveM,
    required this.baseFreq,
  });

  @override
  String toString() => 'Whale(n: $n, diveM: $diveM)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Whale &&
          runtimeType == other.runtimeType &&
          e == other.e &&
          n == other.n &&
          f == other.f &&
          color == other.color &&
          diveM == other.diveM &&
          baseFreq == other.baseFreq;

  @override
  int get hashCode =>
      e.hashCode ^
      n.hashCode ^
      f.hashCode ^
      color.hashCode ^
      diveM.hashCode ^
      baseFreq.hashCode;
}

// ---------------------------------------------------------------------------
// Constants — ported verbatim from raw/data.jsx (HABITATS, ANIMALS)
//             and raw/sea.jsx (OCEAN_FACTS, WHALES).
// ---------------------------------------------------------------------------

/// The 4 habitat categories in Animal Planet (raw/data.jsx HABITATS).
const List<Habitat> kHabitats = [
  Habitat(
    id: 'ocean',
    name: 'Ocean',
    emoji: '🌊',
    color: WqColors.sky,
  ),
  Habitat(
    id: 'jungle',
    name: 'Jungle',
    emoji: '🌴',
    color: WqColors.green,
  ),
  Habitat(
    id: 'arctic',
    name: 'Arctic',
    emoji: '❄️',
    color: WqColors.teal,
  ),
  Habitat(
    id: 'savanna',
    name: 'Savanna',
    emoji: '🌾',
    color: WqColors.orange,
  ),
];

/// The 12 animals in Animal Planet's Habitat Hunt (raw/data.jsx ANIMALS).
const List<Animal> kAnimals = [
  Animal(
    emoji: '🐬',
    name: 'Dolphin',
    habitat: 'ocean',
    fact: 'Dolphins talk to each other with clicks and whistles!',
  ),
  Animal(
    emoji: '🐙',
    name: 'Octopus',
    habitat: 'ocean',
    fact: 'An octopus has three hearts and blue blood!',
  ),
  Animal(
    emoji: '🐠',
    name: 'Fish',
    habitat: 'ocean',
    fact: 'Some fish can change color to hide.',
  ),
  Animal(
    emoji: '🐒',
    name: 'Monkey',
    habitat: 'jungle',
    fact: 'Monkeys use their tails like an extra hand.',
  ),
  Animal(
    emoji: '🦜',
    name: 'Parrot',
    habitat: 'jungle',
    fact: 'Parrots can copy the words people say!',
  ),
  Animal(
    emoji: '🐸',
    name: 'Frog',
    habitat: 'jungle',
    fact: 'A frog drinks water through its skin.',
  ),
  Animal(
    emoji: '🐧',
    name: 'Penguin',
    habitat: 'arctic',
    fact: 'Penguins huddle together to stay warm.',
  ),
  Animal(
    emoji: '🐻‍❄️',
    name: 'Polar Bear',
    habitat: 'arctic',
    fact: 'Polar bears have black skin under white fur!',
  ),
  Animal(
    emoji: '🦭',
    name: 'Seal',
    habitat: 'arctic',
    fact: 'Seals can sleep underwater and float up to breathe.',
  ),
  Animal(
    emoji: '🦁',
    name: 'Lion',
    habitat: 'savanna',
    fact: "A lion's roar can be heard 5 miles away!",
  ),
  Animal(
    emoji: '🦒',
    name: 'Giraffe',
    habitat: 'savanna',
    fact: "A giraffe's tongue is dark blue and very long.",
  ),
  Animal(
    emoji: '🐘',
    name: 'Elephant',
    habitat: 'savanna',
    fact: 'Elephants are so big they cannot jump!',
  ),
];

/// The full ocean-facts pool for the Ocean Facts activity (raw/sea.jsx
/// OCEAN_FACTS).
///
/// Note: the prototype picks 8 to display per session via
/// `shuffle(OCEAN_FACTS).slice(0,8)`; the pool itself has 10 entries.
const List<OceanFact> kOceanFacts = [
  OceanFact(
    e: '🐙',
    n: 'Octopus',
    f: 'An octopus can grow back an arm if it loses one! '
        'It also has THREE hearts and blue blood.',
  ),
  OceanFact(
    e: '🪼',
    n: 'Jellyfish',
    f: 'Jellyfish have no brain, no heart, and no bones — '
        'and some glow in the dark!',
  ),
  OceanFact(
    e: '⭐',
    n: 'Starfish',
    f: 'A starfish can grow a whole new arm, and it pushes its stomach OUT to eat!',
  ),
  OceanFact(
    e: '🦈',
    n: 'Shark',
    f: 'Sharks have lived in the ocean longer than there have been trees on Earth!',
  ),
  OceanFact(
    e: '🐡',
    n: 'Pufferfish',
    f: 'A pufferfish puffs up into a spiky ball to scare away anything hungry.',
  ),
  OceanFact(
    e: '🦐',
    n: 'Pistol Shrimp',
    f: 'The pistol shrimp snaps its claw so fast it makes a tiny flash of light and a loud POP!',
  ),
  OceanFact(
    e: '🐬',
    n: 'Dolphin',
    f: 'Dolphins give each other names using special whistle sounds!',
  ),
  OceanFact(
    e: '🦦',
    n: 'Sea Otter',
    f: "Sea otters hold hands while they sleep so they don't float apart.",
  ),
  OceanFact(
    e: '🐢',
    n: 'Sea Turtle',
    f: 'A sea turtle can hold its breath underwater for hours while it naps.',
  ),
  OceanFact(
    e: '🦀',
    n: 'Crab',
    f: 'Crabs walk sideways and can taste their food with their feet!',
  ),
];

/// The 6 whale species in Whale World (raw/sea.jsx WHALES).
///
/// Colors are the exact hex values from the prototype; dive depths and
/// base call frequencies are verbatim.
const List<Whale> kWhales = [
  Whale(
    e: '🐋',
    n: 'Blue Whale',
    color: Color(0xFF3F77C9),
    diveM: 200,
    f: 'The blue whale is the BIGGEST animal that ever lived — '
        'its heart is as big as a small car!',
    baseFreq: 54.0,
  ),
  Whale(
    e: '🐳',
    n: 'Humpback Whale',
    color: Color(0xFF2E8B8B),
    diveM: 200,
    f: 'Humpback whales sing long songs that can last for hours, '
        'and they leap right out of the water!',
    baseFreq: 90.0,
  ),
  Whale(
    e: '🐋',
    n: 'Sperm Whale',
    color: Color(0xFF6A5ACD),
    diveM: 2000,
    f: 'The sperm whale dives DEEPER than any other whale — '
        'over 2 kilometers down to hunt giant squid!',
    baseFreq: 46.0,
  ),
  Whale(
    e: '🐳',
    n: 'Orca',
    color: Color(0xFF222B33),
    diveM: 150,
    f: 'The orca, or killer whale, is actually the largest dolphin '
        'and hunts together in family pods!',
    baseFreq: 130.0,
  ),
  Whale(
    e: '🐋',
    n: 'Beluga Whale',
    color: Color(0xFF7FB5D6),
    diveM: 700,
    f: 'The white beluga is called the "canary of the sea" because '
        'it chirps and whistles so much!',
    baseFreq: 150.0,
  ),
  Whale(
    e: '🦄',
    n: 'Narwhal',
    color: Color(0xFF5C8AC9),
    diveM: 1500,
    f: 'The narwhal is the "unicorn of the sea" — its long tusk is really a giant tooth!',
    baseFreq: 120.0,
  ),
];
