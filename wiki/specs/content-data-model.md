# Spec: Content Data Model

**Purpose**: Canonical data shapes (from the prototype) to port to typed models.
**Status**: prototype-validated.

## Section / land
`{ id, title, sub, emoji, color, playable:bool }` — drives the Expedition Map.

## Alphabet (English)
`{ u:'B', l:'b', word:'Bat', emoji:'🦇', ph:'buh' }` (uppercase, lowercase, picture word, emoji, beginning-sound). Confusable map: `{ b:'d', p:'q', … }`. Match order list (easy→tricky).

## Word families (Reading Words)
`{ emoji, word:'BAT', miss:['B'], end:'AT', distract:['C','H','S'] }`; blends use `miss:['F','R']`. Pool = 75 unique (55 single + 20 blend).

## Arabic letter (Hoorof)
`{ g:'ب', nm:'بَاء', tr:'Baa', snd:'b', w:'بَطَّة', wtr:'batta (duck)', e:'🦆', base:'ٮ', dots:'1b' }`. Clusters of 3–4; families for distractors; dot codes `{count}{a|b}` (above/below) + `0`.

## Numbers
Count rounds `{ emoji, count }`; missing-number `{ seq:[…], missIdx, answer }`. Pools generated (90 items) for ≤2× repeat.

## Math (Little Math Lab)
Stations `{ id,title,emoji,color,type:'count|add|sub|compare', obj, obj_name, … }`. Pools: add (a+b≤16), sub (total−take), count (1–12), compare (a≠b). Themed object lists: zoo animals (18), fruits/veggies, gems (12).

## Animals
`{ emoji, name, habitat, fact }`; habitats `{id,name,emoji,color}`. Whales `{ e,n,color,dive(m),f,base(freq) }`. Ocean facts `{ e,n,f }`.

## Around the World
Continents (id, name, color, emoji, badge, mission, theme, animals[]). Discovery cards by continent: `{ e,title,fact,sticker, game:{type:'collect|order|build|decorate|find', …params} }` (3 each, 21 total). World Wonder cards, stamps, passport.

## Spot Me
Scenes `{ name, emoji, bg, deco[], dark? }`. Game rounds reference a scene + goals `[{c,n,l}]` or a single target + look-alike pool. Socks: color/pattern levels.

## Rewards/economy
See `systems/state-persistence.md` for the persisted profile shape and `systems/rewards-gamification.md` for `applyReward`.

## Native rebuild notes
Port each as a **typed TS model + content JSON**; separate **content data** (translatable, expandable) from **engine code**. This enables dynamic generation of "hundreds of activities" (brief) from compact data + engines.
