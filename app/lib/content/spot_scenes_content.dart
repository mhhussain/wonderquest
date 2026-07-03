import 'package:flutter/material.dart';

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
