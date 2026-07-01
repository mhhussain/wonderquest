/* ============================================================
   SPOT ME IF YOU CAN — scene data & object pools
   ============================================================ */

// Hidden-object / animal scenes: emoji pools to scatter as "scenery"
const SPOT_SCENES = {
  picnic:   { name:'Picnic Day',      emoji:'🧺', bg:'#BFE89A', deco:['🌳','🌷','🍃','🟫','☁️','🌼','🪨','🐜'] },
  playground:{name:'Playground',      emoji:'🛝', bg:'#A9DCF0', deco:['🌳','☁️','🌷','🟫','🐦','🍃','⚽','🪁'] },
  aquarium: { name:'Aquarium',        emoji:'🐠', bg:'#7FD0E6', deco:['🫧','🪸','🌊','🐚','🌿','🪨','💧','🐟'] },
  museum:   { name:'Dino Museum',     emoji:'🦕', bg:'#E7CFA1', deco:['🦴','🥚','🌋','🪨','🌿','🟫','⛰️','🍃'] },
  safari:   { name:'Safari Park',     emoji:'🦁', bg:'#F2D98C', deco:['🌴','🌾','🪨','☁️','🌳','🌅','🍃','🟫'] },
  farm:     { name:'Farm Life',       emoji:'🚜', bg:'#C7E89A', deco:['🌽','🌾','🌳','🟫','☁️','🚜','🪣','🍃'] },
  beach:    { name:'Beach Day',       emoji:'🏖️', bg:'#FFE3A8', deco:['🌊','🐚','⛱️','🩴','☀️','🪨','🏐','🦀'] },
  space:    { name:'Space Station',   emoji:'🚀', bg:'#2C2456', deco:['⭐','🪐','🌙','☄️','🛸','🌟','✨','👽'], dark:true },
  carnival: { name:'Carnival',        emoji:'🎪', bg:'#F6BFD8', deco:['🎈','🎡','🎠','🍭','🎢','🎟️','🍿','✨'] },
};

// Hidden Object Hunt missions: scene + goals (emoji + count)
const HUNT_ROUNDS = [
  { scene:'picnic',    goals:[{c:'🐝',n:3,l:'bees'},{c:'🦋',n:2,l:'butterflies'},{c:'🍎',n:4,l:'apples'}] },
  { scene:'playground',goals:[{c:'🎈',n:3,l:'balloons'},{c:'🐦',n:2,l:'birds'},{c:'⚽',n:2,l:'balls'}] },
  { scene:'aquarium',  goals:[{c:'🐡',n:3,l:'puffer fish'},{c:'🐙',n:2,l:'octopus'},{c:'🦀',n:3,l:'crabs'}] },
  { scene:'beach',     goals:[{c:'🐚',n:4,l:'shells'},{c:'🦀',n:2,l:'crabs'},{c:'🪼',n:2,l:'jellyfish'}] },
  { scene:'space',     goals:[{c:'⭐',n:4,l:'stars'},{c:'🛸',n:2,l:'UFOs'},{c:'👽',n:2,l:'aliens'}] },
  { scene:'carnival',  goals:[{c:'🎈',n:4,l:'balloons'},{c:'🍭',n:3,l:'lollipops'},{c:'🤡',n:1,l:'clown'}] },
];

// Animal Tracker rounds
const ANIMAL_ROUNDS = [
  { scene:'safari', goals:[{c:'🦁',n:2,l:'lions'},{c:'🦒',n:2,l:'giraffes'},{c:'🐘',n:2,l:'elephants'},{c:'🐒',n:3,l:'monkeys'}], deco:['🌴','🌾','🪨','🌳'] },
  { scene:'aquarium', goals:[{c:'🐠',n:3,l:'fish'},{c:'🐙',n:2,l:'octopus'},{c:'🦀',n:2,l:'crabs'},{c:'🐬',n:2,l:'dolphins'}], deco:['🫧','🪸','🌊','🐚'] },
  { scene:'farm', goals:[{c:'🐄',n:2,l:'cows'},{c:'🐖',n:2,l:'pigs'},{c:'🐔',n:3,l:'chickens'},{c:'🐑',n:2,l:'sheep'}], deco:['🌽','🌾','🌳','🟫'] },
];

