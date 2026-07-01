# Module: Number Kingdom

**Purpose**: Number recognition, counting, number order.
**Status**: prototype-validated.

## Structure
2-game picker → each opens a **10 games × 15 questions** level screen (level-dealer, 90-item generated pools so each question repeats ≤2× total). See `systems/game-engines.md`.

## Games
1. **Count & Match** — a group of objects (varying emoji per round); child **taps each to count** (numbers appear on each), then picks the matching number from 4 choices; reveal animation. Counts ramp up.
2. **Missing Number** — a sequence with a gap (e.g. 3,4,_,6,7); pick the missing number from 3 choices; longer sequences later.

## Rewards
Stars, XP, dino eggs, number stickers; feeds `progress.number` → parent dashboard.

## Native rebuild notes
- Count-tap interaction needs per-object hit state + running tally.
- Pools are generated at runtime (see dealer); keep deterministic seeding if you want reproducible "games".
