import 'package:flutter/material.dart';

import '../domain/spot_scene_engine.dart';

/// A scene spec for the Spot Me / Hidden Object Hunt activity.
///
/// [name] is the display name, [emoji] is the scene icon, [bg] is the
/// background color, [deco] is the pool of scenery emojis scattered in the
/// scene, and [dark] flags scenes that need a light-text UI (e.g. Space).
///
/// Ported from raw/spot-data.jsx SPOT_SCENES.
class SpotSceneSpec {
  final String name;
  final String emoji;
  final Color bg;
  final List<String> deco;
  final bool dark;

  const SpotSceneSpec({
    required this.name,
    required this.emoji,
    required this.bg,
    required this.deco,
    this.dark = false,
  });

  @override
  String toString() => 'SpotSceneSpec(name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpotSceneSpec &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          emoji == other.emoji;

  @override
  int get hashCode => name.hashCode ^ emoji.hashCode;
}

/// A single Match-the-Socks difficulty level (raw/spot-data.jsx SOCK_LEVELS).
///
/// [pairs] is the number of sock pairs to match, [by] is the matching
/// criterion ('color' | 'pattern' | 'both'), and [say] is the TTS
/// instruction text.
class SockLevel {
  final int pairs;
  final String by;
  final String say;

  const SockLevel({
    required this.pairs,
    required this.by,
    required this.say,
  });

  @override
  String toString() => 'SockLevel(pairs: $pairs, by: $by)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SockLevel &&
          runtimeType == other.runtimeType &&
          pairs == other.pairs &&
          by == other.by &&
          say == other.say;

  @override
  int get hashCode => pairs.hashCode ^ by.hashCode ^ say.hashCode;
}

// ---------------------------------------------------------------------------
// Constants — ported verbatim from raw/spot-data.jsx.
// ---------------------------------------------------------------------------

/// The 5 primary scenes used in the Hidden Object Hunt activity.
///
/// Subset of raw/spot-data.jsx SPOT_SCENES: Picnic, Carnival, Aquarium,
/// Beach, Space — matching the brief's named 5 + the HUNT_ROUNDS that
/// reference these scenes.
const List<SpotSceneSpec> kSpotScenes = [
  SpotSceneSpec(
    name: 'Picnic Day',
    emoji: '🧺',
    bg: Color(0xFFBFE89A),
    deco: ['🌳', '🌷', '🍃', '🟫', '☁️', '🌼', '🪨', '🐜'],
  ),
  SpotSceneSpec(
    name: 'Carnival',
    emoji: '🎪',
    bg: Color(0xFFF6BFD8),
    deco: ['🎈', '🎡', '🎠', '🍭', '🎢', '🎟️', '🍿', '✨'],
  ),
  SpotSceneSpec(
    name: 'Aquarium',
    emoji: '🐠',
    bg: Color(0xFF7FD0E6),
    deco: ['🫧', '🪸', '🌊', '🐚', '🌿', '🪨', '💧', '🐟'],
  ),
  SpotSceneSpec(
    name: 'Beach Day',
    emoji: '🏖️',
    bg: Color(0xFFFFE3A8),
    deco: ['🌊', '🐚', '⛱️', '🩴', '☀️', '🪨', '🏐', '🦀'],
  ),
  SpotSceneSpec(
    name: 'Space Station',
    emoji: '🚀',
    bg: Color(0xFF2C2456),
    deco: ['⭐', '🪐', '🌙', '☄️', '🛸', '🌟', '✨', '👽'],
    dark: true,
  ),
];

/// The 3 Match-the-Socks difficulty levels (raw/spot-data.jsx SOCK_LEVELS).
///
/// Progression: color-only → pattern-only → both.
const List<SockLevel> kSockLevels = [
  SockLevel(
    pairs: 4,
    by: 'color',
    say: 'Find the socks that are the same color!',
  ),
  SockLevel(
    pairs: 5,
    by: 'pattern',
    say: 'Find the socks with the same pattern!',
  ),
  SockLevel(
    pairs: 6,
    by: 'both',
    say: 'Find the matching sock pairs!',
  ),
];

/// The 8 sock colors used in Match-the-Socks (raw/spot-data.jsx SOCK_COLORS).
const List<Color> kSockColors = [
  Color(0xFFE84B4B),
  Color(0xFF3F86D6),
  Color(0xFFF2C233),
  Color(0xFF5FB94B),
  Color(0xFF9B6FE0),
  Color(0xFFFF8A3D),
  Color(0xFF2BB3C6),
  Color(0xFFF472A8),
];

/// The 4 sock patterns used in Match-the-Socks (raw/spot-data.jsx
/// SOCK_PATTERNS).
const List<String> kSockPatterns = ['solid', 'stripe', 'dots', 'zig'];

