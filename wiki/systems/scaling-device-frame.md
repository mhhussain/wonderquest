# System: Scaling & Device Frame

**Purpose**: How the fixed-size design fits any screen.
**Status**: prototype-validated; superseded for native by [decisions-2026-07-01](../requirements/decisions-2026-07-01.md) — the native app **keeps** a fixed-canvas letterbox scaler.

## Prototype technique
- Content is a **fixed 1194×834 canvas** (landscape iPad) inside a full-viewport **scaler** that applies `transform: scale()` to fit, letterboxing on a dark background. Controls live outside the scaled element.
- Wrapped in a decorative **iPad bezel** (`.ipad` frame with camera dot) for presentation.
- React + Babel (in-browser) renders the app; modules split across many JSX files sharing globals via `Object.assign(window, …)`.

## Native rebuild notes
- ~~**Do not port the fixed-canvas scaler** — native is genuinely responsive.~~ **Superseded** by decisions-2026-07-01 ("Fixed 1024×600px (or native iPad landscape resolution) with letterbox scaling"): the Flutter app uses a fixed **1194×834** canvas in `app/lib/widgets/canvas_scaler.dart` (`FittedBox` letterbox on `WqColors.ink`, wrapped in `SafeArea` so system insets stay outside the canvas).
- Lock to **landscape** for game scenes (per brief) unless product decides otherwise. > ❓ support portrait?
- Drop the bezel (real device provides it).
- Replace the multi-file `window`-global JSX pattern with proper **TS modules + imports**; replace in-browser Babel with a real bundler (Metro).
- Keep absolute-positioned scene layouts **relative to a measured container** (engines already scale pointer coords to container size — carry that principle over).
