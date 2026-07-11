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

/// Key builders for `SaveData.skillStats` entries (per-skill mastery
/// aggregates shown on the parent dashboard).
abstract final class SkillKeys {
  static String letter(String glyph) => 'letter:$glyph';
  static String arabic(String glyph) => 'arabic:$glyph';
  static String number(Object n) => 'number:$n';
  static String math(String concept) => 'math:$concept';
  static String trace(String glyph) => 'trace:$glyph';

  /// Prefix shared by all tracing-accuracy stats.
  static const tracePrefix = 'trace:';
}
