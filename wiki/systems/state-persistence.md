# System: State & Persistence

**Purpose**: How progress is saved.
**Status**: prototype-validated (localStorage; replace for native).

## Stores (prototype = localStorage)
- **`dinodig_v1`** — main profile/economy: `name, xp, level, stars, eggs, streak, soundOn, hatched[], stickers[], animalsFound[], lettersMastered[], lettersLearning[], numbersMastered[], progress{letter,number,math,animal,world,find}, minutesToday, week[7]`.
- **`dinodig_levels`** — per-game-type completion map: `{ typeId: [bool×games] }` (e.g. `big`, `match`, `count`, `math_eggs`, `word`).
- **`dinodig_world`** — Around-the-World state: `visited{}`, passport/discovery points, `discovery{cardId:true}` collected cards.

## Patterns
- Load with defaults merge on boot; write on every state change.
- Reward application is centralized (`applyReward`) so saves stay consistent.
- Playback/position-style persistence not needed (host keeps no media position); collections/levels persist so refresh keeps place.

## Native rebuild notes
- Replace localStorage with **shared_preferences / Hive / SQLite** (Hive recommended for speed; SQLite if querying analytics).
- Define a **versioned schema + migrations** (prototype already uses `_v1` suffix).
- Consider **multiple child profiles** for production. > ❓ single child (Hassan) vs multi-profile.
- Parent dashboard reads aggregate fields (`week`, `minutesToday`, mastery arrays, `progress`) — ensure the data model captures **per-skill events** if richer analytics are wanted (see `specs/parent-dashboard.md`).
