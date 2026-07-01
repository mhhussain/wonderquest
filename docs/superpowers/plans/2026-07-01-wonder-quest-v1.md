# Wonder Quest v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the validated HTML prototype as **Wonder Quest**, a fully-offline Flutter iPad app for a 5-year-old: 7 playable learning lands, a reward economy, and a parent dashboard.

**Architecture:** A fixed 1194×834 design canvas scaled to fit any tablet (landscape only). Pure-Dart domain layer (save model, reward engine, level dealer, engine logic) built TDD-first, wrapped by Riverpod for cross-cutting state, with plain Flutter widgets (no Flame) for the 7 lands. All content is data-driven from Dart constant pools ported from the prototype.

**Tech Stack:** Flutter (stable ≥3.22, Dart 3), flutter_riverpod, flutter_tts, audioplayers, path_provider, bundled fonts (Baloo 2, Nunito, Noto Naskh Arabic).

## Global Constraints

Every task's requirements implicitly include this section.

- **All code lives in `app/`** at the repo root. Run every `flutter` command from `app/`.
- **Fully offline.** No network calls, no Firebase, no google_fonts runtime fetch, no accounts. Everything (fonts, sounds, data) ships in the app bundle.
- **Landscape tablet only.** Design canvas is exactly **1194×834 logical px**, scaled with letterbox (letterbox color `#3A2E2A`).
- **Single child profile**, but every save is keyed under a `profileId` (UUID string) for future multi-profile support.
- **Persistence:** ONE versioned JSON save file (`wonderquest_save.json`) in the app documents directory. Atomic writes (write `.tmp`, then rename). `schemaVersion: 1`. No database, no shared_preferences for game data.
- **No Flame.** Plain widgets + CustomPaint. `setState` inside a mini-game is fine; anything cross-cutting (save data, rewards, settings, audio) goes through Riverpod.
- **All art through `Art` (asset-lookup layer)** — land widgets must never hardcode emoji directly. v1 art is emoji + Flutter shapes.
- **All speech through `TtsService`** — features never instantiate `FlutterTts` directly. Respect the global sound toggle.
- **Rewards only via `SaveController.apply(Reward)`** — never mutate xp/stars/etc. directly in a land.
- **XP formula (verbatim):** `xpForLevel(lvl) = 100 + (lvl - 1) * 60` (XP needed to advance from `lvl` to `lvl+1`; awards roll over; multi-level-ups possible).
- **Progress keys:** `letter, arabic, number, math, animal, world, find` — each 0–100. (`arabic` is separate from `letter` — a grill-session decision.)
- **Colors (verbatim hex):** orange `#FF8A3D`, teal `#2BB3C6`, green `#7BC043`, coral `#FF6B6B`, grape `#8B7BE0`, sky `#4AA8E0`, yellow `#FFC53D`, pink `#F472A8`; background `#FFF8EE` / alt `#FFEFD9`, card `#FFFFFF`, ink `#3A2E2A`, softInk `#6E5D55`, lines `#F0E2CF`.
- **Hit targets ≥64px** for child-facing controls (system minimum is 44; we build for a 5-year-old).
- **Every task ends with:** `flutter analyze` → 0 issues, `flutter test` → all green, then a git commit (`feat:`/`test:`/`chore:` prefix). Never commit with failing tests.
- **No ads, no external links, no in-app purchases, no analytics SDKs.** Local summary stats only — no event log.
- **UI language is English** everywhere (including Hoorof chrome); only Arabic glyphs/words render in Arabic script. Layout is LTR everywhere.

## Source-of-Truth Reading List

The wiki (`wiki/`) documents validated behavior; the raw prototype (`raw/*.jsx`) has the exact data pools and logic. **Each task below names the files its implementer must read first.** Key map:

| Area | Wiki page | Raw prototype |
|---|---|---|
| Rewards/economy | `wiki/systems/rewards-gamification.md` | `raw/shared.jsx` |
| Engines | `wiki/systems/game-engines.md` | `raw/levels.jsx`, `raw/spot-engine.jsx`, `raw/spot-engine2.jsx` |
| Design system | `wiki/systems/design-system.md` | `raw/app.css` |
| Audio/TTS | `wiki/systems/audio-speech.md` | `raw/shared.jsx`, `raw/sea.jsx` |
| Save model | `wiki/systems/state-persistence.md` | `raw/shared.jsx` |
| Scaling | `wiki/systems/scaling-device-frame.md` | `raw/app.css` |
| Letter Adventure | `wiki/modules/letter-adventure.md` | `raw/letter2.jsx`, `raw/letter3.jsx`, `raw/trace.jsx`, `raw/data.jsx` |
| Hoorof | `wiki/modules/hoorof.md` | `raw/hoorof.jsx`, `raw/hoorof-data.jsx`, `raw/hoorof.css` |
| Number Kingdom | `wiki/modules/number-kingdom.md` | `raw/number.jsx`, `raw/data.jsx` |
| Math Lab | `wiki/modules/math-lab.md` | `raw/math.jsx` |
| Animal Planet | `wiki/modules/animal-planet.md` | `raw/animal.jsx`, `raw/sea.jsx`, `raw/data.jsx` |
| Around the World | `wiki/modules/around-the-world.md` | `raw/world.jsx`, `raw/world2.jsx`, `raw/cards.jsx`, `raw/cards-data.jsx`, `raw/world.css` |
| Spot Me | `wiki/modules/spot-me.md` | `raw/spot.jsx`, `raw/spot-data.jsx`, `raw/spot.css` |
| Home/HUD/menu | `wiki/overview.md` | `raw/menu.jsx`, `raw/app.jsx` |
| Parent dashboard | `wiki/specs/` (dashboard spec) | `raw/parent.jsx` |
| Decisions | `wiki/requirements/decisions-2026-07-01.md` | — |

## Architecture & File Map

```
app/
  pubspec.yaml
  analysis_options.yaml
  assets/fonts/            Baloo2, Nunito, NotoNaskhArabic TTFs
  assets/sfx/              generated WAVs (Task 12)
  tool/gen_sfx.dart        WAV synthesizer script
  lib/
    main.dart              orientation lock, ProviderScope, runApp
    app.dart               MaterialApp, theme, home = ExpeditionMapScreen
    theme/wq_colors.dart   all palette constants
    theme/wq_theme.dart    ThemeData, text styles (Baloo2 headings, Nunito body)
    core/art.dart          Art asset-lookup layer (emoji now, images later)
    core/audio/tts_service.dart
    core/audio/sfx_service.dart
    core/persistence/save_data.dart    schema v1 model + json + migrations
    core/persistence/save_file.dart    atomic SaveFileStore
    core/save_controller.dart          Riverpod Notifier (single write path)
    core/daily_rollover.dart           streak/minutes/week logic
    domain/reward.dart                 Reward value type
    domain/reward_engine.dart          xpForLevel, applyReward
    domain/level_dealer.dart           dealGames
    domain/spot_scene_engine.dart      jittered-grid placement + goal tracking
    domain/trace_scorer.dart           glyph-coverage scoring
    domain/drift_field.dart            drifting-items tick engine
    content/lands.dart                 13-land registry
    content/english_letters.dart       26 letters + confusables + 75 word families
    content/arabic_letters.dart        28 letters + confusable families
    content/numbers_content.dart       count/missing-number generators
    content/math_content.dart          6 stations + object pools
    content/animals_content.dart       animals, habitats, ocean facts, 6 whales
    content/world_content.dart         7 continents, 21 discovery cards, wonders
    content/spot_scenes_content.dart   scenes, goals, sock levels
    widgets/canvas_scaler.dart         1194×834 FittedBox shell
    widgets/hud.dart
    widgets/reward_modal.dart          + confetti painter
    widgets/wq_button.dart             pill button w/ pressed offset
    widgets/level_select.dart          Game-N grid + GameDeck wrapper
    widgets/spot_scene.dart            SpotScene widget (uses engine)
    widgets/trace_canvas.dart          CustomPaint tracing (uses scorer)
    widgets/flip_card.dart
    widgets/drift_field_widget.dart
    features/map/expedition_map_screen.dart
    features/parent/parent_gate.dart
    features/parent/dashboard_screen.dart
    features/parent/settings_screen.dart
    features/spike/tts_spike_screen.dart   (Task 3, debug-only)
    features/lands/letter_adventure/...
    features/lands/hoorof/...
    features/lands/number_kingdom/...
    features/lands/math_lab/...
    features/lands/animal_planet/...
    features/lands/around_the_world/...
    features/lands/spot_me/...
  test/                    mirrors lib/ structure
```

## Save Schema v1 (canonical)

```json
{
  "schemaVersion": 1,
  "profileId": "<uuid>",
  "name": "Hassan",
  "xp": 0,
  "level": 1,
  "stars": 0,
  "eggs": 0,
  "streak": 0,
  "soundOn": true,
  "hatched": [],
  "stickers": [],
  "animalsFound": [],
  "lettersMastered": [],
  "lettersLearning": [],
  "numbersMastered": [],
  "progress": {"letter":0,"arabic":0,"number":0,"math":0,"animal":0,"world":0,"find":0},
  "minutesToday": 0,
  "lastPlayedDate": "2026-07-01",
  "week": [0,0,0,0,0,0,0],
  "levels": {},
  "world": {"visited":{},"points":0,"discovery":{}}
}
```

Notes: `levels` maps a game-type id (e.g. `"big"`, `"match"`, `"count"`, `"math_eggs"`, `"word"`) to a `List<bool>` of per-game completion. `week` is minutes per weekday, Monday=index 0. `hatched`/`stickers`/`animalsFound` are deduped string lists.

## Phase Overview

