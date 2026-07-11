import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/progress_keys.dart';

/// Overall GSRP readiness: mean of all 7 progress keys, 0–100.
int readinessPercent(Map<String, int> progress) {
  final sum =
      ProgressKeys.all.fold<int>(0, (a, k) => a + (progress[k] ?? 0));
  return (sum / ProgressKeys.all.length).round().clamp(0, 100);
}

/// One badge definition: streaks, star milestones, per-module mastery,
/// level, and GSRP Ready (rewards-gamification spec).
///
/// Badges are **derived** from [SaveData] — [earned] is a pure predicate —
/// so they need no persistence, never desync from the stats they summarise,
/// and re-earn automatically after a progress reset.
class BadgeSpec {
  const BadgeSpec({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.earned,
  });

  final String id;
  final String title;

  /// [Art] key or emoji passthrough.
  final String icon;

  final String description;
  final bool Function(SaveData) earned;
}

/// Mastery threshold (progress percent) for the per-module badges.
const kMasteryBadgePct = 80;

/// All badge definitions, in Treasure Chest display order.
final List<BadgeSpec> kAllBadges = [
  // Streaks
  BadgeSpec(
    id: 'streak-3',
    title: 'On a Roll',
    icon: 'streak',
    description: 'Play 3 days in a row',
    earned: (s) => s.streak >= 3,
  ),
  BadgeSpec(
    id: 'streak-7',
    title: 'Week Explorer',
    icon: 'streak',
    description: 'Play 7 days in a row',
    earned: (s) => s.streak >= 7,
  ),
  // Star milestones
  BadgeSpec(
    id: 'stars-25',
    title: 'Star Catcher',
    icon: 'star',
    description: 'Collect 25 stars',
    earned: (s) => s.stars >= 25,
  ),
  BadgeSpec(
    id: 'stars-100',
    title: 'Star Champion',
    icon: 'star',
    description: 'Collect 100 stars',
    earned: (s) => s.stars >= 100,
  ),
  // Level milestones
  BadgeSpec(
    id: 'level-5',
    title: 'Level 5 Hero',
    icon: 'rexy',
    description: 'Reach level 5',
    earned: (s) => s.level >= 5,
  ),
  BadgeSpec(
    id: 'level-10',
    title: 'Level 10 Legend',
    icon: 'rexy',
    description: 'Reach level 10',
    earned: (s) => s.level >= 10,
  ),
  // Per-module mastery
  for (final (key, title, icon) in [
    (ProgressKeys.letter, 'Letter Master', 'land-letter'),
    (ProgressKeys.arabic, 'Hoorof Master', 'land-hoorof'),
    (ProgressKeys.number, 'Number Master', 'land-number'),
    (ProgressKeys.math, 'Math Master', 'land-math'),
    (ProgressKeys.animal, 'Animal Master', 'land-animal'),
    (ProgressKeys.world, 'World Master', 'land-world'),
    (ProgressKeys.find, 'Finding Master', 'land-find'),
  ])
    BadgeSpec(
      id: 'mastery-$key',
      title: title,
      icon: icon,
      description: 'Reach $kMasteryBadgePct% in this module',
      earned: (s) => (s.progress[key] ?? 0) >= kMasteryBadgePct,
    ),
  // GSRP Ready
  BadgeSpec(
    id: 'gsrp-ready',
    title: 'GSRP Ready',
    icon: 'trophy',
    description: 'Reach 80% overall readiness',
    earned: (s) => readinessPercent(s.progress) >= 80,
  ),
];

/// IDs of the badges [s] has earned.
Set<String> earnedBadgeIds(SaveData s) =>
    {for (final b in kAllBadges) if (b.earned(s)) b.id};