/// The detective rank ladder for the Spot Me land.
///
/// Players progress from 'Junior Detective' to 'Hidden Object Hero' as they
/// complete more spot rounds.
const List<String> kDetectiveTitles = [
  'Junior Detective',
  'Rookie Spotter',
  'Scene Explorer',
  'Ace Detective',
  'Hidden Object Hero',
];

// ---------------------------------------------------------------------------
// Full 9-scene map (raw/spot-data.jsx SPOT_SCENES verbatim).
// ---------------------------------------------------------------------------

/// All 9 Spot Me scenes keyed by their identifier.
///
/// [kSpotScenes] contains the original 5 (Picnic, Carnival, Aquarium, Beach,
/// Space). This map extends that with Playground, Museum, Safari, and Farm
/// which are required by the game round data below.
const Map<String, SpotSceneSpec> kSceneMap = {
  'picnic': SpotSceneSpec(
    name: 'Picnic Day',
    emoji: '🧺',
    bg: Color(0xFFBFE89A),
    deco: ['🌳', '🌷', '🍃', '🟫', '☁️', '🌼', '🪨', '🐜'],
  ),
  'playground': SpotSceneSpec(
    name: 'Playground',
    emoji: '🛝',
    bg: Color(0xFFA9DCF0),
    deco: ['🌳', '☁️', '🌷', '🟫', '🐦', '🍃', '⚽', '🪁'],
  ),
  'aquarium': SpotSceneSpec(
    name: 'Aquarium',
    emoji: '🐠',
    bg: Color(0xFF7FD0E6),
    deco: ['🫧', '🪸', '🌊', '🐚', '🌿', '🪨', '💧', '🐟'],
  ),
  'museum': SpotSceneSpec(
    name: 'Dino Museum',
    emoji: '🦕',
    bg: Color(0xFFE7CFA1),
    deco: ['🦴', '🥚', '🌋', '🪨', '🌿', '🟫', '⛰️', '🍃'],
  ),
  'safari': SpotSceneSpec(
    name: 'Safari Park',
    emoji: '🦁',
    bg: Color(0xFFF2D98C),
    deco: ['🌴', '🌾', '🪨', '☁️', '🌳', '🌅', '🍃', '🟫'],
  ),
  'farm': SpotSceneSpec(
    name: 'Farm Life',
    emoji: '🚜',
    bg: Color(0xFFC7E89A),
    deco: ['🌽', '🌾', '🌳', '🟫', '☁️', '🚜', '🪣', '🍃'],
  ),
  'beach': SpotSceneSpec(
    name: 'Beach Day',
    emoji: '🏖️',
    bg: Color(0xFFFFE3A8),
    deco: ['🌊', '🐚', '⛱️', '🩴', '☀️', '🪨', '🏐', '🦀'],
  ),
  'space': SpotSceneSpec(
    name: 'Space Station',
    emoji: '🚀',
    bg: Color(0xFF2C2456),
    deco: ['⭐', '🪐', '🌙', '☄️', '🛸', '🌟', '✨', '👽'],
    dark: true,
  ),
  'carnival': SpotSceneSpec(
    name: 'Carnival',
    emoji: '🎪',
    bg: Color(0xFFF6BFD8),
    deco: ['🎈', '🎡', '🎠', '🍭', '🎢', '🎟️', '🍿', '✨'],
  ),
};

// ---------------------------------------------------------------------------
// Round data types — ported from raw/spot-data.jsx.
// ---------------------------------------------------------------------------

/// One round of the Hidden Object Hunt or Animal Tracker game.
///
/// [sceneKey] maps into [kSceneMap]. [goals] is the list of targets to find.
/// [extraDeco] optional additional decoy pool (for Animal Tracker).
class HuntRound {
  final String sceneKey;
  final List<SpotGoal> goals;
  final List<String> extraDeco;

  const HuntRound({
    required this.sceneKey,
    required this.goals,
    this.extraDeco = const [],
  });
}

/// One round of the Count It If You Can game.
///
/// [char] is the emoji to count; count is chosen randomly per round.
class SpotCountRound {
  final String sceneKey;
  final String char;
  final String label;
  final List<String> deco;

  const SpotCountRound({
    required this.sceneKey,
    required this.char,
    required this.label,
    required this.deco,
  });
}

/// One round of a single-target detective game (letter / number / shape).
///
/// [target] is the emoji/character to find among [pool] distractors.
/// [n] is the number of targets placed in the scene.
class DetectiveRound {
  final String sceneKey;
  final String target;
  final List<String> pool;
  final int n;
  final String label;

  const DetectiveRound({
    required this.sceneKey,
    required this.target,
    required this.pool,
    required this.n,
    required this.label,
  });
}

