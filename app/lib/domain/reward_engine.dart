import 'package:wonder_quest/core/persistence/save_data.dart';
import 'reward.dart';

/// Calculate XP required to advance from [level] to [level] + 1.
///
/// Formula: `xpForLevel(lvl) = 100 + (lvl - 1) * 60`
///
/// Examples:
/// - xpForLevel(1) = 100 (xp needed to go from level 1 to 2)
/// - xpForLevel(2) = 160 (xp needed to go from level 2 to 3)
int xpForLevel(int level) {
  return 100 + (level - 1) * 60;
}

/// Apply a reward to a SaveData state and return the updated state.
///
/// Rules (verbatim from wiki):
/// - Add [Reward.stars] to the state
/// - Add [Reward.xp] then apply level-up rollover: while xp >= xpForLevel(level),
///   subtract and increment level (supports multi-level-ups)
/// - [Reward.egg] true → increment eggs
/// - [Reward.sticker] appended only if not already present (deduplication)
/// - [Reward.animal] appended only if not already present (deduplication)
/// - [Reward.progressKey] with [Reward.progressTo] → progress[key] = max(current, progressTo).clamp(0, 100)
///   (progress never decreases, always clamped to valid range)
/// - [Reward.silent] flag is stored but doesn't affect state transformation
///
/// Returns a new SaveData with all changes applied.
SaveData applyReward(SaveData state, Reward reward) {
  // Start with current values
  var newStars = state.stars + reward.stars;
  var newXp = state.xp + reward.xp;
  var newLevel = state.level;

  // Apply level-up rollover: while xp >= xpForLevel(level), level up
  while (newXp >= xpForLevel(newLevel)) {
    newXp -= xpForLevel(newLevel);
    newLevel += 1;
  }

  // Handle egg
  var newEggs = state.eggs + (reward.egg ? 1 : 0);

  // Handle sticker (deduplicate)
  var newStickers = [...state.stickers];
  if (reward.sticker != null && !newStickers.contains(reward.sticker)) {
    newStickers.add(reward.sticker!);
  }

  // Handle animal (deduplicate)
  var newAnimalsFound = [...state.animalsFound];
  if (reward.animal != null && !newAnimalsFound.contains(reward.animal)) {
    newAnimalsFound.add(reward.animal!);
  }

  // Handle progress (monotonic, clamped) and count the completed game
  // session toward its land's play total.
  var newProgress = {...state.progress};
  var newLandPlays = state.landPlays;
  if (reward.progressKey != null && reward.progressTo != null) {
    final key = reward.progressKey!;
    final currentValue = newProgress[key] ?? 0;
    final newValue = reward.progressTo!.clamp(0, 100);
    // Keep monotonic: never decrease
    newProgress[key] = newValue > currentValue ? newValue : currentValue;
    newLandPlays = {...state.landPlays};
    newLandPlays[key] = (newLandPlays[key] ?? 0) + 1;
  }

  // Return updated state
  return state.copyWith(
    stars: newStars,
    xp: newXp,
    level: newLevel,
    eggs: newEggs,
    stickers: newStickers,
    animalsFound: newAnimalsFound,
    progress: newProgress,
    landPlays: newLandPlays,
  );
}
