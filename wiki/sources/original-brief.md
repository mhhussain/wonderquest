# Source: Original Brief & Session Decisions

**Purpose**: Captured source material — the founding brief and key decisions made while building the prototype.
**Status**: prototype-validated.

## Founding brief (summary)
Design a complete iPad app for **Hassan, 5**, for the whole summer to prep for **Michigan GSRP**. Must **not feel like schoolwork** — a fun game (PBS Kids / Khan Academy Kids / ABC Mouse / Duolingo-style progression). Interaction-first (tap, drag, trace, circle, match, draw w/ Pencil, find, puzzles); avoid passive video. Sections requested: Letter Adventure, Number Kingdom, Little Math Lab, Dino Discovery World, Amazing Animal Planet, Around the World, Earth Explorer, Where's Hassan? (hidden object), Maze World, Creative Tracing Studio, Pattern Detective, Reading Readiness. Gamification: streaks, XP, levels, badges, dino-egg rewards, animal collection, unlockable worlds, celebrations; no ads/links; child-safe. **Parent dashboard** with mastery/time/weekly reports/areas-to-practice.

## Confirmed direction (from intake Q&A)
- Deliverable: **clickable hi-fi prototype** (dashboard + several playable activities).
- Vibe: **bright & playful**; theme: **dinosaur explorer / little paleontologist**.
- Palette: orange/teal/green (bright kid set). **Landscape**. Characters: emoji/shapes for UI + placeholders for scene art.
- Rewards: **all types layered**. Parent dashboard: **yes**. Audio: text+icons, **audio as voiced bonus**.
- Hassan: ~**15–20 min focus**, great vocabulary; ultimate goal **reading** → add **phonics audio** + **drag-letter-into-word** (`_AT`) activity.

## Notable decisions during build
- Lowercase made the **headline** skill (Build Small abc).
- "P is for **Piano**"; Reading Words uses **PEN** (not Pig).
- Reading Words pool expanded to **75 words** for ≤2× repeat; word families incl. 2-letter blends.
- Level structure: Letter/Number = **10 games × 15 Q**; Math Lab = **4 games × 10 Q**; level tiles show just "Game N".
- Math: objects first, **equation revealed after** solving; **Count the Zoo** replaced a 2nd addition station; **big** answer buttons; varied object pools.
- Treasure chest redrawn for clarity (light interior); egg-hatch + monkey-swing animations added.
- Animal Planet: fun-fact **3D flip cards**; added **Under the Sea** (Ocean Facts + **Whale World** with calls/dive meters/video placeholders).
- Around the World: **SVG world map** (not cards) + plane travel + **World Discovery Cards** (21) + **Explorer Passport**; finishing a card returns to the **deck**.
- Collect mini-games are **drag-the-mascot** onto **slowly drifting** items.
- **Spot Me If You Can** built as a 9-game procedural hidden-object suite.
- **Hoorof** (Arabic, 28 letters, 8 games) added; later set so **only the Arabic letters are Arabic, all UI is English** (LTR).

## Reference implementation
`../Dino Dig.html` + its JSX/CSS files (the validated prototype). Treat as immutable reference for behavior/data.
