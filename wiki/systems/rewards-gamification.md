# System: Rewards & Gamification

**Purpose**: The reward economy that motivates a 5-year-old across a summer.
**Status**: prototype-validated.

## Layered rewards (all persisted)
- **XP & Levels** — `xp`, `level`; `xpForLevel(lvl)=100+(lvl-1)*60`. Awards roll over and can multi-level-up.
- **Stars** — `stars` currency from completing activities.
- **Dino Eggs** — `eggs`; hatch into a **collection** of named dinos (Bronto, Rexy, Stego…).
- **Stickers** — themed per module, into a sticker book.
- **Animal collection book** — animals discovered in Animal Planet.
- **Badges** — streaks, star milestones, per-module mastery, level, "GSRP Ready".
- **Streak** — `streak` day count.
- **World**: continent stamps, discovery points, World Wonder cards, collected Discovery Cards.

## Award flow
`applyReward(state, {stars,xp,egg,sticker,animal,progressKey,progressTo,silent})` returns a state patch (handles level-ups, dedupes stickers/animals, bumps `progress[key]`, +1 `minutesToday`). Most activities then show a **RewardModal** (confetti + reward pills); some pass `silent:true` (e.g. Discovery Cards have their own celebration and return to the deck).

## Progress keys
`progress.{letter,number,math,animal,world,find}` (0–100) drive the parent dashboard and land progress bars. > ❓ add `arabic`, `reading`, `shapes` keys as modules grow.

## Collections UI
A "Treasure Chest" modal with tabs: Dino Eggs, Animal Book, Stickers, Badges.

## Design intent
Short-session friendly: every ~2–4 min activity ends in a visible reward. Layered systems give many "things to collect more of" (per the parent's request for all reward types).

## Native rebuild notes
Model as a single persisted **profile/economy store** (see `systems/state-persistence.md`). Keep award logic pure/centralized for testability. Consider server sync only if multi-device — currently single-device local.
