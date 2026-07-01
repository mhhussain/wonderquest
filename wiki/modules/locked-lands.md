# Module: Locked / Spec-only Lands

**Purpose**: Modules designed in the brief and present on the map as "🔒 Soon", not yet built.
**Status**: spec-only.

These appear on the Expedition Map but are not interactive yet. Specs from the original brief (`sources/original-brief.md`):

- **Dino Discovery World** — dinosaur names, sizes, herbivore/carnivore, fun facts; matching, puzzles, **fossil digs**, trace dino paths, hidden dinos; reward = unlock new dinosaurs. (Strong fit — Hassan loves dinos.)
- **Earth Explorer** — weather, seasons, day/night, mountains, oceans, volcanoes, forests; dress-for-weather, match seasons, build weather scenes.
- **Maze World** — easy→hard mazes (dino/animal-rescue/number/letter), Apple Pencil path drawing.
- **Creative Tracing Studio** — trace shapes/letters/numbers/animals, draw along dotted lines (Pencil). *Note: tracing already exists inside Letter Adventure & Hoorof; this is a standalone free-draw studio.*
- **Pattern Detective** — pattern recognition, sequencing, logic; complete-the-pattern (color/shape/animal).
- **Reading Readiness** — beginning sounds, **rhyming**, sight words, listening comprehension, interactive read-aloud stories. *Partially overlaps Letter Adventure's Reading Words; this adds rhyming + sight words + stories.*

## Reusable assets already available
Most of these can be built fast on existing systems:
- Tracing/Pencil → reuse `TraceCanvas` (trace engine).
- Hidden/find (dinos, patterns) → reuse **SpotScene**.
- Matching/memory → reuse Animal Planet / Hoorof memory patterns.
- Drag-to-target (mazes, sorting) → reuse drag-collect / habitat-drag.
- Rewards/levels → reuse rewards + level-dealer.

## Priority suggestion
Given the learner: **Dino Discovery** (motivation) and **Reading Readiness/rhyming** (reading goal) are highest value next. > ❓ confirm build order in architecture phase.
