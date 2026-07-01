# Module: Amazing Animal Planet

**Purpose**: Animals — names, habitats, fun facts, ocean life.
**Status**: prototype-validated.

## Game picker (3 cards)
1. **Animal Homes** (habitat sorting) — drag each animal to its habitat (Ocean/Jungle/Arctic/Savanna); correct drop reveals a fun fact aloud.
2. **Fun Facts** — grid of **3D flip cards**: front shows animal emoji + name + "Tap for a fun fact"; tap flips (purple back) and reads the fact. Discovered animals saved to the Animal collection book.
3. **Under the Sea** — sub-menu with two activities:
   - **Ocean Facts** — tap 8 sea creatures for "most interesting" facts (octopus regrows arms / 3 hearts; jellyfish no brain; starfish regrows arms; pistol shrimp; etc.).
   - **Whale World** — gallery of **6 whale types** (Blue, Humpback, Sperm, Orca, Beluga, Narwhal). Each: picture (drop-in image-slot + emoji), fact, **"Hear its call"** (synthesized per-whale tone via Web Audio), a **dive-depth meter** (Sperm 2000m fills full vs Blue 200m), and a **dive-video placeholder**.

## Content
Animals carry: emoji, name, habitat, fact. Fun facts written for ages 4–6 (1–2 sentences). Whales carry: name, color, dive depth (m), fact, call base-frequency.

## Rewards
Stars, XP, dino eggs, stickers; discovered animals → collection book; feeds `progress.animal`.

## Native rebuild notes
- Whale calls are **synthesized oscillator tones** (placeholder) → replace with **real whale recordings**.
- Whale photos/dive videos are placeholders/image-slots → source real media (licensing).
- Flip cards use CSS 3D transform → Flutter equivalent (Transform.rotate / custom animation needed).
