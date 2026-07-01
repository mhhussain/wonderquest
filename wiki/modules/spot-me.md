# Module: Spot Me If You Can! (Where's Hassan?)

**Purpose**: Observation, scanning, counting, letters/numbers/shapes/colors via hidden-object play.
**Status**: prototype-validated.

## Approach
A **procedural scene engine** scatters richly-themed **emoji objects** into busy scenes (jittered-grid placement). Every play is freshly generated → near-unlimited replayability. (Not hand-drawn art — see rebuild notes.)

## Dashboard (9 games)
1. **Hidden Object Hunt** — themed scenes (Picnic, Carnival, Aquarium, Beach, Space…), multi-goal missions ("3 bees, 2 butterflies, 4 apples"); goal chips tick up; rounds advance.
2. **Match the Socks** — 3 levels: by color → by pattern → both (socks rendered via clip-path shapes).
3. **Count It If You Can** — tap each object to count; numbers appear automatically.
4. **Letter Detective** — find all of one target letter among look-alike distractors (supports lowercase).
5. **Number Detective** — find all of a target number.
6. **Shape Safari** — find all triangles/circles/stars/squares.
7. **Animal Tracker** — find target animals in a scene.
8. **Spot the Difference** — two side-by-side scenes; tap what changed in panel B (removed/swapped items).
9. **Color Quest** — find all objects of a target color.

## Shared engine (SpotScene)
Multi-goal find/count over a scattered field: goals `[{char,count,label}]`, decoy pool, `mode: find|count`. Found items pop+ring; wrong taps show a "👀" ripple. Used by Spot Me, Hoorof Find/Safari, and continent Find missions.

## Rewards
Stars, XP, eggs, detective stickers, titles (Junior Detective → Hidden Object Hero per brief); feeds `progress.find`.

## Native rebuild notes
- Emoji scenes are placeholders for **illustrated "Highlights/Where's Waldo" artwork**; engine is structured to swap art per scene (hotspot coordinates over a background image).
- `Daily Search Challenge` (brief) is **not yet built** → `PR`.
