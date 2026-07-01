# System: Reusable Game Engines

**Purpose**: The shared mechanics powering many activities. Rebuild these once natively.
**Status**: prototype-validated.

## Level-dealer (`dealGames`)
Splits a question pool into **G games × Q questions**. Fills game-by-game drawing **least-used items first** → guarantees **no repeat within a game** (when Q ≤ pool) and spreads usage so each item repeats **≤2× across games** once pool ≥ G·Q/2. Used by Letter Adventure (10×15), Number Kingdom (10×15), Math Lab (4×10). Per-game completion saved (`getLevels`/`markLevel`).

## Level UI
`LevelSelect` (grid of "Game N" tiles, ⭐ on completed) + `GameLevels` wrapper (deals once, plays chosen deck, marks done, returns to picker).

## Trace engine (`TraceCanvas`)
Canvas overlay on a guide glyph; tracks stroke coverage; fires `onCovered` past a threshold to gate "done". Supports finger + Apple Pencil. Used by Big Letters, Trace Letters, Hoorof Trace.

## SpotScene (scatter find/count)
Jittered-grid placement of target + decoy emoji over a colored scene. Goals `[{char,count,label}]`, `mode: find|count`. Found→pop+ring; wrong→"👀" ripple. Powers Spot Me (all), Hoorof Find/Safari, continent Find missions. **Designed to swap emoji for hotspots over a background illustration.**

## Drag-collect (Discovery Cards "collect")
Mascot is **dragged**; items **drift slowly** (edge-bouncing) and are collected on overlap. Uses a **setInterval tick (not rAF)** so motion continues if the tab/app backgrounds; scale-corrects pointer→stage coords. Other card engines: **order** (tap by size), **build** (stack in order), **decorate** (tap spots), **find**.

## Flip card
CSS 3D `rotateY(180deg)` reveal (front illustration → back fact). Requires a real block element (inline spans don't transform). Used by Animal Fun Facts + Discovery Cards.

## Habitat/sorting drag
Drag chip → drop zone with overlap test; correct reveals a fact. (Animal Homes.)

## Native rebuild notes
Reimplement as Flutter widgets: gesture handling (Flutter's GestureDetector/gesture system), animation (Flutter's Animation API), canvas (CustomPaint + Impeller rendering; consider Flame engine for game loops). Keep the **dealer and reward logic as pure Dart** shared across modules.
