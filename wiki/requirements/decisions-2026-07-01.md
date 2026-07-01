# Architecture Decisions — 2026-07-01

**Purpose**: Record key architectural and scope decisions from design grilling session.
**Status**: spec-only.

## Product & branding
- **App name**: Wonder Quest (formerly "Dino Dig", working title "Hassan's Summer Ed App").
- **Bundle ID pattern**: com.`<family>`.wonderquest — to be chosen once (e.g., com.ideaspark.wonderquest).

## Technology stack
- **Framework**: Flutter (Dart).
- **UI**: Plain widgets + CustomPaint (no Flame engine for v1).
- **State management**: Riverpod for cross-cutting concerns (rewards, profiles, game results); setState permitted inside mini-game widgets.
- **Audio**: flutter_tts (on-device TTS, no network required).
- **Persistence**: Hive or shared_preferences for local JSON save file (see below).

## Profiles & player identity
- **v1 scope**: Single child profile (Hassan).
- **Future-proofing**: All saves keyed under a `profileId` UUID for future multi-profile support (multiple children).

## Device & UI canvas
- **Target devices**: iPad (landscape) as first-class platform; Android tablet code kept clean but not tested/shipped v1.
- **Design canvas**: Fixed 1024×600px (or native iPad landscape resolution) with letterbox scaling.
- **Phones out of scope**: No portrait orientation, no phone testing in v1.

## Connectivity & data
- **Offline-first**: No accounts, no login, no network required to play.
- **Assets**: All art, audio, and fonts bundled in APK/app.
- **Audio delivery**: flutter_tts for English/Arabic phonics + text-to-speech; fallback to bundled pre-recorded Arabic letter sounds if TTS unreliable on device.

## Persistence
- **Save model**: One versioned JSON save file per profile in app documents directory.
- **Atomic writes**: Write to temp file, then rename (prevent corruption on crash).
- **Schema versioning**: Include version number for safe migrations when structure changes.
- **No database**: Flat JSON only; no SQLite, Hive key-value trees beyond config.

## Scope: v1 feature set
- **Playable lands**: 7 prototype-validated modules (Letter Adventure, Hoorof, Number Kingdom, Little Math Lab, Animal Planet, Around the World, Spot Me If You Can).
- **Rewards**: Full reward system (XP, levels, stars, eggs, stickers, badges, streaks).
- **Parent dashboard**: Analytics view + parental gate (multiplication question) before access or settings changes.
- **Locked lands**: 6 spec-only modules (Dino Discovery, Earth Explorer, Maze World, Tracing Studio, Pattern Detective, Reading Readiness) deferred to v2+.

## Art & audio for v1
- **Placeholder art approach**: Emoji-as-art + simple Flutter shapes for UI; labeled image-slots for scene illustrations.
- **Art layer abstraction**: Single asset-lookup layer (interface) so production can swap placeholder emoji for real SVG/PNG illustrations without touching game code.
- **Audio**: flutter_tts English/Arabic phonics + synthesized creature sounds (e.g., whale calls) for v1; real recorded audio sourced later.
- **Audio layer abstraction**: Parallel asset-lookup interface for easy swap to recorded audio files.

## Parental controls & safety
- **Parental gate**: Multiplication question (e.g., "3 × 4 = ?") before parent dashboard or settings access.
- **Child-safe by default**: No ads, external links, or in-app purchases in v1.

## Analytics & telemetry
- **Local summary stats only**: Per-skill mastery (% correct per letter/number/math concept), per-land session totals, streak counts.
- **No event log**: No fine-grained event telemetry; no third-party analytics (Firebase, Mixpanel, etc.).
- **Data stays local**: All stats computed and stored in the JSON save file, never uploaded.

## Parent dashboard
- **Dual-language reporting**: Separate Arabic (Hoorof) progress metric alongside English literacy, numeracy, world knowledge.
- **Metrics**: Mastery by skill, time spent, session history, areas to practice (low-mastery skills), current streak.

## Distribution & publishing
- **Beta**: TestFlight (account exists); invite Hassan's parent as tester.
- **Public release**: App Store later (post-v1 stabilization).
- **Publishing artifacts required**:
  - **Privacy policy URL**: Static page stating "no data collected" (or minimal local stats only).
  - **App Privacy labels**: COPPA/Kids Category compliance (age 5 → 4+ rating minimum).
  - **Kids app category**: Apple App Store kids category section.
  - **App icon**: 1024×1024px (or generated set).
  - **iPad screenshots**: Landscape, showing multiple lands/rewards.
  - **Age rating**: PEGI 4+ / Apple 4+ minimum.

## Testing strategy
- **Unit tests (TDD)**: Pure-Dart tests for game engines, reward logic, save-file serialization/migration, skill mastery calculation.
- **Widget tests**: Light coverage for critical flows (launch → pick land → play game → see reward → return to map).
- **No golden tests** in v1 (screenshot regression tests deferred).
- **Manual testing**: Full playthrough on real iPad before each beta build.

## First coding task
- **Spike**: Test flutter_tts Arabic speech output on real iPad in airplane mode (offline TTS engine).
- **Success criterion**: Arabic letter names (حروف) pronounced clearly and audibly via TTS.
- **Fallback plan**: If TTS unreliable, substitute bundled pre-recorded Arabic letter audio files (one .wav/.m4a per letter).
- **Outcome**: Pick one approach, document in `systems/audio-speech.md` Native rebuild notes, then unblock game-engine builds.

## Code organization
- **Entry point**: `app/` folder at repo root (e.g., `/app/lib/main.dart`).
- **Parallel wiki**: This wiki (`wiki/`) documents prototype behavior; rebuild code follows Flutter conventions (lib/features/, lib/domain/, etc.) but cross-references the wiki for game logic specs.

## Open threads
- Bundle ID family name (com.`<family>`.wonderquest) to be chosen in first sprint planning.
- Real art and audio sourcing schedule (TBD by product owner).
- Exact COPPA compliance checklist (to be refined with legal/publishing).
