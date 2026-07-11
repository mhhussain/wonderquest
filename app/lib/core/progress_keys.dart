/// Canonical keys for the seven `SaveData.progress` entries.
///
/// Always reference progress through these constants (never raw strings) so
/// a typo can't silently create a new progress bucket.
abstract final class ProgressKeys {
  static const letter = 'letter';
  static const arabic = 'arabic';
  static const number = 'number';
  static const math = 'math';
  static const animal = 'animal';
  static const world = 'world';
  static const find = 'find';

  /// All seven keys, in canonical display order.
  static const all = [letter, arabic, number, math, animal, world, find];
}
