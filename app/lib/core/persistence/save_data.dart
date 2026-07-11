import '../progress_keys.dart';
import 'package:flutter/foundation.dart';

/// Represents the world state in a save file.
@immutable
class WorldState {
  const WorldState({
    required this.visited,
    required this.points,
    required this.discovery,
    required this.cards,
  });

  /// Map of visited locations (locationId -> visited)
  final Map<String, bool> visited;

  /// Points earned in the world
  final int points;

  /// Map of discovered cards (cardId -> discovered)
  final Map<String, bool> discovery;

  /// Continent IDs whose wonder card has been collected (one per continent).
  final List<String> cards;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldState &&
          runtimeType == other.runtimeType &&
          mapEquals(visited, other.visited) &&
          points == other.points &&
          mapEquals(discovery, other.discovery) &&
          listEquals(cards, other.cards);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(visited.entries.map((e) => Object.hash(e.key, e.value))),
        points,
        Object.hashAll(discovery.entries.map((e) => Object.hash(e.key, e.value))),
        Object.hashAll(cards),
      );

  Map<String, dynamic> toJson() => {
        'visited': visited,
        'points': points,
        'discovery': discovery,
        'cards': cards,
      };

  static WorldState fromJson(Map<String, dynamic> json) {
    return WorldState(
      visited: Map<String, bool>.from(json['visited'] as Map? ?? {}),
      points: (json['points'] as int?) ?? 0,
      discovery: Map<String, bool>.from(json['discovery'] as Map? ?? {}),
      cards: (json['cards'] as List<dynamic>?)?.cast<String>().toList() ?? [],
    );
  }
}

/// Represents a player's save data file.
@immutable
class SaveData {
  const SaveData({
    required this.schemaVersion,
    required this.profileId,
    required this.name,
    required this.xp,
    required this.level,
    required this.stars,
    required this.eggs,
    required this.streak,
    required this.soundOn,
    required this.hatched,
    required this.stickers,
    required this.animalsFound,
    required this.lettersMastered,
    required this.lettersLearning,
    required this.numbersMastered,
    required this.progress,
    required this.minutesToday,
    required this.lastPlayedDate,
    required this.week,
    required this.levels,
    required this.world,
  });

  /// Schema version for migrations (always 1 for now)
  final int schemaVersion;

  /// UUID of the profile
  final String profileId;

  /// Player's name
  final String name;

  /// Experience points
  final int xp;

  /// Current level
  final int level;

  /// Star count
  final int stars;

  /// Egg count
  final int eggs;

  /// Daily streak
  final int streak;

  /// Sound enabled
  final bool soundOn;

  /// List of hatched dino IDs
  final List<String> hatched;

  /// List of collected sticker IDs
  final List<String> stickers;

  /// List of discovered animal IDs
  final List<String> animalsFound;

  /// List of mastered letter IDs
  final List<String> lettersMastered;

  /// List of learning letter IDs
  final List<String> lettersLearning;

  /// List of mastered number IDs
  final List<String> numbersMastered;

  /// Progress per skill (letter, arabic, number, math, animal, world, find) 0-100
  final Map<String, int> progress;

  /// Minutes played today
  final int minutesToday;

  /// Last played date (ISO string or empty)
  final String lastPlayedDate;

  /// Weekly playtime (7 days)
  final List<int> week;

  /// Per-game-type completion (typeId -> [bool list])
  final Map<String, List<bool>> levels;

  /// Around-the-world state
  final WorldState world;

  /// Create an initial save with defaults for a new profile.
  factory SaveData.initial({required String profileId}) {
    return SaveData(
      schemaVersion: 1,
      profileId: profileId,
      name: 'Hassan',
      xp: 0,
      level: 1,
      stars: 0,
      eggs: 0,
      streak: 0,
      soundOn: true,
      hatched: [],
      stickers: [],
      animalsFound: [],
      lettersMastered: [],
      lettersLearning: [],
      numbersMastered: [],
      progress: {
        ProgressKeys.letter: 0,
        ProgressKeys.arabic: 0,
        ProgressKeys.number: 0,
        ProgressKeys.math: 0,
        ProgressKeys.animal: 0,
        ProgressKeys.world: 0,
        ProgressKeys.find: 0,
      },
      minutesToday: 0,
      lastPlayedDate: '',
      week: [0, 0, 0, 0, 0, 0, 0],
      levels: {},
      world: const WorldState(
        visited: {},
        points: 0,
        discovery: {},
        cards: [],
      ),
    );
  }

  /// Create a copy with optionally updated fields.
  SaveData copyWith({
    int? schemaVersion,
    String? profileId,
    String? name,
    int? xp,
    int? level,
    int? stars,
    int? eggs,
    int? streak,
    bool? soundOn,
    List<String>? hatched,
    List<String>? stickers,
    List<String>? animalsFound,
    List<String>? lettersMastered,
    List<String>? lettersLearning,
    List<String>? numbersMastered,
    Map<String, int>? progress,
    int? minutesToday,
    String? lastPlayedDate,
    List<int>? week,
    Map<String, List<bool>>? levels,
    WorldState? world,
  }) {
    return SaveData(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      stars: stars ?? this.stars,
      eggs: eggs ?? this.eggs,
      streak: streak ?? this.streak,
      soundOn: soundOn ?? this.soundOn,
      hatched: hatched ?? this.hatched,
      stickers: stickers ?? this.stickers,
      animalsFound: animalsFound ?? this.animalsFound,
      lettersMastered: lettersMastered ?? this.lettersMastered,
      lettersLearning: lettersLearning ?? this.lettersLearning,
      numbersMastered: numbersMastered ?? this.numbersMastered,
      progress: progress ?? this.progress,
      minutesToday: minutesToday ?? this.minutesToday,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      week: week ?? this.week,
      levels: levels ?? this.levels,
      world: world ?? this.world,
    );
  }

