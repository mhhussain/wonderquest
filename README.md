# Wonder Quest

An offline iPad learning app for a 5-year-old (Pre-K → Michigan GSRP readiness): seven lands of games covering English letters, tracing, numbers, early math, Arabic letters (Hoorof), animals, and world geography. Built with Flutter. No ads, no network, no accounts — one local save file.

## Run

```bash
cd app
flutter run          # pick an iPad simulator/device
```

## Test

```bash
cd app
flutter analyze && flutter test
```

## Where things live

- `app/` — the Flutter app (landscape iPad, 1194×834 design canvas).
- `wiki/` — **source of truth**: module behavior, systems, specs, decisions. Start at `wiki/index.md`.
- `raw/` — the validated HTML/JSX prototype the app is rebuilt from (immutable reference; behavior authority when docs disagree).
- `docs/superpowers/plans/2026-07-01-wonder-quest-v1.md` — the v1 implementation plan.
- `wiki/requirements/app-store-artifacts.md` — release/publish checklist (TestFlight, Kids Category, privacy).