/// One color group for the Color Quest game.
///
/// [label] is the display name (e.g. 'red'). [swatch] is the representative
/// color. [items] are emojis that belong to this color group.
class SpotColorGroup {
  final String label;
  final Color swatch;
  final List<String> items;

  const SpotColorGroup({
    required this.label,
    required this.swatch,
    required this.items,
  });
}

/// One round of the Color Quest game.
///
/// [target] is a key into [kColorGroups]. [n] is the number of target items
/// to pick from the group.
class ColorQuestRound {
  final String sceneKey;
  final String target;
  final int n;

  const ColorQuestRound({
    required this.sceneKey,
    required this.target,
    required this.n,
  });
}

// ---------------------------------------------------------------------------
// Round constants — ported from raw/spot-data.jsx.
// ---------------------------------------------------------------------------

/// Hidden Object Hunt missions: scene + multi-goal targets.
const List<HuntRound> kHuntRounds = [
  HuntRound(
    sceneKey: 'picnic',
    goals: [
      SpotGoal(char: '🐝', count: 3, label: 'bees'),
      SpotGoal(char: '🦋', count: 2, label: 'butterflies'),
      SpotGoal(char: '🍎', count: 4, label: 'apples'),
    ],
  ),
  HuntRound(
    sceneKey: 'playground',
    goals: [
      SpotGoal(char: '🎈', count: 3, label: 'balloons'),
      SpotGoal(char: '🐦', count: 2, label: 'birds'),
      SpotGoal(char: '⚽', count: 2, label: 'balls'),
    ],
  ),
  HuntRound(
    sceneKey: 'aquarium',
    goals: [
      SpotGoal(char: '🐡', count: 3, label: 'puffer fish'),
      SpotGoal(char: '🐙', count: 2, label: 'octopus'),
      SpotGoal(char: '🦀', count: 3, label: 'crabs'),
    ],
  ),
  HuntRound(
    sceneKey: 'beach',
    goals: [
      SpotGoal(char: '🐚', count: 4, label: 'shells'),
      SpotGoal(char: '🦀', count: 2, label: 'crabs'),
      SpotGoal(char: '🪼', count: 2, label: 'jellyfish'),
    ],
  ),
  HuntRound(
    sceneKey: 'space',
    goals: [
      SpotGoal(char: '⭐', count: 4, label: 'stars'),
      SpotGoal(char: '🛸', count: 2, label: 'UFOs'),
      SpotGoal(char: '👽', count: 2, label: 'aliens'),
    ],
  ),
  HuntRound(
    sceneKey: 'carnival',
    goals: [
      SpotGoal(char: '🎈', count: 4, label: 'balloons'),
      SpotGoal(char: '🍭', count: 3, label: 'lollipops'),
      SpotGoal(char: '🤡', count: 1, label: 'clown'),
    ],
  ),
];

/// Animal Tracker rounds — each round finds multiple animal types in a scene.
const List<HuntRound> kAnimalRounds = [
  HuntRound(
    sceneKey: 'safari',
    goals: [
      SpotGoal(char: '🦁', count: 2, label: 'lions'),
      SpotGoal(char: '🦒', count: 2, label: 'giraffes'),
      SpotGoal(char: '🐘', count: 2, label: 'elephants'),
      SpotGoal(char: '🐒', count: 3, label: 'monkeys'),
    ],
    extraDeco: ['🌴', '🌾', '🪨', '🌳'],
  ),
  HuntRound(
    sceneKey: 'aquarium',
    goals: [
      SpotGoal(char: '🐠', count: 3, label: 'fish'),
      SpotGoal(char: '🐙', count: 2, label: 'octopus'),
      SpotGoal(char: '🦀', count: 2, label: 'crabs'),
      SpotGoal(char: '🐬', count: 2, label: 'dolphins'),
    ],
    extraDeco: ['🫧', '🪸', '🌊', '🐚'],
  ),
  HuntRound(
    sceneKey: 'farm',
    goals: [
      SpotGoal(char: '🐄', count: 2, label: 'cows'),
      SpotGoal(char: '🐖', count: 2, label: 'pigs'),
      SpotGoal(char: '🐔', count: 3, label: 'chickens'),
      SpotGoal(char: '🐑', count: 2, label: 'sheep'),
    ],
    extraDeco: ['🌽', '🌾', '🌳', '🟫'],
  ),
];

