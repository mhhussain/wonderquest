# Module: Little Math Lab

**Purpose**: Early math — counting, addition, subtraction, comparing.
**Status**: prototype-validated.

## Structure
A **station map** of 6 themed stations → each opens **4 games × 10 questions** (level-dealer). Objects shown first; the **equation is revealed only after the child solves it** (early-childhood best practice).

## Stations & engines
- **Count the Zoo** (count) — count a group of a zoo animal (different animal each round, 18 types), pick the number. (Replaced an earlier 2nd addition station.)
- **Dino Snack Time** (add) — "Rex has 2 🍎, give 2 more!"; tap to count both groups, pick total, reveal `2+2=4`. Uses varied fruits/veggies per round.
- **Treasure Hunt** (add) — gems inside a **rendered treasure chest** (domed lid, gold straps, lock, light velvet tray for contrast); **different gemstone each round** (12 types).
- **Lost Dino Eggs** (subtract) — eggs **hatch/animate away**; opening animation: eggs shake → crack 💥 → baby dinos pop out. "How many left?"
- **Cookie Math** (subtract) — a **monkey swings in on vines** from offscreen and eats cookies; eaten spots become **super-transparent**. "How many left?"
- **More or Less** (compare) — two groups; tap the one with MORE (or FEWER).

## UX details
- Answer-choice buttons are **large (72px)**, sized to match the objects; reveal numbers are big.
- Themed object pools rotate so no repeat within a game.

## Rewards
Stars, XP, dino eggs, math stickers; feeds `progress.math`.

## Native rebuild notes
- Animations (monkey swing, egg hatch) are CSS/JS in the prototype → recreate with Flutter's Animation API or lottie Flutter package; consider real character art.
- Treasure chest is pure CSS shapes → replace with an illustrated asset.
