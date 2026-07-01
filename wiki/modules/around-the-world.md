# Module: Around the World

**Purpose**: Geography — continents, landmarks, world animals, cultures.
**Status**: prototype-validated.

## Flow
1. **World Map** — an **SVG world map** of 7 stylized continent landmasses on an ocean (replaced earlier square cards), each tappable + colored; a **Passport** button (stamps progress N/7).
2. **Fly there** — tap a continent → ~6s plane **travel animation** (board → fly over clouds/ocean → "Welcome to Africa!"), narrated.
3. **Continent page** — themed (Safari, Panda Mountain, Outback, Frozen, etc.): a rotating world-fact ribbon, a 6-animal grid (tap to hear facts), and two buttons: **Find mission** and **Discovery Cards**.
4. **Hidden Discovery mission** — busy search-and-find scene ("Find the 4 lions!"); completing grants a continent **stamp + badge + World Wonder card** + shared rewards.
5. **Explorer Passport** — collectible album: 7 continent stamps, discovery points, 7 World Wonder cards (tap unlocked to hear).

## World Discovery Cards (sub-feature)
Per continent, a deck of **3 collectible flip cards** (21 total). Each card: illustration front → **narrated fact** on flip → launches a **themed mini-game** → on win the card is **collected** (sticker/stars/XP) and you **return to the deck** (not the map) to keep playing.
5 reusable mini-game engines, themed per card:
- **collect** (drag mascot to gather drifting items), **order** (tap by size/speed), **build** (stack pieces in order), **decorate** (tap glowing spots), **find** (tap hidden targets in a scene).

## Rewards
Stars, XP, eggs, stickers, stamps, World Wonder cards; feeds `progress.world`. Collected cards persisted under `world.discovery`.

## Native rebuild notes
- Travel + map are CSS/SVG → recreate map as interactive vector; consider real continent illustrations.
- Card mini-games share the engines in `systems/game-engines.md`.
- Collect mini-game uses drifting items + drag-overlap (timer-driven, not rAF, to survive backgrounded tabs) — see engines page.