| Phase | Tasks | Deliverable |
|---|---|---|
| 0 Scaffold & spike | 1–3 | Running blank app on iPad + Arabic TTS go/no-go |
| 1 Domain core (pure Dart, TDD) | 4–9 | Save model, persistence, rewards, dealer, controller |
| 2 Services & shell | 10–17 | Art, TTS, SFX, scaler, HUD, reward modal, map, parent gate |
| 3 Engines | 18–22 | LevelSelect/GameDeck, SpotScene, Trace, FlipCard, DriftField |
| 4 Content data | 23–26 | All content pools ported from prototype |
| 5 Lands | 27–33 | All 7 playable lands |
| 6 Dashboard & release | 34–35 | Parent dashboard, app icon, privacy artifacts, QA script |

Tasks within a phase that touch different files may run in parallel; phases are sequential. Every land task (27–33) depends only on phases 0–4.

---

### Task 1: Flutter scaffold in `app/`

**Files:**
- Create: `app/` via `flutter create`, then `app/analysis_options.yaml`, folder skeleton under `app/lib/` per file map, `app/lib/main.dart`, `app/lib/app.dart`

**Interfaces:**
- Produces: a running app showing a placeholder `Scaffold`; `main()` locks landscape via `SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight])` before `runApp(ProviderScope(child: WonderQuestApp()))`.

- [ ] **Step 1: Create project**

```bash
cd /Users/iammoo/code/wonderquest
flutter create --org com.hussain --project-name wonder_quest --platforms=ios,android app
```

(Bundle id becomes `com.hussain.wonder_quest`; the final App Store bundle id is set at release time, Task 35.)

- [ ] **Step 2: Add dependencies**

In `app/`: `flutter pub add flutter_riverpod flutter_tts audioplayers path_provider uuid` and `flutter pub add --dev flutter_lints`.

- [ ] **Step 3: Strict lints**

`app/analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml
linter:
  rules:
    prefer_const_constructors: true
    always_declare_return_types: true
```

- [ ] **Step 4: iOS landscape lock**

In `app/ios/Runner/Info.plist` set `UISupportedInterfaceOrientations` and `UISupportedInterfaceOrientations~ipad` to ONLY `UIInterfaceOrientationLandscapeLeft` and `UIInterfaceOrientationLandscapeRight`. Also set `UIRequiresFullScreen` = `true`.

- [ ] **Step 5: main.dart + app.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ProviderScope(child: WonderQuestApp()));
}
```

```dart
// lib/app.dart
import 'package:flutter/material.dart';

