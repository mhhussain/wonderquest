# Module: Letter Adventure (English)

**Purpose**: Core English literacy — letters, sounds, lowercase mastery, reading readiness.
**Status**: prototype-validated.

## Structure
A 5-game picker. Each game card opens a **"Pick a Game" level screen of 10 games × 15 questions** (dealt by the level-dealer; no repeat within a game, ≤2× across games when the pool allows). See `systems/game-engines.md`.

## Games
1. **Big Letters** — all 26 uppercase. Child **traces** the letter (finger/Pencil); on completion a sparkle + **phonics callout**: "C… cuh, cuh… Cat!" with picture word.
2. **Build a Small Letters abc** *(headline lowercase skill)* — every uppercase shown beside its lowercase partner (A→a) on colorful cards; tap to hear name + sound + picture word; tracks all 26 with celebration.
3. **Match Big & Small** — show uppercase, tap correct lowercase from 3 choices; ramps easy→tricky using **confusable families** (b/d, p/q, g/q, m/w). Correct = "🦖 Yay!" cheer.
4. **Trace Letters** — uppercase + lowercase **side-by-side** on one canvas; wiggle/sparkle + sound on finish.
5. **Reading Words** — sees a picture (🐱), drags the missing first letter into `_AT`; word families `_AT,_AD,_ED,_OG,_UN,_OCK,_EN…`; **two-letter blends** (FR, TR, SN) for harder levels. Pool = 75 unique words (55 single-letter + 20 blends).

## Content
- Alphabet data: glyph, picture word, emoji, beginning-sound phonics. Example: "P is for Piano 🎹" (changed from Pig per request). Reading Words "PEN" (🖊️→`_EN`).
- Confusable-letter families drive distractors.

## Rewards
Stars, XP, dino eggs, letter-themed stickers; feeds `progress.letter` → parent dashboard alphabet grid.

## Native rebuild notes
- Tracing = pointer/canvas → use Flutter gesture system + CustomPaint (Impeller rendering) with stroke-coverage threshold to gate "done".
- Phonics audio currently TTS; production = recorded phoneme + word clips.
- See `specs/content-data-model.md` for data shapes; `modules/hoorof.md` is the Arabic parallel.
