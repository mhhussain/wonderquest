# Spec: Parent Dashboard

**Purpose**: Grown-up analytics & guidance view.
**Status**: prototype-validated.

## Access
Reached via a 👪 button in the HUD (gate behind a parent-lock in production). Separate screen, calmer styling.

## Sections (in prototype)
- **Top stats**: minutes today (goal 20), streak, letters mastered (n/26), numbers mastered (n/20).
- **Alphabet mastery grid**: A–Z colored mastered / learning / not-started (upper+lower).
- **This week**: per-day minutes bar chart.
- **Skill progress bars**: Letter ID, Letter Sounds, Numbers 1–20, Counting, Tracing, Animals & World (driven by `progress.*` + mastery arrays).
- **Coach notes**: flagged practice areas (e.g. lowercase b/d, sounds g/j/q) + wins.
- **GSRP readiness ring**: overall % with an "ahead of pace" message; "Email weekly report" CTA.

## Data sources
Reads persisted profile fields: `minutesToday, week[], streak, lettersMastered/Learning, numbersMastered, progress{}`. (Currently some coach-note items are illustrative, not yet event-derived.)

## Production requirements (brief)
Track: letters mastered, numbers mastered, **tracing accuracy**, math progress, time spent, **weekly reports**, areas needing practice, favorite scenes/modules.

## Native rebuild notes
- To power *real* coach notes & tracing accuracy, log **per-attempt events** (skill, item, correct?, ms, accuracy) — add an events store beyond the summary fields.
- Add parent gate (e.g. hold + simple math) before opening.
- Weekly report = generated summary (email/share). > ❓ on-device only vs cloud account.
