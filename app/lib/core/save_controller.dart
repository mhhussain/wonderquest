import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wonder_quest/core/daily_rollover.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/domain/reward.dart';
import 'package:wonder_quest/domain/reward_engine.dart';

/// Provides the [SaveFileStore]. Must be overridden in main.dart with the
/// real documents directory, or overridden in tests with a temp-dir store.
final saveStoreProvider = Provider<SaveFileStore>(
  (ref) => throw UnimplementedError(
    'saveStoreProvider must be overridden (e.g. in ProviderScope or tests)',
  ),
);

/// The single write path to the save file. All mutations go through here.
final saveControllerProvider =
    AsyncNotifierProvider<SaveController, SaveData>(SaveController.new);

/// Riverpod [AsyncNotifier] that is the sole owner of the save file.
///
/// Invariant: every public mutator follows the pattern
///   compute new state → state = AsyncData(next) → store.save(next)
/// Nothing outside this class may call [SaveFileStore.save].
class SaveController extends AsyncNotifier<SaveData> {
  SaveFileStore get _store => ref.read(saveStoreProvider);

  /// Serialises concurrent [_store.save] calls so they never race on the
  /// shared `.tmp` file used by [SaveFileStore].  Seeded with an
  /// already-completed [Future].
  Future<void> _pendingSave = Future.value();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<SaveData> build() async {
    final raw = await _store.load();
    return applyDailyRollover(raw, DateTime.now());
  }

  // ── Internal helper ────────────────────────────────────────────────────────

  /// Reads the current value, applies [updater], updates state, and persists.
  ///
  /// Uses `await future` only to block until build completes, then reads
  /// `state.requireValue` synchronously so that two concurrent callers each
  /// see the latest committed state rather than the same stale snapshot.
  ///
  /// Saves are chained through [_pendingSave] so that concurrent mutators
  /// never overlap on the `.tmp` file used by [SaveFileStore].
  Future<void> _update(SaveData Function(SaveData) updater) async {
    await future; // wait for build; do NOT capture the value
    final current = state.requireValue; // synchronous read of current state
    final next = updater(current);
    state = AsyncData(next);
    // Chain save after any in-flight save to prevent concurrent .tmp conflicts.
    final myFuture = _pendingSave.then<void>((_) => _store.save(next));
    // Swallow errors on the chain so a failed save never stalls later ones.
    _pendingSave = myFuture.catchError((dynamic _) {});
    await myFuture;
  }

  // ── Public mutators ────────────────────────────────────────────────────────

  /// Apply a [Reward] (via [applyReward]) and persist.
  Future<void> apply(Reward r) async {
    await _update((s) => applyReward(s, r));
  }

  /// Toggle sound on/off and persist.
  Future<void> toggleSound() async {
    await _update((s) => s.copyWith(soundOn: !s.soundOn));
  }

  /// Record completion of level [index] for game type [typeId].
  ///
  /// Ensures levels[typeId] has [totalGames] entries (false by default), then
  /// marks [index] as true.
  Future<void> markLevelDone(
    String typeId,
    int index,
    int totalGames,
  ) async {
    await _update((s) {
      final existing =
          s.levels[typeId] ?? List<bool>.filled(totalGames, false);
      final list = List<bool>.from(existing);
      // Grow the list if needed (e.g. new levels added after initial data)
      while (list.length < totalGames) {
        list.add(false);
      }
      // Guard: bad index is a silent no-op to avoid RangeError
      if (index < 0 || index >= list.length) return s;
      list[index] = true;
      final newLevels = Map<String, List<bool>>.from(s.levels);
      newLevels[typeId] = list;
      return s.copyWith(levels: newLevels);
    });
  }

  /// Move [letter] from lettersLearning → lettersMastered (deduped) and persist.
  Future<void> setLetterMastered(String letter) async {
    await _update((s) {
      final mastered = List<String>.from(s.lettersMastered);
      if (!mastered.contains(letter)) mastered.add(letter);
      final learning = List<String>.from(s.lettersLearning)..remove(letter);
      return s.copyWith(
        lettersMastered: mastered,
        lettersLearning: learning,
      );
    });
  }

  /// Add [letter] to lettersLearning (deduped) and persist.
  Future<void> setLetterLearning(String letter) async {
    await _update((s) {
      final learning = List<String>.from(s.lettersLearning);
      if (!learning.contains(letter)) learning.add(letter);
      return s.copyWith(lettersLearning: learning);
    });
  }

  /// Add [n] to numbersMastered (deduped) and persist.
  Future<void> setNumberMastered(String n) async {
    await _update((s) {
      final mastered = List<String>.from(s.numbersMastered);
      if (!mastered.contains(n)) mastered.add(n);
      return s.copyWith(numbersMastered: mastered);
    });
  }

  /// Hatch an egg: decrements eggs by 1 and appends [dinoName] to hatched.
  ///
  /// No-op if eggs == 0.
  Future<void> hatchEgg(String dinoName) async {
    await _update((s) {
      if (s.eggs <= 0) return s;
      return s.copyWith(
        eggs: s.eggs - 1,
        hatched: [...s.hatched, dinoName],
      );
    });
  }

  /// Mark continent [id] as visited in world state and persist.
  Future<void> visitContinent(String id) async {
    await _update((s) {
      final visited = Map<String, bool>.from(s.world.visited)..[id] = true;
      return s.copyWith(
        world: WorldState(
          visited: visited,
          points: s.world.points,
          discovery: s.world.discovery,
          cards: s.world.cards,
        ),
      );
    });
  }

  /// Mark discovery card [cardId] as collected and persist.
  Future<void> collectDiscoveryCard(String cardId) async {
    await _update((s) {
      final discovery =
          Map<String, bool>.from(s.world.discovery)..[cardId] = true;
      return s.copyWith(
        world: WorldState(
          visited: s.world.visited,
          points: s.world.points,
          discovery: discovery,
          cards: s.world.cards,
        ),
      );
    });
  }

  /// Add continent [continentId] to the wonder-card collection (deduped).
  ///
  /// Called at find-mission completion alongside [visitContinent].
  Future<void> collectWonderCard(String continentId) async {
    await _update((s) {
      final cards = List<String>.from(s.world.cards);
      if (!cards.contains(continentId)) cards.add(continentId);
      return s.copyWith(
        world: WorldState(
          visited: s.world.visited,
          points: s.world.points,
          discovery: s.world.discovery,
          cards: cards,
        ),
      );
    });
  }

  /// Add one play-minute (via [addPlayMinute]) and persist.
  Future<void> addMinute() async {
    await _update((s) => addPlayMinute(s, DateTime.now()));
  }

  /// Reset all progress while keeping the same [profileId].
  ///
  /// Caller (parent gate) is responsible for any confirmation UX.
  Future<void> resetAllProgress() async {
    await _update((s) => SaveData.initial(profileId: s.profileId));
  }
}
