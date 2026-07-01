# System: Design System

**Purpose**: Visual + interaction language.
**Status**: prototype-validated.

## Brand & theme
Dinosaur-explorer ("little paleontologist") expedition. Bright, warm, PBS-Kids energy. Mascot **Rexy** (🦖) guides on the home map.

## Color
- Section/brand colors (bright, harmonious): orange `#FF8A3D`, teal `#2BB3C6`, green `#7BC043`, coral `#FF6B6B`, grape `#8B7BE0`, sky `#4AA8E0`, yellow `#FFC53D`, pink `#F472A8` (each with a darker shade for button "press" depth).
- Warm neutrals: bg `#FFF8EE`/`#FFEFD9`, card `#FFFFFF`, ink `#3A2E2A`, soft ink `#6E5D55`, lines `#F0E2CF`.

## Type
- Headings: **Baloo 2** (rounded, friendly). Body: **Nunito**. 1–3 fonts only.
- Min sizes: large touch-first; activity text never tiny.

## Components
- **Buttons**: pill, bold, colored with a solid darker "shadow" offset that compresses on press (`translateY`). Variants per color + ghost + lg.
- **Cards/lands**: rounded (22–32px radius), soft layered shadows, decorative circles, emoji art, "▶ Play"/"🔒 Soon" pills, progress bars.
- **HUD**: avatar+level, XP bar, streak/star/egg coins, sound toggle, parent button.
- **Reward modal**: confetti, starburst, reward pills (+stars/+xp/egg/sticker), "Map"/"Play again".
- **Motion**: pop, wiggle, sparkle burst, shake (wrong), drop-in, confetti, card flip. Entrance animations gated so print/reduced-motion show end-state.

## Touch / sizing
Landscape, fixed **1194×834** iPad canvas (see `systems/scaling-device-frame.md`). Hit targets generously large (≥44px; answer tiles ~72–120px).

## Art convention
Emoji + simple CSS shapes for UI; **labeled striped placeholders / drop-in image-slots** for real scene art. No hand-drawn complex SVG.

## Native rebuild notes
Port tokens to a Flutter theme (colors, radii, shadows, type scale). Button "press-depth" = layered Container or shadow trick. Confetti/sparkle → particle lib or lottie Flutter package.
