# System: Audio & Speech

**Purpose**: Narration, phonics, and sound effects.
**Status**: prototype-validated (placeholder-quality audio).

## English narration & phonics
`speak(text, {rate,pitch})` via **Web Speech API** (SpeechSynthesis). Helpers: `sayPhonics(letter,word)` → "buh. bat!"; `sayLetterSound`. Used everywhere for instructions, letter sounds, counting ("1, 2, 3…"), encouragement. Honors a global **sound toggle** (`state.soundOn`).

## Arabic narration
`speakArabic(arabic, fallback)` selects an `ar-*` TTS voice; **falls back to English transliteration** if no Arabic voice is installed (avoids mispronunciation). `sayLetter(h, withWord)`.

## Synthesized SFX
**Whale calls** built with **Web Audio API** oscillators (per-whale base frequency + LFO vibrato + gain envelope) — distinct "voices" (blue whale low, beluga high). Placeholder for real recordings.

## Reality / production gap
All audio is **device TTS + synthesized tones**. Production should add **recorded audio**: native Arabic letter sounds, clean English phoneme/word clips, real animal & whale sounds, music/ambience. Voice-over reading of instructions recommended (Hassan can't read yet).

## Native rebuild notes
- iOS has `AVSpeechSynthesizer` (Flutter: flutter_tts) — quality varies; prefer bundled recorded clips for core phonics.
- Bundle an **audio asset map** keyed by letter/word/animal; lazy-load.
- Keep a single `audio` service honoring the global mute and ducking music under narration.