  /// Convert to JSON for storage.
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'profileId': profileId,
        'name': name,
        'xp': xp,
        'level': level,
        'stars': stars,
        'eggs': eggs,
        'streak': streak,
        'soundOn': soundOn,
        'hatched': hatched,
        'stickers': stickers,
        'animalsFound': animalsFound,
        'lettersMastered': lettersMastered,
        'lettersLearning': lettersLearning,
        'numbersMastered': numbersMastered,
        'progress': progress,
        'minutesToday': minutesToday,
        'lastPlayedDate': lastPlayedDate,
        'week': week,
        'levels': levels,
        'world': world.toJson(),
      };

  /// Create from JSON, filling missing keys with defaults.
  factory SaveData.fromJson(Map<String, dynamic> json) {
    // Build progress with defaults for missing keys
    final progressJson = json['progress'] as Map<String, dynamic>? ?? {};
    final progress = {
      ProgressKeys.letter: (progressJson[ProgressKeys.letter] as int?) ?? 0,
      ProgressKeys.arabic: (progressJson[ProgressKeys.arabic] as int?) ?? 0,
      ProgressKeys.number: (progressJson[ProgressKeys.number] as int?) ?? 0,
      ProgressKeys.math: (progressJson[ProgressKeys.math] as int?) ?? 0,
      ProgressKeys.animal: (progressJson[ProgressKeys.animal] as int?) ?? 0,
      ProgressKeys.world: (progressJson[ProgressKeys.world] as int?) ?? 0,
      ProgressKeys.find: (progressJson[ProgressKeys.find] as int?) ?? 0,
    };

    // Build week with defaults
    final weekJson = json['week'] as List<dynamic>? ?? [];
    final week = weekJson.cast<int>().toList();
    while (week.length < 7) {
      week.add(0);
    }
    week.length = 7;

    // Build levels with defaults
    final levelsJson = json['levels'] as Map<String, dynamic>? ?? {};
    final levels = <String, List<bool>>{};
    levelsJson.forEach((key, value) {
      if (value is List<dynamic>) {
        levels[key] = value.cast<bool>().toList();
      }
    });

    // Build world state
    final worldJson = json['world'] as Map<String, dynamic>? ?? {};
    final world = WorldState.fromJson(worldJson);

    return SaveData(
      schemaVersion: (json['schemaVersion'] as int?) ?? 1,
      profileId: (json['profileId'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Hassan',
      xp: (json['xp'] as int?) ?? 0,
      level: (json['level'] as int?) ?? 1,
      stars: (json['stars'] as int?) ?? 0,
      eggs: (json['eggs'] as int?) ?? 0,
      streak: (json['streak'] as int?) ?? 0,
      soundOn: (json['soundOn'] as bool?) ?? true,
      hatched: (json['hatched'] as List<dynamic>?)?.cast<String>().toList() ?? [],
      stickers: (json['stickers'] as List<dynamic>?)?.cast<String>().toList() ?? [],
      animalsFound: (json['animalsFound'] as List<dynamic>?)?.cast<String>().toList() ?? [],
      lettersMastered: (json['lettersMastered'] as List<dynamic>?)?.cast<String>().toList() ?? [],
      lettersLearning: (json['lettersLearning'] as List<dynamic>?)?.cast<String>().toList() ?? [],
      numbersMastered: (json['numbersMastered'] as List<dynamic>?)?.cast<String>().toList() ?? [],
      progress: progress,
      minutesToday: (json['minutesToday'] as int?) ?? 0,
      lastPlayedDate: (json['lastPlayedDate'] as String?) ?? '',
      week: week,
      levels: levels,
      world: world,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveData &&
          runtimeType == other.runtimeType &&
          schemaVersion == other.schemaVersion &&
          profileId == other.profileId &&
          name == other.name &&
          xp == other.xp &&
          level == other.level &&
          stars == other.stars &&
          eggs == other.eggs &&
          streak == other.streak &&
          soundOn == other.soundOn &&
          listEquals(hatched, other.hatched) &&
          listEquals(stickers, other.stickers) &&
          listEquals(animalsFound, other.animalsFound) &&
          listEquals(lettersMastered, other.lettersMastered) &&
          listEquals(lettersLearning, other.lettersLearning) &&
          listEquals(numbersMastered, other.numbersMastered) &&
          mapEquals(progress, other.progress) &&
          minutesToday == other.minutesToday &&
          lastPlayedDate == other.lastPlayedDate &&
          listEquals(week, other.week) &&
          _levelsMapEquals(levels, other.levels) &&
          world == other.world;

  @override
  int get hashCode => Object.hashAll([
        schemaVersion,
        profileId,
        name,
        xp,
        level,
        stars,
        eggs,
        streak,
        soundOn,
        Object.hashAll(hatched),
        Object.hashAll(stickers),
        Object.hashAll(animalsFound),
        Object.hashAll(lettersMastered),
        Object.hashAll(lettersLearning),
        Object.hashAll(numbersMastered),
        Object.hashAll(progress.entries.map((e) => Object.hash(e.key, e.value))),
        minutesToday,
        lastPlayedDate,
        Object.hashAll(week),
        Object.hashAll(levels.entries.map((e) => Object.hash(e.key, Object.hashAll(e.value)))),
        world,
      ]);

  /// Helper to compare nested maps of lists.
  static bool _levelsMapEquals(
      Map<String, List<bool>> a, Map<String, List<bool>> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !listEquals(a[key], b[key])) {
        return false;
      }
    }
    return true;
  }
}
