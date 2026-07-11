/// A reward unit that can be applied to SaveData.
///
/// Contains any combination of: stars, xp, egg, sticker, animal,
/// progress update, or silent flag.
class Reward {
  const Reward({
    this.stars = 0,
    this.xp = 0,
    this.egg = false,
    this.sticker,
    this.animal,
    this.progressKey,
    this.progressTo,
    this.silent = false,
  });

  /// Number of stars awarded
  final int stars;

  /// Experience points awarded
  final int xp;

  /// Whether to award an egg
  final bool egg;

  /// Sticker ID to add (if not already present)
  final String? sticker;

  /// Animal ID to add (if not already present)
  final String? animal;

  /// Progress key to update (one of: letter, arabic, number, math, animal, world, find)
  final String? progressKey;

  /// Progress value to update to (will be clamped 0-100 and kept monotonic)
  final int? progressTo;

  /// Whether to hide the reward modal (e.g., for inline celebrations)
  final bool silent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reward &&
          runtimeType == other.runtimeType &&
          stars == other.stars &&
          xp == other.xp &&
          egg == other.egg &&
          sticker == other.sticker &&
          animal == other.animal &&
          progressKey == other.progressKey &&
          progressTo == other.progressTo &&
          silent == other.silent;

  @override
  int get hashCode => Object.hash(
        stars,
        xp,
        egg,
        sticker,
        animal,
        progressKey,
        progressTo,
        silent,
      );
}
