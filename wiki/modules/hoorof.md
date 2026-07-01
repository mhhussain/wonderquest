# Module: Hoorof — Arabic Letters (حروف)

**Purpose**: Arabic letter recognition/sounds, parallel to Letter Adventure.
**Status**: prototype-validated.

## Key UX decision
**Only the Arabic letter glyphs (and example words, with transliteration) are in Arabic; ALL UI chrome is English** (titles, buttons, instructions, dot labels). Layout is LTR. Letter names shown as transliteration ("Alif", "Baa"); 🔊 still pronounces Arabic.

## Coverage
All **28 letters**, taught in gentle clusters of 3–4 (isolated forms first — no connected-word reading yet). Each letter: glyph `g`, Arabic name `nm`, transliteration `tr`, sound `snd`, example word `w` + translit `wtr` + emoji `e`, and (where relevant) dotless `base` + `dots` code.

## 8 games
1. **Learn the Letter** — giant tappable glyph, hear name, wobble, example word.
2. **Trace the Letter** — dotted Arabic glyph tracing, sparkle/confetti.
3. **Hear & Match** — audio plays a letter; tap correct of **3** choices (distractors from confusable family).
4. **Match the Letters** — face-down memory game.
5. **Find the Letter** — hidden-letter hunt (reuses SpotScene) among look-alikes.
6. **Shape Builder** — add correct dots to a dotless base to build ب/ت/ث; dot options labeled "2 dots above" etc.
7. **Letter Pop** — pop the floating balloon with the called letter.
8. **Safari Letter Hunt** — desert/oasis themed letter hunt.

## Confusable families
ب/ت/ث/ن/ي · ج/ح/خ · د/ذ · ر/ز · س/ش · ص/ض · ط/ظ · ع/غ · ف/ق — used for distractors and Shape Builder.

## Audio
`speakArabic(arabic, fallback)` picks an Arabic TTS voice (`ar-*`); if none installed, falls back to English transliteration rather than mispronouncing.

## Native rebuild notes
- Production needs **recorded native-speaker letter audio** (TTS quality/availability varies on device).
- Arabic-capable font required for glyphs and dotless base forms (ٮ ٯ ڡ etc.).
- Rewards feed `progress.letter` (shared with English letters) — consider a separate Arabic progress key for the parent dashboard. > ❓ separate AR progress metric?
