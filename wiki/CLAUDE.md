# CLAUDE.md — Wonder Quest Wiki Schema & Conventions

This wiki is the **source of truth** for *Wonder Quest* (formerly "Dino Dig", working title "Hassan's Summer Ed App"): an iPad/mobile early-learning app for a 5-year-old (Pre-K → Michigan GSRP readiness). It documents the **validated HTML prototype** so a developer can rebuild it natively (target: Flutter for iPad/tablet).

## Layers
- **Raw source**: the original product brief + the working prototype `../Dino Dig.html` and its JSX/CSS files (immutable reference; never edit from the wiki).
- **Wiki** (`wiki/`): LLM-maintained markdown. You own this layer.
- **Schema**: this file.

## Directory map
- `overview.md` — product vision, audience, status
- `modules/` — one page per learning land (behavior, activities, data, rewards)
- `systems/` — cross-cutting systems (design system, rewards, engines, audio, state, scaling)
- `specs/` — curriculum, content data model, parent dashboard
- `requirements/` — consolidated requirements for the native rebuild
- `sources/` — captured source material (brief)
- `index.md` — catalog of every page (read this first)
- `log.md` — append-only chronological record

## Page conventions
- Start each page with a one-line **Purpose**, then **Status** (`prototype-validated` | `spec-only` | `proposed`).
- Use `[[wiki-links]]` style references by relative path, e.g. `modules/letter-adventure.md`.
- Keep a **Native rebuild notes** section on module/system pages flagging anything HTML-specific that needs a Flutter equivalent (Web Speech API, Web Audio, pointer events, emoji-as-art).
- Flag open questions with `> ❓`.

## Workflows
- **Ingest** a new decision/source → write/update the relevant page, update `index.md`, append to `log.md`.
- **Query** → read `index.md`, drill into pages, answer with citations; file durable answers back as pages.
- **Lint** → check for contradictions, stale "proposed" items now built, orphan pages, missing cross-refs, and content gaps before the architecture phase.

## Status legend
`prototype-validated` = exists and verified in the HTML prototype · `spec-only` = specified in brief, not yet built · `proposed` = idea, not committed.
