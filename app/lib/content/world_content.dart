import 'package:flutter/material.dart';

import 'animals_content.dart';

// ---------------------------------------------------------------------------
// Mini-game types and specs for Discovery Cards (raw/cards-data.jsx).
// ---------------------------------------------------------------------------

/// The type of mini-game embedded in a Discovery Card.
enum MiniGameType {
  /// Player moves a character to collect falling items.
  collect,

  /// Player taps items in size/speed order.
  order,

  /// Player taps pieces in sequence to construct a landmark.
  build,

  /// Player taps decoration spots on a base object.
  decorate,

  /// Player taps hidden targets scattered through a scene.
  find,
}

/// The mini-game spec embedded in a [DiscoveryCard].
///
/// [type] identifies the game mechanic; [params] carries all game-specific
/// parameters verbatim from raw/cards-data.jsx (e.g. who, item, n, say for
/// collect games; pieces, say for build games).
class MiniGameSpec {
  final MiniGameType type;
  final Map<String, Object> params;

  const MiniGameSpec({required this.type, required this.params});

  @override
  String toString() => 'MiniGameSpec(type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MiniGameSpec &&
          runtimeType == other.runtimeType &&
          type == other.type;

  @override
  int get hashCode => type.hashCode;
}

/// A collectible discovery card shown on a continent (raw/cards-data.jsx).
class DiscoveryCard {
  final String id;
  final String e;
  final String title;
  final String fact;
  final String sticker;
  final MiniGameSpec game;

  const DiscoveryCard({
    required this.id,
    required this.e,
    required this.title,
    required this.fact,
    required this.sticker,
    required this.game,
  });

  @override
  String toString() => 'DiscoveryCard(id: $id, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveryCard &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}

// ---------------------------------------------------------------------------
// Continent mission spec (raw/world-data.jsx mission field).
// ---------------------------------------------------------------------------

/// The hidden-discovery mission embedded in each [Continent].
///
/// [find] is the emoji to hunt, [n] is the plural label, [count] is how many
/// to find.
class MissionSpec {
  final String find;
  final String n;
  final int count;

  const MissionSpec({
    required this.find,
    required this.n,
    required this.count,
  });

  @override
  String toString() => 'MissionSpec(find: $find, n: $n, count: $count)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissionSpec &&
          runtimeType == other.runtimeType &&
          find == other.find &&
          n == other.n &&
          count == other.count;

  @override
  int get hashCode => find.hashCode ^ n.hashCode ^ count.hashCode;
}

/// A world continent with animals, color, badge and hidden-discovery mission.
///
/// Ported from raw/world-data.jsx WORLD. The [animals] list reuses [Animal]
/// from animals_content.dart; habitat is set to '' for continent animals since
/// they do not belong to the Animal Planet habitat categories.
class Continent {
  final String id;
  final String name;
  final String emoji;
  final String badge;
  final String theme;
  final Color color;
  final List<Animal> animals;
  final MissionSpec mission;

  const Continent({
    required this.id,
    required this.name,
    required this.emoji,
    required this.badge,
    required this.theme,
    required this.color,
    required this.animals,
    required this.mission,
  });

  @override
  String toString() => 'Continent(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Continent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

/// A collectible world-wonder card (raw/world-data.jsx WONDER_CARDS).
class WorldWonder {
  final String e;
  final String t;

  const WorldWonder({required this.e, required this.t});

  @override
  String toString() => 'WorldWonder(e: $e)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldWonder &&
          runtimeType == other.runtimeType &&
          e == other.e &&
          t == other.t;