class WonderQuestApp extends StatelessWidget {
  const WonderQuestApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Wonder Quest',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('Wonder Quest'))),
    );
  }
}
```

- [ ] **Step 6: Verify**

Run: `flutter analyze` → 0 issues. `flutter test` → the default widget test will fail against our new app; replace `app/test/widget_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/app.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(const WonderQuestApp());
    expect(find.text('Wonder Quest'), findsOneWidget);
  });
}
```

Run: `flutter test` → PASS.

- [ ] **Step 7: Commit**

```bash
git add app && git commit -m "feat: scaffold Flutter app with landscape lock and deps"
```

---

### Task 2: Design tokens & bundled fonts

**Files:**
- Create: `app/lib/theme/wq_colors.dart`, `app/lib/theme/wq_theme.dart`, `app/assets/fonts/*`
- Modify: `app/pubspec.yaml`, `app/lib/app.dart`
- Read first: `wiki/systems/design-system.md`

**Interfaces:**
- Produces: `WqColors.orange` … `WqColors.lines` (static `Color` consts, hex values from Global Constraints); `WqTheme.theme` (`ThemeData`); text styles `WqTheme.heading` (Baloo 2) / `WqTheme.body` (Nunito).

- [ ] **Step 1: Vendor fonts.** Download TTFs (OFL-licensed) for Baloo 2 (Regular/Bold), Nunito (Regular/Bold), Noto Naskh Arabic (Regular/Bold) from Google Fonts GitHub (`github.com/google/fonts`), place in `app/assets/fonts/`, declare all three families + the `assets/sfx/` folder in `pubspec.yaml`. **Do NOT use the google_fonts package** (runtime fetch violates offline rule).
- [ ] **Step 2: Write `wq_colors.dart`** with one `static const Color` per palette entry from Global Constraints (e.g. `static const orange = Color(0xFFFF8A3D);`), plus `landColors` list cycling orange/teal/green/coral/grape/sky/yellow/pink for land tiles.
- [ ] **Step 3: Write `wq_theme.dart`**: `ThemeData` with `scaffoldBackgroundColor: WqColors.background`, `fontFamily: 'Nunito'`, and `headingStyle(double size)` helper returning Baloo 2 bold in `WqColors.ink`. Wire into `app.dart` `MaterialApp(theme: WqTheme.theme, ...)`.
- [ ] **Step 4: Widget test** `app/test/theme/wq_theme_test.dart`: pump a `MaterialApp(theme: WqTheme.theme)` and assert `Theme.of` scaffold background equals `WqColors.background`. Run `flutter test` → PASS.
- [ ] **Step 5: Commit** `feat: design tokens, theme, bundled fonts`

---

### Task 3: Arabic TTS spike (go/no-go gate for Hoorof audio)

**Files:**
- Create: `app/lib/features/spike/tts_spike_screen.dart`
- Create: `wiki/requirements/arabic-tts-spike-result.md` (filled in after manual run)
- Read first: `wiki/systems/audio-speech.md`, `wiki/modules/hoorof.md`

**Interfaces:**
- Produces: a written decision — Arabic TTS is (a) good enough, or (b) fallback to bundled recorded audio needed. Task 33 (Hoorof) consumes this decision.

- [ ] **Step 1:** Build a debug screen (reachable via a temporary button on the placeholder home) with buttons: "List voices" (prints `FlutterTts.getVoices` filtered to `ar-*`), "Speak ب" / "Speak بَطَّة" (uses an `ar-*` voice, rate 0.4), "Speak English fallback".
- [ ] **Step 2:** Run on a real iPad **in airplane mode**. Note: which `ar-*` voices exist offline, subjective quality (child-appropriate? correct letter names?), latency.
- [ ] **Step 3:** Write results + decision into `wiki/requirements/arabic-tts-spike-result.md` (Status: prototype-validated), append a line to `wiki/log.md`. If NO acceptable voice: the decision is "bundle recorded Arabic letter audio in Task 33" — record the chosen source (family recordings or CC0 clips) there.
- [ ] **Step 4: Commit** `feat: arabic tts spike screen + decision record`

**NOTE for executor:** if no iPad is attached to the dev machine, implement the screen, run on the iOS simulator (voice list still enumerable), mark the wiki page `Status: needs-device-verification`, and continue — do not block the plan.

---

### Task 4: SaveData model (schema v1, TDD)

**Files:**
- Create: `app/lib/core/persistence/save_data.dart`
- Test: `app/test/core/persistence/save_data_test.dart`
- Read first: `wiki/systems/state-persistence.md`, the Save Schema v1 block above

**Interfaces:**
- Produces: `class SaveData` — immutable, `const`-friendly, with **exactly** the fields of Save Schema v1: `int schemaVersion, String profileId, String name, int xp, int level, int stars, int eggs, int streak, bool soundOn, List<String> hatched, List<String> stickers, List<String> animalsFound, List<String> lettersMastered, List<String> lettersLearning, List<String> numbersMastered, Map<String,int> progress, int minutesToday, String lastPlayedDate, List<int> week, Map<String,List<bool>> levels, WorldState world`. Plus `WorldState` (`Map<String,bool> visited, int points, Map<String,bool> discovery`). Methods: `SaveData.initial({required String profileId})` (defaults per schema, name "Hassan"), `copyWith(...)` covering every field, `toJson()`, `SaveData.fromJson(Map<String,dynamic>)` (missing keys → defaults, i.e. defaults-merge on load), `==`/`hashCode` via field-by-field comparison (write manually or with `collection` package `DeepCollectionEquality`).

- [ ] **Step 1: Write failing tests** covering: (a) `initial()` matches schema defaults incl. all 7 progress keys; (b) `toJson`→`fromJson` round-trips a fully-populated instance unchanged; (c) `fromJson({'schemaVersion': 1})` fills every missing field with defaults; (d) `copyWith(stars: 5)` changes only stars.

```dart
test('fromJson merges defaults for missing keys', () {
  final s = SaveData.fromJson({'schemaVersion': 1, 'profileId': 'p1', 'stars': 3});
  expect(s.stars, 3);
  expect(s.level, 1);
  expect(s.progress['arabic'], 0);
  expect(s.week, hasLength(7));
});
```

- [ ] **Step 2:** Run `flutter test test/core/persistence/save_data_test.dart` → FAIL (class missing).
- [ ] **Step 3:** Implement `SaveData` + `WorldState` fully.
- [ ] **Step 4:** Run tests → PASS. `flutter analyze` → 0 issues.
- [ ] **Step 5: Commit** `feat: SaveData schema v1 model with defaults-merge json`

---

### Task 5: Atomic SaveFileStore (TDD)

**Files:**
- Create: `app/lib/core/persistence/save_file.dart`
- Test: `app/test/core/persistence/save_file_test.dart`

**Interfaces:**
- Consumes: `SaveData` (Task 4).
- Produces: `class SaveFileStore { SaveFileStore(Directory dir); Future<SaveData> load(); Future<void> save(SaveData data); }`. `load()`: file missing → `SaveData.initial(profileId: <new uuid>)`; corrupt JSON → same (and renames the bad file to `wonderquest_save.corrupt.json` so data is never silently destroyed); future `schemaVersion > 1` handled by a `migrate(Map json)` hook that currently returns the map unchanged. `save()`: JSON-encode → write `wonderquest_save.json.tmp` → `File.rename` over `wonderquest_save.json` (atomic on iOS/APFS).

- [ ] **Step 1: Failing tests** using `Directory.systemTemp.createTempSync()`: (a) load-from-empty-dir returns initial with non-empty profileId; (b) save-then-load round-trips; (c) load with garbage file returns initial AND `.corrupt.json` exists; (d) after `save()`, no `.tmp` file remains.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Run → PASS, analyze clean.
- [ ] **Step 5: Commit** `feat: atomic JSON save file store with corruption quarantine`

---

### Task 6: Reward engine (TDD)

**Files:**
- Create: `app/lib/domain/reward.dart`, `app/lib/domain/reward_engine.dart`
- Test: `app/test/domain/reward_engine_test.dart`
- Read first: `wiki/systems/rewards-gamification.md` (formulas are copied into this task — verify they match)

**Interfaces:**
- Consumes: `SaveData`.
- Produces:

```dart
class Reward {
  const Reward({this.stars = 0, this.xp = 0, this.egg = false, this.sticker,
    this.animal, this.progressKey, this.progressTo, this.silent = false});
  final int stars; final int xp; final bool egg;
  final String? sticker; final String? animal;
  final String? progressKey; final int? progressTo; final bool silent;
}

int xpForLevel(int level); // 100 + (level - 1) * 60
SaveData applyReward(SaveData s, Reward r);
```

`applyReward` rules (all verbatim from wiki): add stars; add xp then **while** `xp >= xpForLevel(level)` subtract and increment level (multi-level-up rollover); `egg` → `eggs + 1`; `sticker`/`animal` appended **only if not already present** (dedupe); `progressKey` with `progressTo` → `progress[key] = max(current, progressTo).clamp(0, 100)` (progress never decreases).

- [ ] **Step 1: Failing tests**: xpForLevel(1)==100, xpForLevel(2)==160; single level-up leaves remainder (level 1 + 130xp → level 2, xp 30); multi-level-up (level 1 + 300xp → level 3, xp 300−100−160=40); sticker dedupe; progress monotonic (progressTo 40 then 20 stays 40) and clamps at 100.
- [ ] **Step 2:** FAIL → **Step 3:** implement → **Step 4:** PASS + analyze.
- [ ] **Step 5: Commit** `feat: reward engine with xp rollover and dedupe`

---

### Task 7: Daily rollover — streak, minutes, week (TDD)

**Files:**
- Create: `app/lib/core/daily_rollover.dart`
- Test: `app/test/core/daily_rollover_test.dart`

**Interfaces:**
- Consumes: `SaveData`.
- Produces: `SaveData applyDailyRollover(SaveData s, DateTime now)` — pure function called once at app launch and on resume. Rules: dates compared as `yyyy-MM-dd` strings in local time. If `lastPlayedDate` == today → no change. If yesterday → `streak + 1`, `minutesToday = 0`. If older (or empty) → `streak = 1`, `minutesToday = 0`. Always sets `lastPlayedDate` to today. If the ISO week changed since `lastPlayedDate`, zero the whole `week` list first. Also produces `SaveData addPlayMinute(SaveData s, DateTime now)`: increments `minutesToday` and `week[now.weekday - 1]`.

- [ ] **Step 1: Failing tests**: same-day no-op; consecutive-day streak increment; gap resets streak to 1; week array zeroed on new ISO week; `addPlayMinute` bumps the right weekday slot.
- [ ] **Step 2:** FAIL → **Step 3:** implement → **Step 4:** PASS + analyze.
- [ ] **Step 5: Commit** `feat: daily rollover for streak/minutes/week`

---

### Task 8: Level dealer (TDD)

**Files:**
- Create: `app/lib/domain/level_dealer.dart`
- Test: `app/test/domain/level_dealer_test.dart`
- Read first: `wiki/systems/game-engines.md` §Level-Dealer, `raw/levels.jsx`

**Interfaces:**
- Produces: `List<List<T>> dealGames<T>({required List<T> pool, required int games, required int perGame, required Random random})`. Contract (verbatim from wiki): fills game-by-game drawing **least-used items first** (ties broken randomly); **no repeat within a single game** whenever `perGame <= pool.length`; usage spread so each item is used ≤2× across all games once `pool.length >= games*perGame/2`; if `perGame > pool.length`, repeats are allowed to fill. Deterministic for a seeded `Random`.

- [ ] **Step 1: Failing tests**: (a) 90-item pool, 10 games × 15: every game has 15 unique items, every item used ≤2× overall, all games full; (b) pool of 5, 1 game × 8 → repeats allowed, game length 8; (c) seeded Random(42) twice → identical deal; (d) 26-item pool, 10×15 → no within-game dupes.
- [ ] **Step 2:** FAIL → **Step 3:** implement:

```dart
List<List<T>> dealGames<T>({required List<T> pool, required int games,
    required int perGame, required Random random}) {
  final use = <T, int>{for (final p in pool) p: 0};
  final out = <List<T>>[];
  for (var g = 0; g < games; g++) {
    final game = <T>[];
    final candidates = [...pool]..shuffle(random);
    candidates.sort((a, b) => use[a]!.compareTo(use[b]!)); // stable: keeps shuffle for ties
    for (final c in candidates) {
      if (game.length == perGame) break;
      game.add(c);
      use[c] = use[c]! + 1;
    }
    var i = 0;
    while (game.length < perGame) {
      game.add(pool[i % pool.length]);
      i++;
    }
    game.shuffle(random);
    out.add(game);
  }
  return out;
}
```

- [ ] **Step 4:** PASS + analyze. **Step 5: Commit** `feat: level dealer with least-used-first distribution`

---

### Task 9: SaveController (Riverpod, single write path)

**Files:**
- Create: `app/lib/core/save_controller.dart`
- Test: `app/test/core/save_controller_test.dart`

**Interfaces:**
- Consumes: `SaveData`, `SaveFileStore`, `applyReward`, `applyDailyRollover`, `addPlayMinute`.
- Produces:

```dart
final saveStoreProvider = Provider<SaveFileStore>((ref) => throw UnimplementedError('override in main'));
final saveControllerProvider = AsyncNotifierProvider<SaveController, SaveData>(SaveController.new);

class SaveController extends AsyncNotifier<SaveData> {
  @override Future<SaveData> build();            // load(), then applyDailyRollover(now)
  Future<void> apply(Reward r);                  // applyReward + persist
  Future<void> toggleSound();
  Future<void> markLevelDone(String typeId, int index, int totalGames); // grows/updates levels[typeId]
  Future<void> setLetterMastered(String letter); // moves from learning→mastered, dedupes
  Future<void> setLetterLearning(String letter);
  Future<void> setNumberMastered(String n);
  Future<void> hatchEgg(String dinoName);        // eggs>0: eggs-1, hatched+name
  Future<void> visitContinent(String id);        // world.visited[id]=true + persist
  Future<void> collectDiscoveryCard(String cardId);
  Future<void> addMinute();                      // addPlayMinute(now) + persist
  Future<void> resetAllProgress();               // SaveData.initial(same profileId) — parent-gated caller
}
```

Every mutator: compute new state → `state = AsyncData(newState)` → `await store.save(newState)`. In `main.dart`, override `saveStoreProvider` with the real documents directory (`path_provider`).

- [ ] **Step 1: Failing tests** with a `ProviderContainer` overriding `saveStoreProvider` to a temp-dir store: `apply(Reward(stars: 2))` persists (reload store → stars 2); `markLevelDone('big', 3, 10)` yields a 10-length list with index 3 true; `hatchEgg` decrements eggs and appends; `resetAllProgress` keeps profileId.
- [ ] **Step 2:** FAIL → **Step 3:** implement → **Step 4:** PASS + analyze.
- [ ] **Step 5: Commit** `feat: SaveController riverpod notifier with persistence`

---

### Task 10: Art asset-lookup layer

**Files:**
- Create: `app/lib/core/art.dart`
- Test: `app/test/core/art_test.dart`
- Read first: `wiki/requirements/decisions-2026-07-01.md` (art decision)

**Interfaces:**
- Produces: the ONLY place emoji/art strings live for shared visuals:

```dart
/// v1 renders emoji strings; v2 swaps to illustration assets by changing
/// ONLY this class (return an Image widget instead). Never bypass it.
class Art {
  static Widget glyph(String key, {double size = 48});   // Text(emoji, fontSize: size) for now
  static String emoji(String key);                        // raw emoji lookup
  static const mascot = 'rexy';                           // key for 🦖
}
```

Keys are semantic (`'rexy'`, `'egg'`, `'star'`, `'lock'`, plus passthrough: unknown keys that are already emoji render as-is — content pools store emoji directly and pass them through `Art.glyph`). This gives one seam: later, known keys map to images and passthrough emoji get replaced pool-by-pool.

- [ ] **Step 1: Failing test**: `Art.emoji('rexy') == '🦖'`; `Art.emoji('🐝') == '🐝'` (passthrough); `Art.glyph('star')` builds a `Text` with the star emoji.
- [ ] **Step 2:** FAIL → implement (map: rexy 🦖, egg 🥚, star ⭐, lock 🔒, parent 👪, sound-on 🔊, sound-off 🔇) → PASS + analyze.
- [ ] **Step 3: Commit** `feat: Art asset-lookup seam`

---

### Task 11: TtsService

**Files:**
- Create: `app/lib/core/audio/tts_service.dart`
- Test: `app/test/core/audio/tts_service_test.dart`
- Read first: `wiki/systems/audio-speech.md`, Task 3's `wiki/requirements/arabic-tts-spike-result.md`

**Interfaces:**
- Consumes: `soundOn` from `saveControllerProvider`.
- Produces:

```dart
final ttsServiceProvider = Provider<TtsService>(...);

class TtsService {
  TtsService(this._tts, {required bool Function() soundOn});
  Future<void> speak(String text, {double rate = 0.45, double pitch = 1.1});
  Future<void> sayPhonics(String letter, String word); // "B… buh… Bat!" pattern from wiki
  Future<void> speakArabic(String arabic, String fallbackTransliteration);
  Future<void> stop();
}
```

`speakArabic`: enumerate voices once (cache), pick first `ar-*`; if none, speak `fallbackTransliteration` in English (wiki-validated fallback). All methods no-op when `soundOn()` is false. Constructor takes `FlutterTts` so tests can pass a fake.

- [ ] **Step 1: Failing tests** with a recorded-calls fake `FlutterTts`-shaped class (wrap `FlutterTts` behind a 3-method `abstract class TtsBackend { speak; setVoice; getVoices; }` so the fake is trivial): muted → no calls; `sayPhonics('B','Bat')` speaks a string containing "B" and "Bat"; `speakArabic` with no ar voice speaks the fallback.
- [ ] **Step 2:** FAIL → implement → PASS + analyze.
- [ ] **Step 3: Commit** `feat: TtsService with phonics and arabic fallback`

---

### Task 12: SFX — generated WAVs + SfxService

**Files:**
- Create: `app/tool/gen_sfx.dart` (dev script), `app/assets/sfx/*.wav` (generated), `app/lib/core/audio/sfx_service.dart`
- Test: `app/test/tool/gen_sfx_test.dart`
- Read first: `wiki/systems/audio-speech.md` §synthesized tones (whale call spec: base frequency + LFO vibrato + gain envelope)

**Interfaces:**
- Produces: `SfxService` with `Future<void> play(Sfx sfx)` where `enum Sfx { pop, ding, wrong, fanfare, whaleLow, whaleHigh }`, backed by `audioplayers` `AudioPlayer` playing bundled assets, muted when `soundOn` false. Also `tool/gen_sfx.dart`: pure-Dart 16-bit PCM mono 22050 Hz WAV writer + synth functions `sine(freq, seconds)`, `envelope`, `vibrato(base, lfoHz, depth)`; run once via `dart run tool/gen_sfx.dart` to emit the 6 wavs (pop: 600→900 Hz 0.1 s sweep; ding: 880 Hz 0.25 s; wrong: 220 Hz 0.2 s; fanfare: 523/659/784 Hz arpeggio 0.6 s; whaleLow: 80 Hz base, 4 Hz LFO, 2 s; whaleHigh: 500 Hz base, 6 Hz LFO, 1.5 s).

- [ ] **Step 1 (TDD the WAV writer):** failing test — `buildWav(samples)` output starts with bytes `RIFF`, has correct data-chunk length, sample count for 1 s @22050 Hz is 22050.
- [ ] **Step 2:** FAIL → implement writer + synths → PASS.
- [ ] **Step 3:** `dart run tool/gen_sfx.dart` → 6 files in `assets/sfx/`; confirm `pubspec.yaml` bundles them; commit the wavs (they're small, deterministic, and the script regenerates them).
- [ ] **Step 4:** Implement `SfxService` (thin; no test beyond analyze).
- [ ] **Step 5:** `flutter analyze` + `flutter test` → clean/green. **Commit** `feat: synthesized sfx assets and SfxService`

---

### Task 13: Canvas scaler + WqButton

**Files:**
- Create: `app/lib/widgets/canvas_scaler.dart`, `app/lib/widgets/wq_button.dart`
- Test: `app/test/widgets/canvas_scaler_test.dart`
- Read first: `wiki/systems/scaling-device-frame.md`, `wiki/systems/design-system.md` §buttons

**Interfaces:**
- Produces: `class CanvasScaler extends StatelessWidget { const CanvasScaler({required this.child}); }` — a `ColoredBox(color: WqColors.ink)` filling the screen, centering a `FittedBox(fit: BoxFit.contain)` wrapping `SizedBox(width: 1194, height: 834, child: child)`. ALL screens render inside it, so every screen lays out against exactly 1194×834 logical px. Also `WqButton({required String label, String? emojiKey, required Color color, required VoidCallback onTap, double fontSize = 22})` — pill shape, darker bottom "shadow" band, presses down 3 px on tap-down (the prototype's signature button), min height 64.

- [ ] **Step 1: Failing widget test**: pump `CanvasScaler(child: SizedBox.expand())` inside a 2000×1000 surface (`tester.view.physicalSize`); assert the inner SizedBox's `RenderBox.size == Size(1194, 834)` and a letterbox `ColoredBox` with `WqColors.ink` exists. Second test at 1194×900 surface (taller than 16:11) still yields inner 1194×834.
- [ ] **Step 2:** FAIL → implement → PASS + analyze.
- [ ] **Step 3: Play-minutes ticker.** Also in `canvas_scaler.dart`, add `class PlayMinuteTicker extends ConsumerStatefulWidget` — wraps its child, runs a `Timer.periodic(Duration(minutes: 1))` calling `SaveController.addMinute()`, paused when app is backgrounded (`WidgetsBindingObserver` lifecycle). Wire `app.dart`: `home: CanvasScaler(child: PlayMinuteTicker(child: <placeholder>))` (map screen arrives in Task 16). Test: pump with a fake async `tester.pump(Duration(minutes: 2))` → minutesToday == 2.
- [ ] **Step 4:** analyze/test green. **Commit** `feat: fixed 1194x834 canvas scaler, WqButton, minute ticker`

---

### Task 14: HUD

**Files:**
- Create: `app/lib/widgets/hud.dart`
- Test: `app/test/widgets/hud_test.dart`
- Read first: `wiki/systems/design-system.md` §HUD, `raw/menu.jsx`

**Interfaces:**
- Consumes: `saveControllerProvider` (level/xp/streak/stars/eggs/soundOn), `xpForLevel`, `Art`.
- Produces: `class Hud extends ConsumerWidget { const Hud({required this.onParentTap}); }` — a top bar (height 72) showing: mascot avatar + "Lv N", XP progress bar (`xp / xpForLevel(level)` fraction), streak 🔥 count, star count, egg count, sound toggle (calls `toggleSound()`), parent 👪 button (calls `onParentTap`). All counts read live from the provider.

- [ ] **Step 1: Failing widget test**: `ProviderScope` with overridden temp-dir store; seed save with stars 7, level 2, xp 80; pump `Hud`; expect `find.text('7')`, `find.text('Lv 2')`; tap sound toggle → provider state `soundOn` flips.
- [ ] **Step 2:** FAIL → implement → PASS + analyze. **Step 3: Commit** `feat: HUD bar`

---

### Task 15: RewardModal + confetti

**Files:**
- Create: `app/lib/widgets/reward_modal.dart`
- Test: `app/test/widgets/reward_modal_test.dart`
- Read first: `wiki/systems/design-system.md` §Reward Modal, `wiki/systems/rewards-gamification.md` §Reward Flow

**Interfaces:**
- Consumes: `Reward`, `SaveController.apply`, `SfxService` (fanfare).
- Produces: `Future<void> showRewardModal(BuildContext context, WidgetRef ref, Reward reward, {VoidCallback? onPlayAgain})` — applies the reward via `SaveController.apply`, then shows a dialog: confetti burst (a `CustomPainter` animating ~40 colored particles falling over 1.5 s), starburst behind Rexy, "pills" for each nonzero component (`+3 ⭐`, `+40 XP`, `🥚 New egg!`, sticker/animal), and two `WqButton`s: "🗺 Map" (pop to map) and "▶ Play again" (calls `onPlayAgain`, hidden when null). If `reward.silent` is true, the helper applies the reward and returns WITHOUT showing UI (used by Discovery Cards which celebrate their own way).

- [ ] **Step 1: Failing widget test**: showing modal with `Reward(stars: 3, xp: 40)` renders texts `+3` and `+40 XP`, and provider stars increased by 3; silent reward shows no dialog but still applies.
- [ ] **Step 2:** FAIL → implement (confetti painter: seed-random particles, `AnimationController` 1.5 s) → PASS + analyze. **Step 3: Commit** `feat: reward modal with confetti`

---

### Task 16: Land registry + Expedition Map home screen

**Files:**
- Create: `app/lib/content/lands.dart`, `app/lib/features/map/expedition_map_screen.dart`
- Test: `app/test/features/map/expedition_map_test.dart`
- Modify: `app/lib/app.dart` (home = map inside CanvasScaler)
- Read first: `wiki/overview.md`, `raw/menu.jsx`, `wiki/modules/locked-lands.md`

**Interfaces:**
- Produces: `class Land { final String id, title, sub, emojiKey; final Color color; final bool playable; final WidgetBuilder? builder; }` and `const/final List<Land> kLands` — **13 entries in this order**: Letter Adventure, Hoorof, Number Kingdom, Little Math Lab, Animal Planet, Around the World, Spot Me If You Can (playable, builders filled in Tasks 27–33 — until then a "Coming in a later task" placeholder screen), then Dino Discovery, Earth Explorer, Maze World, Tracing Studio, Pattern Detective, Reading Readiness (locked). Pull each land's exact `title`, `sub` tagline and emoji from `raw/menu.jsx`. `ExpeditionMapScreen`: `Hud` on top; scrollable grid (4 columns) of land cards — rounded 24 px, land color, emoji, title, "▶ Play" pill or "🔒 Soon" pill + grayed style; per-land progress bar reading `progress[key]` for its mapped progress key; a Rexy mascot tip bubble cycling 3 encouragement lines.

- [ ] **Step 1: Collections & egg hatching** (wiki: eggs hatch into a named dino collection; sticker book): a "🎒 My Stuff" button on the map opens a tabbed modal — Dinos tab (hatched dino names + a "Hatch!" `WqButton` enabled when `eggs > 0`: crack animation → random unhatched name from `['Bronto','Rexy Jr','Stego','Tricera','Ptera','Raptor']` → `hatchEgg(name)`), Stickers tab (grid of `stickers`), Animals tab (grid of `animalsFound`).
- [ ] **Step 2: Failing widget test**: map renders 13 cards; locked card shows 🔒 and tapping it does NOT navigate; tapping a playable card pushes its builder route; with eggs=1, Hatch adds a dino and decrements eggs.
- [ ] **Step 3:** FAIL → implement → PASS + analyze. Run app in simulator; visually confirm layout fits 1194×834.
- [ ] **Step 4: Commit** `feat: expedition map with 13 land registry, collections modal`

---

### Task 17: Parent gate + settings

**Files:**
- Create: `app/lib/features/parent/parent_gate.dart`, `app/lib/features/parent/settings_screen.dart`
- Test: `app/test/features/parent/parent_gate_test.dart`
- Read first: `wiki/requirements/decisions-2026-07-01.md` §parental gate

**Interfaces:**
- Produces: `Future<bool> showParentGate(BuildContext context)` — dialog asking a random single-digit multiplication (`a × b`, a,b ∈ 3–9) with a number pad; correct → pops `true`; wrong → shake + new question; "✕" → `false`. Gate the HUD 👪 button: pass → `DashboardScreen` (placeholder `Scaffold` until Task 34) with a Settings button → `SettingsScreen`: sound toggle, "Reset all progress" (confirm dialog → `resetAllProgress()`), app version, credits line.

- [ ] **Step 1: Failing widget test** (inject `Random(1)` via optional param for a deterministic question): correct product unlocks (completer resolves true); wrong entry keeps dialog open.
- [ ] **Step 2:** FAIL → implement → PASS + analyze. **Step 3: Commit** `feat: multiplication parent gate and settings`

---

### Task 18: LevelSelect + GameDeck wrappers

**Files:**
- Create: `app/lib/widgets/level_select.dart`
- Test: `app/test/widgets/level_select_test.dart`
- Read first: `wiki/systems/game-engines.md` §Level-Dealer UI, `raw/levels.jsx`

**Interfaces:**
- Consumes: `dealGames`, `saveControllerProvider.levels`, `markLevelDone`.
- Produces:

```dart
/// Grid of "Game N" tiles; ⭐ badge on completed ones (levels[typeId][n]).
class LevelSelect extends ConsumerWidget {
  const LevelSelect({required this.typeId, required this.games,
    required this.title, required this.color, required this.onPlay});
  final String typeId; final int games; final String title; final Color color;
  final void Function(int gameIndex) onPlay;
}

/// Deals the pool ONCE (seeded by typeId+gameIndex so re-entry is stable),
/// steps through questions, then fires onComplete.
class GameDeck<T> extends StatefulWidget {
  const GameDeck({required this.typeId, required this.gameIndex,
    required this.pool, required this.games, required this.perGame,
    required this.questionBuilder, required this.onComplete});
  final String typeId; final int gameIndex;
  final List<T> pool; final int games; final int perGame;
  /// Build the UI for one question; call advance() when answered correctly.
  final Widget Function(BuildContext, T item, void Function() advance) questionBuilder;
  final void Function() onComplete; // caller marks level + shows RewardModal
}
```

Seeding: `Random(typeId.hashCode ^ gameIndex)` so the same game always deals the same questions (wiki: "keep deterministic seeding if reproducible games desired"). `GameDeck` shows a progress dots row (question k of N).

- [ ] **Step 1: Failing widget tests**: LevelSelect renders `games` tiles and stars completed ones from seeded save; GameDeck with a 3-item pool advances through 3 questionBuilder invocations then calls onComplete exactly once.
- [ ] **Step 2:** FAIL → implement → PASS + analyze. **Step 3: Commit** `feat: LevelSelect grid and GameDeck runner`

---

### Task 19: SpotScene engine + widget

**Files:**
- Create: `app/lib/domain/spot_scene_engine.dart`, `app/lib/widgets/spot_scene.dart`
- Test: `app/test/domain/spot_scene_engine_test.dart`, `app/test/widgets/spot_scene_test.dart`
- Read first: `wiki/systems/game-engines.md` §SpotScene, `raw/spot-engine.jsx`, `raw/spot-engine2.jsx`

**Interfaces:**
- Produces (pure Dart engine):

```dart
class SpotGoal { const SpotGoal({required this.char, required this.count, required this.label}); }
enum SpotMode { find, count }
class PlacedItem { final String char; final Offset pos; final double size; final bool isTarget; final int id; }

class SpotSceneLayout {
  /// Jittered grid: divide canvas into ceil(sqrt(total)) grid, one item per
  /// cell (shuffled), jitter within cell, so items never fully overlap.
  static List<PlacedItem> place({required List<SpotGoal> goals,
    required List<String> decoys, required int decoyCount,
    required Size canvas, required Random random});
}

class SpotSceneState { // tap bookkeeping
  SpotSceneState(this.goals, this.mode);
  bool tap(PlacedItem item);      // target not-yet-found → true (found); else false
  Map<String, int> get foundByChar;
  bool get complete;              // every goal's count reached
}
```

And the widget: `SpotScene({required List<SpotGoal> goals, required SpotMode mode, required List<String> decoys, required int decoyCount, required Color bg, List<String> deco = const [], required VoidCallback onComplete})` — renders placed items via `Art.glyph` on the colored scene; correct tap → pop scale animation + ring + `Sfx.pop` (+ running number label in count mode); wrong tap → brief "👀" ripple at tap point + `Sfx.wrong`; goal chips along the top tick up `found/count`; all goals met → `onComplete()`.

- [ ] **Step 1: Failing engine tests**: place() puts every item inside canvas bounds; item count == sum(goal counts) + decoyCount; no two items closer than 0.5 × min cell size; state: tapping a target twice counts once; complete only when all goals met.
- [ ] **Step 2:** FAIL → implement engine → PASS.
- [ ] **Step 3: Failing widget test**: 1 goal ({char:🐝, count:2}), 0 decoys; tap both bees → onComplete fired.
- [ ] **Step 4:** FAIL → implement widget → PASS + analyze. **Step 5: Commit** `feat: SpotScene engine and widget`

---

### Task 20: TraceScorer + TraceCanvas

**Files:**
- Create: `app/lib/domain/trace_scorer.dart`, `app/lib/widgets/trace_canvas.dart`
- Test: `app/test/domain/trace_scorer_test.dart`
- Read first: `wiki/systems/game-engines.md` §Trace, `raw/trace.jsx`, `wiki/modules/letter-adventure.md`

**Interfaces:**
- Produces (pure Dart):

```dart
class TraceScorer {
  TraceScorer({required List<Offset> guidePoints, this.tolerance = 28});
  void addStrokePoint(Offset p);       // marks guide points within tolerance as covered
  double get coverage;                  // covered / total, 0..1
  bool get done;                        // coverage >= 0.85
}
```

Guide points come from rasterizing the glyph: `TraceCanvas` paints the glyph with `TextPainter` (font size ~420, `WqColors.lines` color) into a `ui.PictureRecorder` → `toImage` → `byteData`; sample a 24×24 grid over the glyph's bounding box; grid cells whose pixel alpha > 0 become guide points (do this once in `initState`, async). Widget: `TraceCanvas({required String glyph, String fontFamily = 'Baloo 2', required VoidCallback onCovered})` — stack of guide glyph (light), child's strokes (`CustomPaint`, rounded stroke width 18, ink color), pan gesture feeding both the paint layer and the scorer; when `done` → sparkle overlay + `onCovered()` once. Works with finger and Apple Pencil (both arrive as pointer events — no extra code, but do NOT filter by pointer kind).

- [ ] **Step 1: Failing scorer tests** (pure, no raster): guide points = 10-point horizontal line, stroke along it → coverage 1.0 and done; stroke along half → coverage 0.5, not done; far stroke → 0.0.
- [ ] **Step 2:** FAIL → implement scorer → PASS.
- [ ] **Step 3:** Implement TraceCanvas + a widget smoke test (pumps, waits for async guide extraction with `tester.runAsync`, asserts CustomPaint present).
- [ ] **Step 4:** PASS + analyze. Manual check in simulator: trace "B", sparkle fires. **Step 5: Commit** `feat: trace scorer and canvas`

---

### Task 21: FlipCard widget

**Files:**
- Create: `app/lib/widgets/flip_card.dart`
- Test: `app/test/widgets/flip_card_test.dart`
- Read first: `wiki/systems/game-engines.md` §Flip Card

**Interfaces:**
- Produces: `FlipCard({required Widget front, required Widget back, VoidCallback? onFlipped, bool startFlipped = false})` — tap toggles a 400 ms Y-rotation (`AnimatedBuilder` + `Transform(Matrix4.identity()..setEntry(3,2,0.001)..rotateY(angle))`); content swaps at the 90° midpoint; `onFlipped` fires when the back becomes visible (first flip only).

- [ ] **Step 1: Failing widget test**: front visible initially, back not; tap + `pumpAndSettle` → back visible, `onFlipped` called once; second flip does not re-call it.
- [ ] **Step 2:** FAIL → implement → PASS + analyze. **Step 3: Commit** `feat: flip card`

---

### Task 22: DriftField (drag-collect) engine + widget

**Files:**
- Create: `app/lib/domain/drift_field.dart`, `app/lib/widgets/drift_field_widget.dart`
- Test: `app/test/domain/drift_field_test.dart`
- Read first: `wiki/systems/game-engines.md` §Drag-Collect, `raw/cards.jsx` (collect mini-game)

**Interfaces:**
- Produces (pure Dart):

```dart
class DriftItem { final int id; final String char; Offset pos; Offset velocity; bool collected; }
class DriftField {
  DriftField({required List<String> chars, required Size bounds,
    required double itemRadius, required Random random}); // random start pos + slow velocities
  void tick(double dtSeconds);                 // move items, bounce off edges
  List<int> collectAt(Offset dragPos, double dragRadius); // ids newly overlapping
  bool get allCollected;
}
```

Widget: `DriftFieldWidget({required List<String> itemChars, required String mascotKey, required VoidCallback onAllCollected})` — a `Ticker`-driven field (Ticker is Flutter's rAF-equivalent; the prototype's setInterval note is web-specific — ignore it, apps pause when backgrounded anyway); child drags the mascot (`Art.glyph`, 96 px); each tick calls `tick(dt)` then `collectAt(mascotPos, 60)`; collected items pop out with `Sfx.pop`; all collected → `onAllCollected()`.

- [ ] **Step 1: Failing engine tests**: tick moves items; an item heading past an edge bounces (velocity component sign flips, pos stays in bounds); collectAt returns overlapping ids once (collected items never returned again); allCollected true after collecting each id.
- [ ] **Step 2:** FAIL → implement engine → PASS.
- [ ] **Step 3:** Implement widget + smoke test (pump, drag mascot onto a seeded item position, expect collected count text updates).
- [ ] **Step 4:** PASS + analyze. **Step 5: Commit** `feat: drift field drag-collect engine`

---

## Phase 4 — Content data (port from prototype)

**Shared rules for Tasks 23–26:** Port pools **verbatim** from the named `raw/*.jsx` file — same items, same order, same words/facts (they're validated with the child). Every record type gets a `const` Dart class (no json — these are compile-time constants). Every content task's test asserts pool **sizes** and spot-checks 2–3 known records so a mis-port fails loudly. Emoji stay as strings in the pools (rendered later via `Art.glyph` passthrough).

### Task 23: English letters + word families content

**Files:**
- Create: `app/lib/content/english_letters.dart`
- Test: `app/test/content/english_letters_test.dart`
- Read first: `raw/data.jsx`, `wiki/modules/letter-adventure.md`

**Interfaces:**
- Produces: `class EnglishLetter { final String u, l, word, emoji, ph; }` (e.g. `EnglishLetter(u:'B', l:'b', word:'Bat', emoji:'🦇', ph:'buh')`); `const List<EnglishLetter> kEnglishLetters` (26, A–Z order); `const Map<String,String> kConfusables` (`{'b':'d','d':'b','p':'q','q':'p','g':'q','m':'w','w':'m', ...}` — copy the full map from `raw/data.jsx`); `const List<String> kMatchOrder` (easy→tricky order from prototype); `class WordFamily { final String emoji, word, end; final List<String> miss, distract; }` and `const List<WordFamily> kWordFamilies` — **all 75** (55 single-onset + 20 blends like FR/TR/SN).

- [ ] **Step 1: Failing tests**: 26 letters; letter 'B' has word 'Bat' and ph 'buh' (verify against raw/data.jsx and fix the test values if the prototype differs); 75 word families, 20 of which have `miss.length == 2`; every `distract` entry is a single uppercase letter or valid blend.
- [ ] **Step 2:** FAIL → port data → PASS + analyze. **Step 3: Commit** `feat: english letters and word family content`

### Task 24: Arabic letters content

**Files:**
- Create: `app/lib/content/arabic_letters.dart`
- Test: `app/test/content/arabic_letters_test.dart`
- Read first: `raw/hoorof-data.jsx`, `wiki/modules/hoorof.md`

**Interfaces:**
- Produces: `class ArabicLetter { final String g, nm, tr, snd, w, wtr, e; final String? base, dots; }` (e.g. `ArabicLetter(g:'ب', nm:'بَاء', tr:'Baa', snd:'b', w:'بَطَّة', wtr:'batta (duck)', e:'🦆', base:'ٮ', dots:'1b')`); `const List<ArabicLetter> kArabicLetters` (**28**, alphabetical order); `const List<List<String>> kArabicConfusableFamilies` — `[['ب','ت','ث','ن','ي'],['ج','ح','خ'],['د','ذ'],['ر','ز'],['س','ش'],['ص','ض'],['ط','ظ'],['ع','غ'],['ف','ق']]`; `const List<List<String>> kArabicClusters` — the 3–4-letter teaching clusters from the prototype; dots codes: `{count}{a|b}` (above/below) or `'0'`.

- [ ] **Step 1: Failing tests**: 28 letters; ب record matches above; every letter with a non-null `base` has a valid dots code matching `RegExp(r'^([123][ab]|0)$')`; clusters cover all 28 exactly once.
- [ ] **Step 2:** FAIL → port → PASS + analyze. **Step 3: Commit** `feat: arabic letters content`

### Task 25: Numbers + math content generators

**Files:**
- Create: `app/lib/content/numbers_content.dart`, `app/lib/content/math_content.dart`
- Test: `app/test/content/numbers_content_test.dart`, `app/test/content/math_content_test.dart`
- Read first: `raw/data.jsx`, `raw/math.jsx`, `wiki/modules/number-kingdom.md`, `wiki/modules/math-lab.md`

**Interfaces:**
- Produces (numbers): `class CountRound { final String emoji; final int count; }`, `class MissingNumberRound { final List<int> seq; final int missIdx; final int answer; final List<int> choices; }`; generators `List<CountRound> genCountRounds(int n, Random r)` (counts ramp 1→12, varied emoji from the prototype's object list) and `List<MissingNumberRound> genMissingRounds(int n, Random r)` (sequences lengthen over the list; 3 choices incl. answer). Both generate **90 items** for the 10×15 deal.
- Produces (math): `class MathStation { final String id, title, emoji, obj, objName; final Color color; final MathType type; }` with `enum MathType { count, add, sub, compare }`; `const List<MathStation> kMathStations` (**6**: Count the Zoo, Dino Snack Time, Treasure Hunt, Lost Dino Eggs, Cookie Math, More or Less — ids/titles/emoji from `raw/math.jsx`); object pools `kZooAnimals` (18), `kGems` (12), `kFruitsVeggies`; `class MathProblem { final int a, b, answer; final List<int> choices; final String obj; }` and `List<MathProblem> genMathProblems(MathType type, String stationId, int n, Random r)` honoring prototype ranges: add `a+b ≤ 16`; sub `total − take ≥ 0`; count 1–12; compare two unequal groups.

- [ ] **Step 1: Failing tests**: genCountRounds(90) → 90 rounds, all counts in 1..12, early rounds smaller than late on average; missing rounds: `seq[missIdx]` removed and equals `answer`, answer ∈ choices; 6 stations with expected ids; 200 seeded add problems all satisfy `a+b ≤ 16` and `answer ∈ choices` (4 choices for count/add/sub); compare problems never equal.
- [ ] **Step 2:** FAIL → implement → PASS + analyze. **Step 3: Commit** `feat: number and math content generators`

### Task 26: Animals, world & spot-scene content

**Files:**
- Create: `app/lib/content/animals_content.dart`, `app/lib/content/world_content.dart`, `app/lib/content/spot_scenes_content.dart`
- Test: one test file per content file under `app/test/content/`
- Read first: `raw/data.jsx`, `raw/sea.jsx`, `raw/cards-data.jsx`, `raw/world.jsx`, `raw/spot-data.jsx`

**Interfaces:**
- Produces (animals): `class Animal { final String emoji, name, habitat, fact; }` + `kAnimals` (port all); `class Habitat { final String id, name, emoji; final Color color; }` + `kHabitats` (**4**: Ocean, Jungle, Arctic, Savanna); `kOceanFacts` (**8** creatures: emoji, name, fact); `class Whale { final String e, n, f; final Color color; final int diveM; final double baseFreq; }` + `kWhales` (**6**: Blue, Humpback, Sperm, Orca, Beluga, Narwhal — dive depths & facts verbatim).
- Produces (world): `class Continent { final String id, name, emoji, badge, mission, theme; final Color color; final List<Animal> animals; }` + `kContinents` (**7**); `class DiscoveryCard { final String id, e, title, fact, sticker; final MiniGameSpec game; }` with `class MiniGameSpec { final MiniGameType type; final Map<String,Object> params; }`, `enum MiniGameType { collect, order, build, decorate, find }`; `kDiscoveryCards` (**21**, 3 per continent, params verbatim from `raw/cards-data.jsx`); `kWorldWonders` (**7**); `kWorldFacts` (ribbon facts).
- Produces (spot): `class SpotSceneSpec { final String name, emoji; final Color bg; final List<String> deco; final bool dark; }` + `kSpotScenes` (Picnic, Carnival, Aquarium, Beach, Space); `kSockLevels` (color → pattern → both); decoy pools; detective title ladder (`Junior Detective` → `Hidden Object Hero`).

- [ ] **Step 1: Failing tests**: counts (4 habitats, 8 ocean facts, 6 whales, 7 continents, 21 cards — 3 per continent, 7 wonders, 5 spot scenes); spot-check Sperm whale dive 2000 m vs Blue 200 m; every DiscoveryCard's `game.type` is a valid enum; every animal's `habitat` matches a habitat id.
- [ ] **Step 2:** FAIL → port → PASS + analyze. **Step 3: Commit** `feat: animal, world, and spot scene content`

---

## Phase 5 — Lands

**Shared rules for Tasks 27–33 (read carefully):**
- Read the land's wiki page AND raw jsx **before writing any code** — the wiki defines behavior, the raw file resolves ambiguity. Match prototype behavior exactly; do not invent new mechanics.
- Every land: entry screen is a game picker (grid of `WqButton`-style cards); every activity ends in `showRewardModal` (values below); back navigation to picker and map always available (top-left ← button, 64 px).
- Standard per-activity reward unless stated: `Reward(stars: 2, xp: 25)` plus the land's progress bump: `progressKey: <key>, progressTo: <percent of land content touched>` — compute as e.g. lettersMastered/26×100. Game-completion (a full GameDeck) additionally: `stars: 5, xp: 60, egg: true` every 3rd completed game.
- Narrate instructions via `TtsService.speak` when a game opens; `Sfx.ding` on right answers, `Sfx.wrong` + gentle shake animation on wrong (never punitive).
- Land screens live under `features/lands/<land>/`: `<land>_screen.dart` (picker) + one file per game. Register the land's `builder` in `content/lands.dart` (replacing the Task 16 placeholder).
- Tests per land: widget test that the picker renders all games and one behavioral test per game's core logic (specified below). UI polish is verified manually in the simulator at 1194×834.

### Task 27: Letter Adventure (progress key `letter`)

**Files:** `features/lands/letter_adventure/`: `letter_adventure_screen.dart`, `big_letters_game.dart`, `small_letters_game.dart`, `match_letters_game.dart`, `trace_letters_game.dart`, `reading_words_game.dart`; tests in `test/features/lands/letter_adventure/`.
**Read first:** `wiki/modules/letter-adventure.md`, `raw/letter2.jsx`, `raw/letter3.jsx`.
**Consumes:** `TraceCanvas`, `LevelSelect`/`GameDeck` (typeIds `big`, `small`, `match`, `trace`, `word`), `kEnglishLetters`, `kWordFamilies`, `kConfusables`, `kMatchOrder`, `TtsService.sayPhonics`.

5-game picker:
- [ ] **Big Letters** — LevelSelect 10 games × GameDeck over uppercase letters; each question: `TraceCanvas(glyph: letter.u)`; on covered → `sayPhonics(u, word)` + sparkle + advance; completing a letter calls `setLetterLearning(u)`; a letter traced in 2 different games → `setLetterMastered(u)`.
- [ ] **Small Letters abc** — grid of all 26 lowercase; tap → hear name/sound/picture word (`sayPhonics(l, word)`) + emoji pops; tracks visited set; all 26 visited → completion reward.
- [ ] **Match Big & Small** — GameDeck (`match`, 10×15) over `kMatchOrder`; prompt shows uppercase; 3 lowercase choices: correct + confusable (`kConfusables[l]`) + random; correct → advance.
- [ ] **Trace Letters** — like Big Letters but uppercase + lowercase side by side; both covered to advance.
- [ ] **Reading Words** — GameDeck (`word`, 10×15) over `kWordFamilies`; render `_AT` style blank + emoji; 4 draggable letter tiles (`miss` + `distract`); drop correct onset into blank → word flashes assembled, `speak("B… AT… BAT!")`, advance.
- [ ] **Behavioral tests:** match game shows the confusable as a choice for 'b' (expect 'd' present); reading words accepts correct drop and rejects wrong (word not assembled); big letters marks mastery after 2 games contain the letter.
- [ ] **Wire into lands.dart, analyze + test green, commit** `feat: letter adventure land`

### Task 28: Number Kingdom (progress key `number`)

**Files:** `features/lands/number_kingdom/`: `number_kingdom_screen.dart`, `count_match_game.dart`, `missing_number_game.dart`; tests alongside.
**Read first:** `wiki/modules/number-kingdom.md`, `raw/number.jsx`.
**Consumes:** `LevelSelect`/`GameDeck` (typeIds `count`, `missing`), `genCountRounds`/`genMissingRounds` (90-item pools, seeded per game), `setNumberMastered`.

- [ ] **Count & Match** — GameDeck 10×15 over count rounds: emoji group rendered scattered; tapping each object marks it counted (number badge appears on it, running tally spoken "1, 2, 3…"); then 4 number choices; correct → reveal animation + `setNumberMastered('$count')` + advance. Each object tappable exactly once (per-object hit state).
- [ ] **Missing Number** — GameDeck 10×15 over missing rounds: sequence tiles with gap; 3 choices; correct fills gap with pop.
- [ ] **Behavioral tests:** count game requires tapping all objects before choices activate; tally equals object count; missing-number correct choice fills the gap and advances.
- [ ] **Wire, analyze/test, commit** `feat: number kingdom land`

### Task 29: Little Math Lab (progress key `math`)

**Files:** `features/lands/math_lab/`: `math_lab_screen.dart` (station map), `math_station_game.dart` (shared runner), `station_theatrics.dart` (per-station intro/answer animations); tests alongside.
**Read first:** `wiki/modules/math-lab.md`, `raw/math.jsx`.
**Consumes:** `kMathStations`, `genMathProblems`, `LevelSelect`/`GameDeck` (typeId `math_<stationId>`, **4 games × 10 questions**), `DriftFieldWidget` (Cookie Math monkey), `Sfx`.

- [ ] **Station map** — 6 themed station cards; each opens LevelSelect(4) → GameDeck(10).
- [ ] **Shared runner** — objects-first pedagogy: render object groups; child taps to count (add: both groups; sub: remaining); answer choices (72 px+); **equation text (`2+2=4`) revealed ONLY after a correct answer**, big and celebratory.
- [ ] **Station theatrics** (one widget each, keep simple): Dino Snack Time — Rexy + two fruit groups; Treasure Hunt — chest built from rounded containers (domed lid, gold straps, lock) with gems on a velvet tray; Lost Dino Eggs — eggs shake → 💥 crack → baby dino pops on the subtracted ones; Cookie Math — monkey (`Art.glyph`) swings in on a vine (curved slide-in animation), eaten cookies fade to 15% opacity; More or Less — two groups, tap the side with MORE (or FEWER, alternating prompt).
- [ ] **Behavioral tests:** equation hidden before answer, shown after; sub problems never negative; More-or-Less prompt alternates and correct side advances.
- [ ] **Wire, analyze/test, commit** `feat: math lab land`

### Task 30: Spot Me If You Can (progress key `find`)

**Files:** `features/lands/spot_me/`: `spot_me_screen.dart` (9-game dashboard), `hidden_object_game.dart`, `socks_game.dart`, `count_it_game.dart`, `detective_game.dart` (letter/number/shape/animal/color variants via config), `spot_difference_game.dart`; tests alongside.
**Read first:** `wiki/modules/spot-me.md`, `raw/spot.jsx`, `raw/spot-data.jsx`.
**Consumes:** `SpotScene` widget + engine, `kSpotScenes`, `kSockLevels`, `kEnglishLetters`, detective title ladder.

- [ ] **Hidden Object Hunt** — themed `SpotScene` rounds with multi-goal missions (e.g. 3 bees + 2 butterflies + 4 apples), goals from `raw/spot-data.jsx`; rounds advance with increasing decoys.
- [ ] **Match the Socks** — 3 levels (color → pattern → both); socks drawn with `ClipPath` shapes; tap the two matching socks in a grid.
- [ ] **Count It If You Can** — `SpotScene` in `SpotMode.count`.
- [ ] **Detective games (4 configs, one widget)** — `DetectiveConfig { target chooser, decoy pool, title }` for Letter (target letter among confusable look-alikes, incl. lowercase), Number, Shape (Flutter-drawn triangle/circle/star/square via CustomPaint), Animal, Color Quest (find all objects of a color).
- [ ] **Spot the Difference** — build scene A via engine `place()`, copy to B with ONE item swapped/moved/removed; render side by side; tap the changed item in B.
- [ ] **Detective titles**: track total finds in-memory per session + stars; award title stickers at thresholds via `Reward(sticker: title)`.
- [ ] **Behavioral tests:** difference generator produces exactly one differing item; detective config generates ≥1 target and 0 false targets in decoys; sock level 3 requires both color AND pattern match.
- [ ] **Wire, analyze/test, commit** `feat: spot me land`

### Task 31: Amazing Animal Planet (progress key `animal`)

**Files:** `features/lands/animal_planet/`: `animal_planet_screen.dart`, `animal_homes_game.dart`, `fun_facts_game.dart`, `under_the_sea_screen.dart`, `ocean_facts_game.dart`, `whale_world_screen.dart`; tests alongside.
**Read first:** `wiki/modules/animal-planet.md`, `raw/animal.jsx`, `raw/sea.jsx`.
**Consumes:** `FlipCard`, `kAnimals`/`kHabitats`/`kOceanFacts`/`kWhales`, `SaveController.animalsFound` (via `apply(Reward(animal: name))`), `Sfx.whaleLow/whaleHigh`, `TtsService`.

- [ ] **Animal Homes** — 4 habitat drop zones + a queue of draggable animal chips; `Draggable`/`DragTarget` with overlap test; correct drop → fact spoken + chip settles; wrong → bounce back.
- [ ] **Fun Facts** — grid of `FlipCard`s (front: emoji + name + "Tap for fact"); flip → fact spoken + `Reward(animal: name, silent: true)` adds to collection book; a collection-book button shows found animals.
- [ ] **Under the Sea** — submenu: Ocean Facts (8 tappable creatures, fact spoken + highlight) and Whale World: gallery of 6 whale cards — emoji + name, fact, dive-depth meter (vertical bar scaled 0–2000 m, animated fill), "🔊 Hear its call" → `Sfx.whaleLow` for Blue/Sperm/Humpback, `whaleHigh` for Beluga/Orca/Narwhal.
- [ ] **Behavioral tests:** wrong-habitat drop does not settle; flip adds animal exactly once to `animalsFound`; dive meter width/height proportional to `diveM/2000`.
- [ ] **Wire, analyze/test, commit** `feat: animal planet land`

### Task 32: Around the World (progress key `world`)

**Files:** `features/lands/around_the_world/`: `world_map_screen.dart`, `travel_animation.dart`, `continent_screen.dart`, `find_mission.dart`, `discovery_cards_screen.dart`, `mini_games.dart` (5 types), `passport_screen.dart`; tests alongside.
**Read first:** `wiki/modules/around-the-world.md`, `raw/world.jsx`, `raw/world2.jsx`, `raw/cards.jsx`, `raw/cards-data.jsx`.
**Consumes:** `kContinents`/`kDiscoveryCards`/`kWorldWonders`, `SpotScene` (find missions + find mini-game), `DriftFieldWidget` (collect mini-game), `FlipCard` (cards + wonders), `world` save state (`visitContinent`, `collectDiscoveryCard`).

- [ ] **World map** — 7 tappable stylized continent blobs (rounded `CustomPaint`/stacked containers per prototype layout — approximate shapes, exact positions from `raw/world.jsx`); Passport button with `N/7` stamp count.
- [ ] **Travel animation** — ~6 s sequence (plane over clouds/ocean, `AnimationController`), narrated "Welcome to Africa!"; then continent page. Skippable by tap (small "Skip ▸").
- [ ] **Continent page** — themed colors; rotating world-fact ribbon (timer, 6 s); 6-animal grid (tap → fact spoken); "🔍 Find mission" and "🎴 Discovery Cards" buttons; `visitContinent(id)` on first arrival.
- [ ] **Find mission** — `SpotScene` with the continent's mission goals; complete → stamp + badge + World Wonder card + `Reward(stars: 5, xp: 60, progressKey: 'world', ...)`.
- [ ] **Discovery Cards** — 3 `FlipCard`s per continent; flip → narrated fact → launches the card's mini-game (`MiniGameSpec`); win → `collectDiscoveryCard(id)` + card marked collected (own celebration → use `silent: true` rewards).
- [ ] **Mini-games (5 shared widgets in `mini_games.dart`):** collect (`DriftFieldWidget`), order (tap items smallest→largest; tapped-in-wrong-order shakes), build (tap stack pieces bottom→top slot into silhouette), decorate (tap 6 glowing spots to place items), find (mini `SpotScene`).
- [ ] **Passport** — album: 7 stamp slots (filled/empty), discovery points, 7 wonder cards (tap → narrated).
- [ ] **Behavioral tests:** first visit sets `world.visited`; find-mission completion grants a stamp exactly once; card win persists in `world.discovery`; order mini-game rejects out-of-order taps.
- [ ] **Wire, analyze/test, commit** `feat: around the world land`

### Task 33: Hoorof — Arabic letters (progress key `arabic`)

**Files:** `features/lands/hoorof/`: `hoorof_screen.dart` (8-game picker + cluster select), `learn_letter_game.dart`, `trace_letter_game.dart`, `hear_match_game.dart`, `memory_match_game.dart`, `find_letter_game.dart`, `shape_builder_game.dart`, `letter_pop_game.dart`, `safari_hunt_game.dart`; tests alongside.
**Read first:** `wiki/modules/hoorof.md`, `raw/hoorof.jsx`, `raw/hoorof-data.jsx`, **and Task 3's `wiki/requirements/arabic-tts-spike-result.md`** — if the spike said "bundle recorded audio", add `assets/audio/arabic/<letter>.m4a` playback through `SfxService`-style player instead of `speakArabic` for letter names (keep `speakArabic` for words).
**Consumes:** `kArabicLetters`/`kArabicConfusableFamilies`/`kArabicClusters`, `TraceCanvas` (fontFamily: 'NotoNaskhArabic'), `SpotScene`, `TtsService.speakArabic`.
**Reminder (Global Constraints):** UI chrome in English, LTR layout; only glyphs/words in Arabic script.

- [ ] **Cluster select** — letters taught in the prototype's 3–4-letter clusters; picker shows clusters with progress.
- [ ] **Learn the Letter** — giant tappable glyph (wobble on tap) + `speakArabic(nm, tr)`; example word + emoji + `speakArabic(w, wtr)`.
- [ ] **Trace the Letter** — `TraceCanvas(glyph: g, fontFamily: 'NotoNaskhArabic')`; covered → sparkle/confetti + name spoken.
- [ ] **Hear & Match** — plays letter name; 3 glyph choices: correct + 2 from the SAME confusable family; correct → advance.
- [ ] **Match the Letters** — memory pairs (glyph ↔ glyph) using `FlipCard`, 8 cards face-down.
- [ ] **Find the Letter** — `SpotScene` with target glyph among same-family look-alikes.
- [ ] **Shape Builder** — show dotless `base`; 3 dot-option buttons labeled in English ("2 dots above", "1 dot below"…); correct option animates dots onto base forming the letter + name spoken.
- [ ] **Letter Pop** — balloons (colored circles + string) float up (`Ticker`); called letter announced; pop the matching balloon (`Sfx.pop`); wrong balloon wiggles.
- [ ] **Safari Letter Hunt** — desert/oasis-themed `SpotScene` (bg `#FFC53D`→sand tones, palm/cactus deco) letter hunt.
- [ ] **Progress**: letters interacted-with across ≥3 games → count toward `progress.arabic` (n/28 × 100).
- [ ] **Behavioral tests:** hear&match choices all come from one confusable family; shape builder only accepts the letter's dots code; find-letter decoys are same-family; cluster progress math.
- [ ] **Wire, analyze/test, commit** `feat: hoorof arabic land`

---

### Task 34: Parent dashboard (real)

**Files:**
- Replace placeholder: `app/lib/features/parent/dashboard_screen.dart`
- Test: `app/test/features/parent/dashboard_test.dart`
- Read first: the dashboard spec in `wiki/specs/`, `raw/parent.jsx`, `wiki/requirements/decisions-2026-07-01.md` (summary-stats-only + separate Arabic metric)

**Interfaces:**
- Consumes: everything in `SaveData` (all metrics derive from the save — NO event log exists, by decision).
- Produces: a calmer-styled (white cards on `WqColors.backgroundAlt`, smaller type) scrollable screen with sections:

1. **Top stats row** — minutes today (vs goal 20), streak days, letters mastered `n/26`, numbers mastered `n/20`.
2. **Alphabet mastery grid** — A–Z tiles colored: green = in `lettersMastered`, yellow = in `lettersLearning`, gray = neither.
3. **Arabic mastery grid** — same treatment over the 28 Arabic letters, driven by `progress.arabic` count (tiles green up to the mastered count) — the separate-Arabic-metric decision.
4. **This week** — 7-day minutes bar chart (`week` list, custom-painted bars, Mon–Sun labels).
5. **Skill progress bars** — one per progress key: Letters, Arabic, Numbers, Math, Animals & World (avg of animal+world), Finding & Focus.
6. **Coach notes** — rule-derived strings (no ML): lowest 2 progress keys → "Practice ideas"; any confusable letter in `lettersLearning` for both of a pair (b/d) → flag it; top progress key → a "win" line.
7. **Readiness ring** — overall % = mean of all 7 progress keys, painted arc, "GSRP Ready" label at ≥80.

- [ ] **Step 1: Failing widget tests** with a seeded save (5 letters mastered, arabic 50, week [5,10,0,0,0,0,0]): expect '5/26', an alphabet grid with 5 green tiles, arabic section present, readiness % text equals computed mean.
- [ ] **Step 2:** FAIL → implement → PASS + analyze.
- [ ] **Step 3:** Manual simulator pass behind the parent gate. **Commit** `feat: parent dashboard`

---

### Task 35: Release readiness (TestFlight)

**Files:**
- Create: `app/assets/icon/icon.png` + launcher config, `wiki/requirements/app-store-artifacts.md`, `README.md` (repo root)
- Modify: `app/pubspec.yaml`, iOS project settings
- Read first: `wiki/requirements/decisions-2026-07-01.md` §distribution

- [ ] **Step 1: App icon** — 1024×1024: Rexy-orange (`#FF8A3D`) rounded background, big "WQ" in Baloo 2 white with a small star; generate programmatically with a Dart script (`tool/gen_icon.dart`, reuse the WAV task's file-writing pattern but emit PNG via `dart:ui` `PictureRecorder`→`toImage`→`toByteData(png)`); apply with `flutter_launcher_icons` dev package.
- [ ] **Step 2: iOS config** — display name "Wonder Quest"; verify bundle id (final value is the owner's call at upload time — leave `com.hussain.wonder_quest` and note it in the artifacts page); build number scheme; `flutter build ios --release --no-codesign` succeeds.
- [ ] **Step 3: Privacy & store artifacts page** — write `wiki/requirements/app-store-artifacts.md` (Status: spec-only) with the publish checklist: privacy policy URL (one-page static site; app collects NO data, all local — include ready-to-publish policy text in the page), App Privacy questionnaire answers ("Data Not Collected"), Kids Category checklist (no ads ✓, no external links ✓, no purchases ✓, parental gate ✓), age rating 4+, required iPad screenshot sizes (12.9" 2048×2732 landscape → 2732×2048, 11"), name/subtitle/description/keywords draft, and the manual QA script: fresh install → play one activity per land in airplane mode → force-quit → relaunch → verify progress persisted → parent gate → dashboard reflects play → reset works.
- [ ] **Step 4: README.md** — one screen: what Wonder Quest is, `cd app && flutter run`, wiki is the source of truth, plan location, test command.
- [ ] **Step 5:** `flutter analyze` + `flutter test` green across the whole app. Append `wiki/log.md`: "v1 implementation complete per plan". **Commit** `chore: release readiness — icon, store artifacts, README`

---

## Execution Notes for the Orchestrator

- **Dispatch one subagent per task**, giving it: this plan's path + its task number, and nothing else — each task names its own reading list. Tasks are self-contained on purpose; do not let a subagent "helpfully" start the next task.
- **Model guidance:** Tasks 4–12, 18–26 (pure Dart/domain/content) suit a lower-powered model. Tasks 13–17, 27–34 (widget-heavy, multi-file) benefit from a mid-tier model. Task 3 needs a human with an iPad for Step 2 — the executor implements, the human verifies.
- **Parallelism:** within Phase 4, Tasks 23–26 are fully independent. Within Phase 5, all seven land tasks are independent of each other (they share only phase 0–4 outputs) — run up to 3 in parallel on separate worktrees if desired, merging after review.
- **Review gate between tasks:** run `flutter analyze && flutter test` yourself before accepting a subagent's task as done; reject commits with failing checks.
- **If the prototype contradicts this plan** on a behavioral detail, the prototype + wiki win; note the divergence in `wiki/log.md`.
- **Scope discipline:** locked lands, cloud sync, real illustrations, recorded English audio, portrait/phone layouts are all OUT of v1. If a task seems to need one, stop and surface it.

## Verification (definition of done for v1)

1. `cd app && flutter analyze` → 0 issues; `flutter test` → all green.
2. Manual QA script from Task 35 passes on a real iPad **in airplane mode**.
3. Every land playable end-to-end; every activity ends in a reward; progress bars move; dashboard reflects play; save survives force-quit; parent gate blocks a 5-year-old.