/// Count It If You Can rounds — one emoji type to count per round.
const List<SpotCountRound> kSpotCountRounds = [
  SpotCountRound(
    sceneKey: 'playground',
    char: '🎈',
    label: 'balloons',
    deco: ['🛝', '🌳', '☁️', '🌷', '🐦', '⚽'],
  ),
  SpotCountRound(
    sceneKey: 'aquarium',
    char: '🐠',
    label: 'fish',
    deco: ['🫧', '🪸', '🌊', '🐚', '🌿'],
  ),
  SpotCountRound(
    sceneKey: 'farm',
    char: '🐔',
    label: 'chickens',
    deco: ['🌽', '🌾', '🌳', '🟫', '🚜'],
  ),
  SpotCountRound(
    sceneKey: 'picnic',
    char: '🐝',
    label: 'bees',
    deco: ['🌳', '🌷', '🍃', '🌼', '🧺'],
  ),
  SpotCountRound(
    sceneKey: 'space',
    char: '⭐',
    label: 'stars',
    deco: ['🪐', '🌙', '🛸', '🌟', '👽'],
  ),
];

/// Letter Detective rounds — find the target letter among confusable look-alikes.
const List<DetectiveRound> kLetterRounds = [
  DetectiveRound(
    sceneKey: 'museum',
    target: 'b',
    pool: ['d', 'p', 'q', 'h', 'a', 'o', 'e'],
    n: 5,
    label: 'little b',
  ),
  DetectiveRound(
    sceneKey: 'farm',
    target: 'm',
    pool: ['n', 'w', 'u', 'r', 'a', 'e', 's'],
    n: 5,
    label: 'little m',
  ),
  DetectiveRound(
    sceneKey: 'space',
    target: 'A',
    pool: ['V', 'W', 'H', 'N', 'M', 'E', 'T'],
    n: 4,
    label: 'big A',
  ),
  DetectiveRound(
    sceneKey: 'picnic',
    target: 'd',
    pool: ['b', 'p', 'q', 'a', 'o', 'g', 'c'],
    n: 5,
    label: 'little d',
  ),
];

/// Number Detective rounds — find all of the target digit.
const List<DetectiveRound> kNumberRounds = [
  DetectiveRound(
    sceneKey: 'safari',
    target: '7',
    pool: ['1', '4', '9', '2', '5', '0', '3'],
    n: 5,
    label: 'number 7',
  ),
  DetectiveRound(
    sceneKey: 'beach',
    target: '4',
    pool: ['7', '1', '9', '6', '8', '3', '2'],
    n: 5,
    label: 'number 4',
  ),
  DetectiveRound(
    sceneKey: 'carnival',
    target: '2',
    pool: ['5', '3', '7', '1', '8', '6', '9'],
    n: 4,
    label: 'number 2',
  ),
];

/// Shape Safari rounds — find all of one shape emoji among distractors.
const List<DetectiveRound> kShapeRounds = [
  DetectiveRound(
    sceneKey: 'playground',
    target: '🔺',
    pool: ['⭕', '⬜', '⭐', '🔵', '🟦'],
    n: 5,
    label: 'triangles',
  ),
  DetectiveRound(
    sceneKey: 'beach',
    target: '⭕',
    pool: ['🔺', '⬜', '⭐', '🟥', '🔻'],
    n: 5,
    label: 'circles',
  ),
  DetectiveRound(
    sceneKey: 'carnival',
    target: '⭐',
    pool: ['🔺', '⭕', '⬜', '🔵', '🟥'],
    n: 5,
    label: 'stars',
  ),
  DetectiveRound(
    sceneKey: 'space',
    target: '⬜',
    pool: ['🔺', '⭕', '⭐', '🔵', '🔻'],
    n: 4,
    label: 'squares',
  ),
];

/// Color groups for Color Quest — emoji items grouped by their color.
const Map<String, SpotColorGroup> kColorGroups = {
  'red': SpotColorGroup(
    label: 'red',
    swatch: Color(0xFFE84B4B),
    items: ['🍎', '🌹', '🍓', '🔴', '🚗', '🧣'],
  ),
  'blue': SpotColorGroup(
    label: 'blue',
    swatch: Color(0xFF3F86D6),
    items: ['🫐', '🔵', '💙', '🐳', '🧢', '👕'],
  ),
  'yellow': SpotColorGroup(
    label: 'yellow',
    swatch: Color(0xFFF2C233),
    items: ['🍌', '⭐', '🌻', '🟡', '🧀', '🐤'],
  ),
  'green': SpotColorGroup(
    label: 'green',
    swatch: Color(0xFF5FB94B),
    items: ['🍀', '🟢', '🥦', '🐸', '🌿', '🥝'],
  ),
};

/// Color Quest rounds — one color group per round.
const List<ColorQuestRound> kColorRounds = [
  ColorQuestRound(sceneKey: 'picnic',     target: 'red',    n: 5),
  ColorQuestRound(sceneKey: 'farm',       target: 'yellow', n: 5),
  ColorQuestRound(sceneKey: 'beach',      target: 'blue',   n: 4),
  ColorQuestRound(sceneKey: 'playground', target: 'green',  n: 5),
];