// Count It scenes: one question per round, tap to count
const COUNT_ROUNDS_SPOT = [
  { scene:'playground', c:'🎈', l:'balloons', deco:['🛝','🌳','☁️','🌷','🐦','⚽'] },
  { scene:'aquarium',   c:'🐠', l:'fish',     deco:['🫧','🪸','🌊','🐚','🌿'] },
  { scene:'farm',       c:'🐔', l:'chickens', deco:['🌽','🌾','🌳','🟫','🚜'] },
  { scene:'picnic',     c:'🐝', l:'bees',     deco:['🌳','🌷','🍃','🌼','🧺'] },
  { scene:'space',      c:'⭐', l:'stars',    deco:['🪐','🌙','🛸','🌟','👽'] },
];

// Letter Detective: find all of target letter among distractors
const LETTER_ROUNDS = [
  { scene:'museum', target:'b', pool:['d','p','q','h','a','o','e'], n:5, l:"little b" },
  { scene:'farm',   target:'m', pool:['n','w','u','r','a','e','s'], n:5, l:"little m" },
  { scene:'space',  target:'A', pool:['V','W','H','N','M','E','T'], n:4, l:"big A" },
  { scene:'picnic', target:'d', pool:['b','p','q','a','o','g','c'], n:5, l:"little d" },
];

// Number Detective
const NUMBER_ROUNDS = [
  { scene:'safari',     target:'7', pool:['1','4','9','2','5','0','3'], n:5, l:"number 7" },
  { scene:'beach',      target:'4', pool:['7','1','9','6','8','3','2'], n:5, l:"number 4" },
  { scene:'carnival',   target:'2', pool:['5','3','7','1','8','6','9'], n:4, l:"number 2" },
];

// Shape Safari: find all of one shape type
const SHAPE_ROUNDS = [
  { scene:'playground', target:'🔺', pool:['⭕','⬜','⭐','🔵','🟦'], n:5, l:"triangles" },
  { scene:'beach',      target:'⭕', pool:['🔺','⬜','⭐','🟥','🔻'], n:5, l:"circles" },
  { scene:'carnival',   target:'⭐', pool:['🔺','⭕','⬜','🔵','🟥'], n:5, l:"stars" },
  { scene:'space',      target:'⬜', pool:['🔺','⭕','⭐','🔵','🔻'], n:4, l:"squares" },
];

// Color Quest: find objects of a target color
const COLOR_GROUPS = {
  red:    { l:'red',    sw:'#E84B4B', items:['🍎','🌹','🍓','🔴','🚗','🧣'] },
  blue:   { l:'blue',   sw:'#3F86D6', items:['🫐','🔵','💙','🐳','🧢','👕'] },
  yellow: { l:'yellow', sw:'#F2C233', items:['🍌','⭐','🌻','🟡','🧀','🐤'] },
  green:  { l:'green',  sw:'#5FB94B', items:['🍀','🟢','🥦','🐸','🌿','🥝'] },
};
const COLOR_ROUNDS = [
  { scene:'picnic', target:'red',    n:5 },
  { scene:'farm',   target:'yellow', n:5 },
  { scene:'beach',  target:'blue',   n:4 },
  { scene:'playground', target:'green', n:5 },
];

// Match the Socks: color/pattern themes
const SOCK_COLORS = ['#E84B4B','#3F86D6','#F2C233','#5FB94B','#9B6FE0','#FF8A3D','#2BB3C6','#F472A8'];
const SOCK_PATTERNS = ['solid','stripe','dots','zig'];
const SOCK_LEVELS = [
  { pairs:4, by:'color',   say:'Find the socks that are the same color!' },
  { pairs:5, by:'pattern', say:'Find the socks with the same pattern!' },
  { pairs:6, by:'both',    say:'Find the matching sock pairs!' },
];

Object.assign(window, { SPOT_SCENES, HUNT_ROUNDS, ANIMAL_ROUNDS, COUNT_ROUNDS_SPOT, LETTER_ROUNDS, NUMBER_ROUNDS, SHAPE_ROUNDS, COLOR_GROUPS, COLOR_ROUNDS, SOCK_COLORS, SOCK_PATTERNS, SOCK_LEVELS });
