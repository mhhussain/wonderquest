# Overview

**Purpose**: Product vision and current state of Wonder Quest.
**Status**: prototype-validated.

## What it is
A bright, playful, **landscape iPad** learning app for **Hassan, age 5**, to use across the summer to get ahead for Michigan's **GSRP** (Great Start Readiness Program). It should feel like a **game, not schoolwork** — PBS-Kids / Khan Academy Kids energy, unified by a **dinosaur-explorer ("little paleontologist") expedition** metaphor.

## Learner profile
- Knows most uppercase; **learning lowercase** (top priority) and letter sounds.
- Learning numbers, counting, early math.
- Loves dinosaurs, animals, finding/spotting things, interactive (not passive) play; uses Apple Pencil.
- **Focus window ~15–20 min** → sessions must be short, switchable, rewarding.
- Strong vocabulary; ultimate goal is **reading**. Wants **phonics audio** and word-building (drag a letter into `_AT`).
- Bilingual goal: also learning **Arabic letters**.

## Experience shape
Home = an **Expedition Map** of "lands" (modules). Each land → a game picker → short playable activities → celebratory rewards → back to map. Everything narrated (text + audio), large touch targets, no ads, no external links, child-safe.

## Status snapshot
- **Built & verified (7 lands)**: Letter Adventure, Hoorof (Arabic), Number Kingdom, Little Math Lab, Animal Planet, Around the World, Spot Me If You Can.
- **Locked/spec (6)**: Dino Discovery, Earth Explorer, Maze World, Tracing Studio, Pattern Detective, Reading Readiness. See `modules/locked-lands.md`.
- **Cross-cutting systems** all built: see `systems/`.

## Art & audio reality
The prototype uses **emoji + simple shapes** for UI and **labeled placeholders / drop-in image-slots** for big scene art; audio is **device TTS** + synthesized tones. Production needs real illustration sets and recorded audio (esp. native Arabic letter sounds and animal/whale sounds). Tracked in `requirements/mobile-app-requirements.md`.

## Goal of this wiki
Seed the **native Flutter (iPad/tablet)** rebuild: requirements, module behaviors, data models, engines, reward economy, and curriculum mapping — kept current as architecture and implementation proceed.
