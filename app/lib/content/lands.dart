import 'package:flutter/material.dart';

import '../features/lands/animal_planet/animal_planet_screen.dart';
import '../features/lands/around_the_world/around_the_world_screen.dart';
import '../features/lands/hoorof/hoorof_screen.dart';
import '../features/lands/letter_adventure/letter_adventure_screen.dart';
import '../features/lands/math_lab/math_lab_screen.dart';
import '../features/lands/number_kingdom/number_kingdom_screen.dart';
import '../features/lands/spot_me/spot_me_screen.dart';
import '../theme/wq_colors.dart';
import '../core/progress_keys.dart';

/// A single land entry in the 13-land Expedition Map registry.
///
/// All emoji are accessed via [Art] using [emojiKey] — never hardcoded in
/// widgets. Colors come from [WqColors].
@immutable
class Land {
  const Land({
    required this.id,
    required this.title,
    required this.sub,
    required this.emojiKey,
    required this.color,
    this.playable = false,
    this.builder,
    this.progressKey,
  });

  /// Unique land identifier (matches [SaveData.progress] key where applicable).
  final String id;

  /// Display title shown on the land card.
  final String title;

  /// Short tagline shown beneath the title on the card.
  final String sub;

  /// Semantic key forwarded to [Art.glyph] / [Art.emoji] for the land icon.
  final String emojiKey;

  /// Background color of the land card tile.
  final Color color;

  /// Whether this land is currently playable.
  ///
  /// `false` = locked / "Coming soon" — the card shows a 🔒 pill and
  /// tapping it is a no-op.
  final bool playable;

  /// Route builder for the land's home screen.
  ///
  /// `null` for locked lands, and for playable lands whose dedicated task
  /// (Tasks 27–33) has not yet shipped — the [ExpeditionMapScreen] falls
  /// back to [_placeholderBuilder] in that case.
  final WidgetBuilder? builder;

  /// Key into [SaveData.progress] for this land's progress bar.
  ///
  /// `null` for locked lands (no progress bar is shown).
  final String? progressKey;
}

/// Descriptor for one hatchable dinosaur in the Dino Eggs collection.
@immutable
class DinoDef {
  const DinoDef({required this.name, required this.emojiKey});

  /// Display name shown after hatching (e.g. `'Rexy Jr'`).
  final String name;

  /// Semantic key forwarded to [Art.glyph] for the dino emoji.
  final String emojiKey;
}

/// The ordered roster of hatchable dinosaurs (6 total).
///
/// The player earns eggs by playing activities; tapping "Hatch!" in the
/// Dino Eggs collection picks a random unhatched entry and calls
/// [SaveController.hatchEgg].
const kDinos = <DinoDef>[
  DinoDef(name: 'Bronto',  emojiKey: 'dino-bronto'),
  DinoDef(name: 'Rexy Jr', emojiKey: 'dino-rexy-jr'),
  DinoDef(name: 'Stego',   emojiKey: 'dino-stego'),
  DinoDef(name: 'Tricera', emojiKey: 'dino-tricera'),
  DinoDef(name: 'Ptera',   emojiKey: 'dino-ptera'),
  DinoDef(name: 'Raptor',  emojiKey: 'dino-raptor'),
];

/// The 13-land registry (7 playable + 6 locked) in display order.
///
/// Land order: Letter Adventure → Hoorof → Number Kingdom → Little Math Lab
/// → Animal Planet → Around the World → Spot Me If You Can (playable, Tasks
/// 27–33), then Dino Discovery → Earth Explorer → Maze World → Tracing Studio
/// → Pattern Detective → Reading Readiness (locked).
///
/// Builders for all 7 playable lands are filled in Tasks 27–33.  Until then
/// [ExpeditionMapScreen] falls back to a placeholder "Coming in a later task"
/// screen.
final List<Land> kLands = [
  Land(
    id: 'letter',
    title: 'Letter Adventure',
    sub: 'Aa Bb Cc',
    emojiKey: 'land-letter',
    color: WqColors.orange,
    playable: true,
    progressKey: ProgressKeys.letter,
    builder: (_) => const LetterAdventureScreen(),
  ),
  Land(
    id: 'hoorof',
    title: 'Hoorof',
    sub: 'Arabic letters',
    emojiKey: 'land-hoorof',
    color: WqColors.teal,
    playable: true,
    progressKey: ProgressKeys.arabic,
    builder: (_) => const HoroofScreen(),
  ),
  Land(
    id: 'number',
    title: 'Number Kingdom',
    sub: '1 2 3 counting',
    emojiKey: 'land-number',
    color: WqColors.teal,
    playable: true,
    progressKey: ProgressKeys.number,
    builder: (_) => const NumberKingdomScreen(),
  ),
  Land(
    id: 'math',
    title: 'Little Math Lab',
    sub: 'Add & take away',
    emojiKey: 'land-math',
    color: WqColors.green,
    playable: true,
    progressKey: ProgressKeys.math,
    builder: (_) => const MathLabScreen(),
  ),
  Land(
    id: 'animal',
    title: 'Animal Planet',
    sub: 'Habitats & facts',
    emojiKey: 'land-animal',
    color: WqColors.grape,
    playable: true,
    progressKey: ProgressKeys.animal,
    builder: (_) => const AnimalPlanetScreen(),
  ),
  Land(
    id: 'world',
    title: 'Around the World',
    sub: 'Continents',
    emojiKey: 'land-world',
    color: WqColors.sky,
    playable: true,
    progressKey: ProgressKeys.world,
    builder: (_) => const AroundTheWorldScreen(),
  ),
  Land(
    id: 'find',
    title: 'Spot Me If You Can',
    sub: 'Hidden objects',
    emojiKey: 'land-find',
    color: WqColors.yellow,
    playable: true,
    progressKey: ProgressKeys.find,
    builder: (_) => const SpotMeScreen(),
  ),
  // ── Locked lands ──────────────────────────────────────────────────────────
  const Land(
    id: 'dino',
    title: 'Dino Discovery',
    sub: 'Dig & collect',
    emojiKey: 'land-dino',
    color: WqColors.coral,
  ),
  const Land(
    id: 'earth',
    title: 'Earth Explorer',
    sub: 'Weather & seasons',
    emojiKey: 'land-earth',
    color: WqColors.teal,
  ),
  const Land(
    id: 'maze',
    title: 'Maze World',
    sub: 'Find the way',
    emojiKey: 'land-maze',
    color: WqColors.pink,
  ),
  const Land(
    id: 'trace',
    title: 'Tracing Studio',
    sub: 'Draw along',
    emojiKey: 'land-trace',
    color: WqColors.orange,
  ),
  const Land(
    id: 'pattern',
    title: 'Pattern Detective',
    sub: 'What comes next?',
    emojiKey: 'land-pattern',
    color: WqColors.grape,
  ),
  const Land(
    id: 'reading',
    title: 'Reading Readiness',
    sub: 'Rhymes & sounds',
    emojiKey: 'land-reading',
    color: WqColors.coral,
  ),
];
