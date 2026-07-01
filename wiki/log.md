# Log

Append-only. Format: `## [date] type | summary`.

## [2026-06-13] init | Wiki created from validated HTML prototype
Captured the Wonder Quest prototype (formerly "Dino Dig", working title "Hassan's Summer Ed App") into a structured knowledge base to seed the native (Flutter / iPad/tablet) build. Documented: 7 built modules, 6 locked/spec modules, 6 cross-cutting systems, curriculum + content data model + parent dashboard specs, and consolidated mobile requirements. All "built" pages reflect features verified in the prototype across the session.

Key state at handoff:
- Built & verified: Letter Adventure (EN), Hoorof (AR letters, EN UI), Number Kingdom, Little Math Lab, Animal Planet (+Under the Sea/Whale World), Around the World (+Discovery Cards/Passport), Spot Me If You Can (9 detective games).
- Shared systems: layered rewards, level-dealer (N games × M questions, dedupe), drag-collect engine, SpotScene scatter engine, TTS phonics + synthesized whale audio, localStorage persistence, fixed-canvas scaling inside an iPad frame.
- Art approach: emoji + labeled placeholders/image-slots stand in for illustrations; real art/audio to be sourced for production.

Next: define architecture & tech stack, then implementation plans, building adjacent to this wiki.

## [2026-07-01] decision | Rebuild target changed from React Native to Flutter
Native rebuild now targets **Flutter (Dart)** for iPad/tablet instead of React Native. Updated all wiki pages to reflect Flutter equivalents: gesture handling (Flutter's built-in GestureDetector), animations (Flutter's Animation API), canvas (CustomPaint + Impeller; Flame for game loops), state persistence (Hive/shared_preferences instead of MMKV), audio (flutter_tts, just_audio/audioplayers), and Lottie animations (lottie Flutter package). Kept all module/system "Native rebuild notes" sections, reframed for Flutter tooling.

## [2026-07-01] decision | App renamed to Wonder Quest; architecture & scope decisions
App officially renamed from working title "Dino Dig" to **Wonder Quest**. Updated all wiki pages to reflect new name (kept file-path reference to prototype file `Dino Dig.html` unchanged as immutable source). Recorded 15 key architectural & scope decisions in `requirements/decisions-2026-07-01.md` from design grilling session, covering: tech stack (Flutter + CustomPaint, no Flame; Riverpod state; flutter_tts audio), platform (iPad landscape tablet-first, phones deferred), connectivity (fully offline, no accounts), persistence (one versioned JSON save file, atomic writes), v1 scope (7 playable lands + rewards + parent dashboard, 6 locked lands deferred), art/audio approach (emoji+placeholders behind asset-lookup layer), parental controls (multiplication gate), analytics (local summary stats only), parent dashboard (dual-language Arabic/English metrics), distribution (TestFlight → App Store), testing (TDD-focused unit tests), and first coding task (flutter_tts Arabic spike on iPad). All decisions span product, platform, scope, architecture, distribution, and testing.
