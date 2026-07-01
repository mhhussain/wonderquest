# Requirements — Native Mobile App (Flutter / iPad)

**Purpose**: Consolidated, build-facing requirements derived from the validated prototype + brief.
**Status**: prototype-validated baseline + open questions for architecture.

## Platform
- Target **iPad, landscape**, Apple **Pencil** + touch. (Phone/portrait later — TBD.)
- **Flutter** (Dart). Recommended: Flutter's built-in animation & gesture systems, CustomPaint + Impeller (canvas rendering; consider Flame engine for game loops), shared_preferences or Hive (storage), lottie Flutter package (celebrations), just_audio/audioplayers (audio), flutter_tts (speech).
- Offline-first, **no ads, no external links, child-safe**, parent-gated settings.

## Functional requirements
1. **Home Expedition Map** with 13 lands (7 built, 6 locked), HUD (level/XP/streak/stars/eggs/sound/parent), mascot tips.
2. **Modules** as documented in `modules/*` — port behaviors, content, and rewards faithfully.
3. **Reusable engines** (`systems/game-engines.md`): level-dealer, TraceCanvas, SpotScene, drag-collect & card engines, flip card, sorting drag.
4. **Reward economy** (`systems/rewards-gamification.md`): XP/levels, stars, eggs+hatching, stickers, animal book, badges, streaks, collections modal.
5. **Audio** (`systems/audio-speech.md`): narration everywhere, phonics, Arabic TTS w/ fallback, SFX; global mute.
6. **Persistence** (`systems/state-persistence.md`): profile/economy, per-game levels, world state; versioned + migratable.
7. **Parent dashboard** (`specs/parent-dashboard.md`) with parent gate; add per-attempt event logging for real analytics.
8. **Content-data driven** so "hundreds of activities" generate from compact data + engines.

## Non-functional
- 15–20 min session ergonomics: fast load, every activity ends in reward, easy land-switching.
- Accessibility: large hit targets (≥44px), high-contrast text, audio-first for pre-readers, reduced-motion safe.
- Performance: 60fps drag/scene interactions on iPad.

## Production content gaps (sourcing needed)
- Real **illustration sets** (scene art for Spot Me/continents; characters: Rexy, mascots; treasure/eggs).
- Recorded **audio**: native Arabic letters, English phonics/words, animal + whale sounds, music.
- Real **whale photos/videos** (licensing) or replace with illustration.

## Build-order candidates (post-architecture)
1. Foundation: theme, navigation, HUD, reward/economy store, persistence, audio service, engines.
2. Port built modules (start Letter Adventure + Number Kingdom — closest to core goals).
3. Then Math Lab, Animal Planet, Around the World, Spot Me, Hoorof.
4. New: Reading Readiness (rhyming/sight words), Dino Discovery, Pattern Detective, Daily Search Challenge.

## Open questions (❓ resolve in architecture phase)
- Single child vs **multi-profile**?
- **Portrait / iPhone** support?
- Cloud account/sync & weekly-report delivery, or fully on-device?
- Separate **Arabic progress** metric in dashboard?
- Real-art pipeline & budget; audio recording plan?
- Analytics depth (summary fields vs full event log)?
- Parental gate mechanism & settings scope?