  @override
  int get hashCode => e.hashCode ^ t.hashCode;
}

// ---------------------------------------------------------------------------
// Constants — ported verbatim from raw/world-data.jsx and raw/cards-data.jsx.
// ---------------------------------------------------------------------------

/// The 7 continents in Around the World (raw/world-data.jsx WORLD).
const List<Continent> kContinents = [
  Continent(
    id: 'africa',
    name: 'Africa',
    emoji: '🦁',
    badge: '🦁',
    theme: 'Safari Adventure',
    color: Color(0xFFE8893B),
    animals: [
      Animal(emoji: '🦁', name: 'Lion', habitat: '',
          fact: "A lion's roar can be heard 5 miles away!"),
      Animal(emoji: '🐘', name: 'Elephant', habitat: '',
          fact: 'Elephants are so big they cannot jump!'),
      Animal(emoji: '🦒', name: 'Giraffe', habitat: '',
          fact: "A giraffe's tongue is dark blue and very long."),
      Animal(emoji: '🦓', name: 'Zebra', habitat: '',
          fact: 'Every zebra has its own pattern of stripes.'),
      Animal(emoji: '🦛', name: 'Hippo', habitat: '',
          fact: 'Hippos can hold their breath underwater for 5 minutes.'),
      Animal(emoji: '🐆', name: 'Cheetah', habitat: '',
          fact: 'Cheetahs are the fastest animals on land!'),
    ],
    mission: MissionSpec(find: '🦁', n: 'lions', count: 4),
  ),
  Continent(
    id: 'asia',
    name: 'Asia',
    emoji: '🐼',
    badge: '🐼',
    theme: 'Panda Mountain',
    color: Color(0xFFD85B6A),
    animals: [
      Animal(emoji: '🐼', name: 'Panda', habitat: '',
          fact: 'Pandas eat bamboo for 12 hours every day!'),
      Animal(emoji: '🐯', name: 'Tiger', habitat: '',
          fact: 'Tigers are the biggest wild cats in the world.'),
      Animal(emoji: '🦧', name: 'Orangutan', habitat: '',
          fact: 'Orangutans build a new nest in the trees every night.'),
      Animal(emoji: '🐆', name: 'Snow Leopard', habitat: '',
          fact: 'Snow leopards wrap their long tails around them like a scarf.'),
      Animal(emoji: '🦝', name: 'Red Panda', habitat: '',
          fact: 'Red pandas are about the size of a house cat.'),
      Animal(emoji: '🐘', name: 'Elephant', habitat: '',
          fact: 'Asian elephants have smaller ears than African ones.'),
    ],
    mission: MissionSpec(find: '🐼', n: 'pandas', count: 4),
  ),
  Continent(
    id: 'australia',
    name: 'Australia',
    emoji: '🦘',
    badge: '🦘',
    theme: 'Outback Discovery',
    color: Color(0xFFC9742E),
    animals: [
      Animal(emoji: '🦘', name: 'Kangaroo', habitat: '',
          fact: 'Baby kangaroos are called joeys and ride in a pouch.'),
      Animal(emoji: '🐨', name: 'Koala', habitat: '',
          fact: 'Koalas sleep most of the day in gum trees.'),
      Animal(emoji: '🦡', name: 'Wombat', habitat: '',
          fact: 'Wombat poop is shaped like little cubes!'),
      Animal(emoji: '🐦', name: 'Emu', habitat: '',
          fact: 'Emus are big birds that cannot fly but run very fast.'),
      Animal(emoji: '🐊', name: 'Crocodile', habitat: '',
          fact: 'Saltwater crocodiles are the largest reptiles alive.'),
      Animal(emoji: '🐠', name: 'Reef Fish', habitat: '',
          fact: 'The Great Barrier Reef is the biggest coral reef on Earth.'),
    ],
    mission: MissionSpec(find: '🦘', n: 'kangaroos', count: 3),
  ),
  Continent(
    id: 'antarctica',
    name: 'Antarctica',
    emoji: '🐧',
    badge: '🐧',
    theme: 'Frozen Mission',
    color: Color(0xFF4C8FB5),
    animals: [
      Animal(emoji: '🐧', name: 'Penguin', habitat: '',
          fact: 'Penguins huddle together to stay warm in the cold.'),
      Animal(emoji: '🦭', name: 'Seal', habitat: '',
          fact: 'Seals can sleep underwater and float up to breathe.'),
      Animal(emoji: '🐋', name: 'Whale', habitat: '',
          fact: 'The blue whale is the largest animal that ever lived!'),
      Animal(emoji: '🐦‍⬛', name: 'Skua', habitat: '',
          fact: 'Skuas are brave birds that fly over the icy sea.'),
      Animal(emoji: '🦐', name: 'Krill', habitat: '',
          fact: 'Tiny krill feed almost every animal in Antarctica.'),
      Animal(emoji: '❄️', name: 'Ice', habitat: '',
          fact: 'Antarctic ice can be thousands of years old.'),
    ],
    mission: MissionSpec(find: '🐧', n: 'penguins', count: 5),
  ),
  Continent(
    id: 'namerica',
    name: 'North America',
    emoji: '🦅',
    badge: '🦅',
    theme: 'Forest & Lakes',
    color: Color(0xFF5C9E58),
    animals: [
      Animal(emoji: '🐻', name: 'Bear', habitat: '',
          fact: 'Bears take a long winter sleep called hibernation.'),
      Animal(emoji: '🦬', name: 'Bison', habitat: '',
          fact: 'Bison are the largest land animals in North America.'),
      Animal(emoji: '🦅', name: 'Bald Eagle', habitat: '',
          fact: 'Bald eagles build the biggest nests of any bird.'),
      Animal(emoji: '🫎', name: 'Moose', habitat: '',
          fact: 'Moose are great swimmers and love the water.'),
      Animal(emoji: '🦝', name: 'Raccoon', habitat: '',
          fact: 'Raccoons wash their food with their clever paws.'),
      Animal(emoji: '🦫', name: 'Beaver', habitat: '',
          fact: 'Beavers build dams across rivers with sticks.'),
    ],
    mission: MissionSpec(find: '🦅', n: 'eagles', count: 4),
  ),
  Continent(
    id: 'samerica',
    name: 'South America',
    emoji: '🦥',
    badge: '🦥',
    theme: 'Amazon Rainforest',
    color: Color(0xFF3FA68A),
    animals: [
      Animal(emoji: '🦥', name: 'Sloth', habitat: '',
          fact: 'Sloths sleep up to 15 hours and move very, very slowly.'),
      Animal(emoji: '🦙', name: 'Llama', habitat: '',
          fact: 'Llamas hum to talk to each other.'),
      Animal(emoji: '🐆', name: 'Jaguar', habitat: '',
          fact: 'Jaguars are great swimmers and love the water.'),
      Animal(emoji: '🦫', name: 'Capybara', habitat: '',
          fact: 'Capybaras are the largest rodents in the world.'),
      Animal(emoji: '🦜', name: 'Toucan', habitat: '',
          fact: "A toucan's big colorful beak helps it reach fruit."),
      Animal(emoji: '🐒', name: 'Monkey', habitat: '',
          fact: 'Monkeys use their tails like an extra hand.'),
    ],
    mission: MissionSpec(find: '🦥', n: 'sloths', count: 3),
  ),
  Continent(
    id: 'europe',
    name: 'Europe',
    emoji: '🦊',
    badge: '🏰',
    theme: 'Castles & Forests',
    color: Color(0xFF8E72C7),
    animals: [
      Animal(emoji: '🦔', name: 'Hedgehog', habitat: '',
          fact: 'Hedgehogs roll into a spiky ball when they feel scared.'),
      Animal(emoji: '🦊', name: 'Fox', habitat: '',
          fact: 'Foxes can hear a mouse moving under the snow.'),
      Animal(emoji: '🦌', name: 'Deer', habitat: '',
          fact: 'Deer grow new antlers on their heads every year.'),
      Animal(emoji: '🦉', name: 'Owl', habitat: '',
          fact: 'Owls can turn their heads almost all the way around.'),
      Animal(emoji: '🐗', name: 'Boar', habitat: '',
          fact: 'Wild boars love to roll in the mud to stay cool.'),
      Animal(emoji: '🐿️', name: 'Squirrel', habitat: '',
          fact: 'Squirrels hide thousands of nuts to eat in winter.'),
    ],
    mission: MissionSpec(find: '🦊', n: 'foxes', count: 4),
  ),
];

/// The 21 discovery cards, 3 per continent (raw/cards-data.jsx CARD_SETS).
///
/// IDs follow the pattern `<continentId>-<index>`.
const List<DiscoveryCard> kDiscoveryCards = [
  // ── Africa ────────────────────────────────────────────────────────────────
  DiscoveryCard(
    id: 'africa-0',
    e: '🏜️',
    title: 'Sahara Desert',
    fact: 'The Sahara is the largest hot desert on Earth. It is in Africa!',
    sticker: '🐪',
    game: MiniGameSpec(
      type: MiniGameType.collect,
      params: <String, Object>{
        'who': '🐪',
        'item': '💧',
        'n': 6,
        'say': 'Help the camel collect water drops!',
      },
    ),
  ),
  DiscoveryCard(
    id: 'africa-1',
    e: '🦒',
    title: 'Tallest Animal',
    fact: 'Giraffes are the tallest animals in the whole world!',
    sticker: '🦒',
    game: MiniGameSpec(
      type: MiniGameType.order,
      params: <String, Object>{
        'items': <Map<String, Object>>[
          <String, Object>{'e': '🐁', 's': 1},
          <String, Object>{'e': '🐈', 's': 2},
          <String, Object>{'e': '🦓', 's': 3},
          <String, Object>{'e': '🦒', 's': 4},
        ],
        'say': 'Tap the animals from shortest to tallest!',
      },
    ),
  ),
  DiscoveryCard(
    id: 'africa-2',
    e: '🦁',
    title: 'King Lion',
    fact: 'Lions are called the kings of the savanna.',
    sticker: '🦁',
    game: MiniGameSpec(
      type: MiniGameType.find,
      params: <String, Object>{
        'target': '🦁',
        'n': 4,
        'deco': <String>['🌾', '🌳', '🪨', '🌅'],
        'say': 'Find the hidden lion cubs!',
      },
    ),
  ),

  // ── Asia ──────────────────────────────────────────────────────────────────
  DiscoveryCard(
    id: 'asia-0',
    e: '🐼',
    title: 'Giant Panda',
    fact: 'Pandas live naturally only in Asia. They love bamboo!',
    sticker: '🐼',
    game: MiniGameSpec(
      type: MiniGameType.collect,
      params: <String, Object>{
        'who': '🐼',
        'item': '🎋',
        'n': 6,
        'say': 'Help the panda collect bamboo!',
      },
    ),
  ),
  DiscoveryCard(
    id: 'asia-1',
    e: '🏯',
    title: 'Great Wall',
    fact: 'The Great Wall of China is one of the longest walls ever built!',
    sticker: '🏯',
    game: MiniGameSpec(
      type: MiniGameType.build,
      params: <String, Object>{
        'pieces': <String>['🧱', '🧱', '🧱', '🏯'],
        'say': 'Tap the blocks to rebuild the Great Wall!',
      },
    ),
  ),
  DiscoveryCard(
    id: 'asia-2',
    e: '⛰️',
    title: 'Mount Everest',
    fact: 'Mount Everest is the tallest mountain on Earth!',
    sticker: '🚩',
    game: MiniGameSpec(
      type: MiniGameType.collect,
      params: <String, Object>{
        'who': '🧗',
        'item': '🚩',
        'n': 5,
        'say': 'Climb up and collect the flags!',
      },
    ),
  ),

  // ── Europe ────────────────────────────────────────────────────────────────
  DiscoveryCard(
    id: 'europe-0',
    e: '🗼',
    title: 'Eiffel Tower',
    fact: 'The Eiffel Tower is in Paris, France. It is made of iron!',
    sticker: '🗼',
    game: MiniGameSpec(
      type: MiniGameType.build,
      params: <String, Object>{
        'pieces': <String>['🟫', '🔲', '🔼', '🗼'],
        'say': 'Stack the pieces to build the Eiffel Tower!',
      },
    ),
  ),
  DiscoveryCard(
    id: 'europe-1',
    e: '🏰',
    title: 'Castles',
    fact: 'Europe is famous for its big stone castles.',
    sticker: '🏰',
    game: MiniGameSpec(
      type: MiniGameType.build,
      params: <String, Object>{
        'pieces': <String>['🟫', '🧱', '🚪', '🏰'],
        'say': 'Build your own castle, tap each piece!',
      },
    ),
  ),
  DiscoveryCard(
    id: 'europe-2',
    e: '🦔',
    title: 'Hedgehog',
    fact: 'Hedgehogs roll into a spiky ball when they feel scared.',
    sticker: '🦔',
    game: MiniGameSpec(
      type: MiniGameType.find,
      params: <String, Object>{
        'target': '🦔',
        'n': 4,
        'deco': <String>['🍂', '🌰', '🌲', '🍄'],
        'say': 'Find the hidden hedgehogs!',
      },
    ),
  ),

  // ── North America ─────────────────────────────────────────────────────────
  DiscoveryCard(
    id: 'namerica-0',
    e: '🦅',
    title: 'Bald Eagle',
    fact: 'The bald eagle is a famous bird of North America.',
    sticker: '🦅',
    game: MiniGameSpec(
      type: MiniGameType.collect,
      params: <String, Object>{
        'who': '🦅',
        'item': '⭐',
        'n': 6,
        'say': 'Fly the eagle and collect the stars!',
      },
    ),
  ),
  DiscoveryCard(
    id: 'namerica-1',
    e: '🦬',
    title: 'American Bison',
    fact: 'Bison are some of the largest animals in North America.',
    sticker: '🦬',
    game: MiniGameSpec(
      type: MiniGameType.collect,
      params: <String, Object>{
        'who': '🦬',
        'item': '🌾',
        'n': 6,
        'say': 'Help the bison herd find grass!',
      },
    ),
  ),
  DiscoveryCard(
    id: 'namerica-2',
    e: '🌊',
    title: 'Great Lakes',
    fact: "The Great Lakes hold a huge amount of the world's fresh water.",
    sticker: '🌊',
    game: MiniGameSpec(
      type: MiniGameType.decorate,
      params: <String, Object>{
        'base': '🗺️',
        'spot': '💧',
        'n': 5,
        'say': 'Tap to fill the Great Lakes with water!',
      },
    ),
  ),

  // ── South America ─────────────────────────────────────────────────────────
  DiscoveryCard(
    id: 'samerica-0',
    e: '🌳',
    title: 'Amazon Jungle',
    fact: 'The Amazon is the largest rainforest on Earth!',
    sticker: '🌳',
    game: MiniGameSpec(
      type: MiniGameType.find,
      params: <String, Object>{
        'target': '🐒',
        'n': 4,
        'deco': <String>['🌴', '🌿', '🍃', '🌺'],
        'say': 'Find the hidden jungle monkeys!',
      },
    ),
  ),
  DiscoveryCard(
    id: 'samerica-1',
    e: '🦥',
    title: 'Slow Sloth',
    fact: 'Sloths move very, very slowly through the trees.',
    sticker: '🦥',
    game: MiniGameSpec(
      type: MiniGameType.order,
      params: <String, Object>{
        'items': <Map<String, Object>>[
          <String, Object>{'e': '🦥', 's': 1},
          <String, Object>{'e': '🐢', 's': 2},
          <String, Object>{'e': '🐇', 's': 3},
          <String, Object>{'e': '🐆', 's': 4},
        ],
        'say': 'Tap the animals from slowest to fastest!',
      },
    ),
  ),
  DiscoveryCard(
    id: 'samerica-2',
    e: '🦜',
    title: 'Toucan',
    fact: 'Toucans have big, colorful beaks to reach fruit.',
    sticker: '🦜',
    game: MiniGameSpec(
      type: MiniGameType.decorate,
      params: <String, Object>{
        'base': '🦜',
        'spot': '🌈',
        'n': 5,
        'say': 'Decorate the toucan with rainbow colors!',
      },
    ),
  ),

  // ── Australia ─────────────────────────────────────────────────────────────
  DiscoveryCard(
    id: 'australia-0',
    e: '🦘',
    title: 'Kangaroo',
    fact: 'Kangaroos are native to Australia. Babies are called joeys!',
    sticker: '🦘',
    game: MiniGameSpec(
      type: MiniGameType.collect,
      params: <String, Object>{
        'who': '🦘',
        'item': '👶',
        'n': 5,
        'say': 'Hop and collect the baby joeys!',
      },
    ),
  ),
  DiscoveryCard(
    id: 'australia-1',
    e: '🐨',
    title: 'Sleepy Koala',
    fact: 'Koalas sleep for most of the day in gum trees.',
    sticker: '🐨',
    game: MiniGameSpec(
      type: MiniGameType.collect,
      params: <String, Object>{
        'who': '🐨',
        'item': '🌿',
        'n': 6,
        'say': 'Help the koala find eucalyptus leaves!',
      },
    ),
  ),
  DiscoveryCard(
    id: 'australia-2',
    e: '🐠',
    title: 'Great Reef',
    fact: 'The Great Barrier Reef is the largest coral reef in the world!',
    sticker: '🐠',
    game: MiniGameSpec(
      type: MiniGameType.find,
      params: <String, Object>{
        'target': '🐠',
        'n': 5,
        'deco': <String>['🪸', '🐚', '🌊', '🦀'],
        'say': 'Find the colorful reef fish!',
      },
    ),
  ),

  // ── Antarctica ────────────────────────────────────────────────────────────
  DiscoveryCard(
    id: 'antarctica-0',
    e: '🐧',
    title: 'Penguin',
    fact: 'Penguins live in icy Antarctica and slide on their bellies!',
    sticker: '🐧',
    game: MiniGameSpec(
      type: MiniGameType.collect,
      params: <String, Object>{
        'who': '🐧',
        'item': '🐟',
        'n': 6,
        'say': 'Slide the penguin and catch the fish!',
      },
    ),
  ),
  DiscoveryCard(
    id: 'antarctica-1',
    e: '❄️',
    title: 'Coldest Place',
    fact: 'Antarctica is the coldest continent on Earth. Bundle up!',
    sticker: '🧣',
    game: MiniGameSpec(
      type: MiniGameType.decorate,
      params: <String, Object>{
        'base': '🧑',
        'spot': '🧣',
        'n': 4,
        'say': 'Dress the explorer warmly for the cold!',
      },
    ),
  ),
  DiscoveryCard(
    id: 'antarctica-2',
    e: '🐋',
    title: 'Blue Whale',
    fact: 'The blue whale is the largest animal that has ever lived!',
    sticker: '🐋',
    game: MiniGameSpec(
      type: MiniGameType.order,
      params: <String, Object>{
        'items': <Map<String, Object>>[
          <String, Object>{'e': '🐟', 's': 1},
          <String, Object>{'e': '🐬', 's': 2},
          <String, Object>{'e': '🦈', 's': 3},
          <String, Object>{'e': '🐋', 's': 4},
        ],
        'say': 'Tap the sea animals from smallest to biggest!',
      },
    ),
  ),
];

/// The 7 world-wonder collectible cards (raw/world-data.jsx WONDER_CARDS).
const List<WorldWonder> kWorldWonders = [
  WorldWonder(e: '🐼', t: 'Pandas live in Asia.'),
  WorldWonder(e: '🦘', t: 'Kangaroos live in Australia.'),
  WorldWonder(e: '🐧', t: 'Penguins thrive in Antarctica.'),
  WorldWonder(e: '🦁', t: 'Lions roam the African safari.'),
  WorldWonder(e: '🦥', t: 'Sloths hang in South America.'),
  WorldWonder(e: '🦅', t: 'Bald eagles soar in North America.'),
  WorldWonder(e: '🦊', t: 'Foxes roam European forests.'),
];

/// Flat list of all continent facts — 3 per continent, 21 total —
/// for use as a scrolling fact ribbon in the Around the World land.
///
/// Sourced from raw/world-data.jsx WORLD[*].facts.
const List<String> kWorldFacts = [
  // Africa
  "Africa has the world's largest hot desert — the Sahara!",
  'Giraffes are the tallest animals on Earth.',
  'Elephants are the largest land animals.',
  // Asia
  'Asia is the largest continent on Earth.',
  'Pandas come from the mountains of Asia.',
  'Mount Everest, the tallest mountain, is in Asia.',
  // Australia
  'Australia is both a country AND a continent.',
  'Kangaroos can hop as fast as a car drives in town!',
  'Koalas sleep up to 20 hours every day.',
  // Antarctica
  'Antarctica is the coldest place on Earth.',
  'No people live there forever — only visiting scientists.',
  'It is covered by a thick blanket of ice.',
  // North America
  'North America has the huge Great Lakes — like inland seas.',
  'The bald eagle is a famous bird found here.',
  'It has tall mountains, big forests, and wide canyons.',
  // South America
  'The Amazon is the biggest rainforest in the world.',
  'Sloths move so slowly that plants grow on their fur!',
  'It is home to more kinds of animals than anywhere else.',
  // Europe
  'Europe has thousands of old castles to explore.',
  "Some of the world's oldest cities are in Europe.",
  'You can ride trains between many countries.',
];
