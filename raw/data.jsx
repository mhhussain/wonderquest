/* ============================================================
   DATA — content for Hassan's app
   ============================================================ */

// ---------- Section map (home) ----------
const SECTIONS = [
  { id:'letter',  title:'Letter Adventure',  sub:'Aa Bb Cc',            emoji:'🔤', color:'var(--orange)', playable:true },
  { id:'hoorof',  title:'Hoorof',            sub:'Arabic letters',      emoji:'🐪', color:'var(--teal)',   playable:true },
  { id:'number',  title:'Number Kingdom',    sub:'1 2 3 counting',      emoji:'🔢', color:'var(--teal)',   playable:true },
  { id:'animal',  title:'Animal Planet',     sub:'Habitats & facts',    emoji:'🦁', color:'var(--grape)',  playable:true },
  { id:'math',    title:'Little Math Lab',   sub:'Add & take away',     emoji:'➕', color:'var(--green)',  playable:true },
  { id:'dino',    title:'Dino Discovery',    sub:'Dig & collect',       emoji:'🦕', color:'var(--coral)',  playable:false },
  { id:'world',   title:'Around the World',  sub:'Continents',          emoji:'🌍', color:'var(--sky)',    playable:true },
  { id:'earth',   title:'Earth Explorer',    sub:'Weather & seasons',   emoji:'⛅', color:'var(--teal)',   playable:false },
  { id:'find',    title:"Where's Hassan?",   sub:'Hidden objects',      emoji:'🔍', color:'var(--yellow)', playable:true },
  { id:'maze',    title:'Maze World',        sub:'Find the way',        emoji:'🌀', color:'var(--pink)',   playable:false },
  { id:'trace',   title:'Tracing Studio',    sub:'Draw along',          emoji:'✏️', color:'var(--orange)', playable:false },
  { id:'pattern', title:'Pattern Detective', sub:'What comes next?',    emoji:'🔺', color:'var(--grape)',  playable:false },
  { id:'reading', title:'Reading Readiness', sub:'Rhymes & sounds',     emoji:'📖', color:'var(--coral)',  playable:false },
];

// ---------- Phonics: beginning-sound approximations for speech ----------
const PHONICS = {
  A:'ah', B:'buh', C:'kuh', D:'duh', E:'eh', F:'fff', G:'guh', H:'huh',
  I:'ih', J:'juh', K:'kuh', L:'lll', M:'mmm', N:'nnn', O:' aw', P:'puh',
  Q:'kwuh', R:'rrr', S:'sss', T:'tuh', U:'uh', V:'vvv', W:'wuh', X:'ks',
  Y:'yuh', Z:'zzz'
};

// ---------- Reading Words (word families) ----------
// each: picture emoji, the word, miss = letter(s) the child drags in order,
// end = the fixed family ending shown, distract = wrong tiles.
// Single-letter rounds are "easy"; two-letter blends are "hard".
const WORDS_EASY = [
  // _AT
  { emoji:'🦇', word:'BAT', miss:['B'], end:'AT', distract:['C','H','R'] },
  { emoji:'🐱', word:'CAT', miss:['C'], end:'AT', distract:['M','R','S'] },
  { emoji:'🎩', word:'HAT', miss:['H'], end:'AT', distract:['B','S','F'] },
  { emoji:'🐀', word:'RAT', miss:['R'], end:'AT', distract:['C','N','P'] },
  // _AD
  { emoji:'👨', word:'DAD', miss:['D'], end:'AD', distract:['S','M','B'] },
  { emoji:'😢', word:'SAD', miss:['S'], end:'AD', distract:['D','M','P'] },
  { emoji:'🛍️', word:'BAG', miss:['B'], end:'AG', distract:['T','R','W'] },
  // _ED
  { emoji:'🛏️', word:'BED', miss:['B'], end:'ED', distract:['R','T','L'] },
  { emoji:'🟥', word:'RED', miss:['R'], end:'ED', distract:['B','N','W'] },
  // _UT
  { emoji:'🥜', word:'NUT', miss:['N'], end:'UT', distract:['C','H','B'] },
  { emoji:'✂️', word:'CUT', miss:['C'], end:'UT', distract:['N','H','G'] },
  // _AN
  { emoji:'🚐', word:'VAN', miss:['V'], end:'AN', distract:['F','P','C'] },
  { emoji:'🪭', word:'FAN', miss:['F'], end:'AN', distract:['V','P','M'] },
  { emoji:'🍳', word:'PAN', miss:['P'], end:'AN', distract:['F','C','V'] },
  { emoji:'🥫', word:'CAN', miss:['C'], end:'AN', distract:['P','F','M'] },
  // _OCK
  { emoji:'🧦', word:'SOCK', miss:['S'], end:'OCK', distract:['L','R','D'] },
  { emoji:'🔒', word:'LOCK', miss:['L'], end:'OCK', distract:['S','R','B'] },
  { emoji:'🪨', word:'ROCK', miss:['R'], end:'OCK', distract:['S','L','M'] },
  // bonus families
  { emoji:'🖊️', word:'PEN', miss:['P'], end:'EN', distract:['T','D','B'] },
  { emoji:'🐶', word:'DOG', miss:['D'], end:'OG', distract:['L','F','H'] },
  { emoji:'🌞', word:'SUN', miss:['S'], end:'UN', distract:['B','R','F'] },
  { emoji:'🐔', word:'HEN', miss:['H'], end:'EN', distract:['T','P','D'] },
  // more single-letter words (bigger pool → each repeats ≤ twice across games)
  { emoji:'🚗', word:'CAR',  miss:['C'], end:'AR',  distract:['J','B','F'] },
  { emoji:'🫙', word:'JAR',  miss:['J'], end:'AR',  distract:['C','B','T'] },
  { emoji:'🧢', word:'CAP',  miss:['C'], end:'AP',  distract:['M','N','T'] },
  { emoji:'🗺️', word:'MAP',  miss:['M'], end:'AP',  distract:['C','N','T'] },
  { emoji:'😴', word:'NAP',  miss:['N'], end:'AP',  distract:['C','M','L'] },
  { emoji:'📦', word:'BOX',  miss:['B'], end:'OX',  distract:['F','C','M'] },
  { emoji:'🐛', word:'BUG',  miss:['B'], end:'UG',  distract:['M','R','J'] },
  { emoji:'☕', word:'MUG',  miss:['M'], end:'UG',  distract:['B','R','J'] },
  { emoji:'📌', word:'PIN',  miss:['P'], end:'IN',  distract:['B','F','T'] },
  { emoji:'🗑️', word:'BIN',  miss:['B'], end:'IN',  distract:['P','F','W'] },
  { emoji:'🍲', word:'POT',  miss:['P'], end:'OT',  distract:['D','H','C'] },
  { emoji:'🔥', word:'HOT',  miss:['H'], end:'OT',  distract:['P','D','C'] },
  { emoji:'🐮', word:'COW',  miss:['C'], end:'OW',  distract:['B','N','H'] },
  { emoji:'🐝', word:'BEE',  miss:['B'], end:'EE',  distract:['S','T','F'] },
  { emoji:'🏷️', word:'TAG',  miss:['T'], end:'AG',  distract:['B','W','R'] },
  { emoji:'⚽', word:'BALL', miss:['B'], end:'ALL', distract:['T','W','F'] },
  { emoji:'🔔', word:'BELL', miss:['B'], end:'ELL', distract:['T','S','W'] },
  { emoji:'💍', word:'RING', miss:['R'], end:'ING', distract:['K','S','W'] },
  { emoji:'🤴', word:'KING', miss:['K'], end:'ING', distract:['R','S','W'] },
  { emoji:'✋', word:'HAND', miss:['H'], end:'AND', distract:['S','B','L'] },
  { emoji:'🔑', word:'KEY',  miss:['K'], end:'EY',  distract:['B','T','M'] },
  { emoji:'🐐', word:'GOAT', miss:['G'], end:'OAT', distract:['C','B','M'] },
  { emoji:'🧥', word:'COAT', miss:['C'], end:'OAT', distract:['G','B','M'] },
  { emoji:'🍽️', word:'DISH', miss:['D'], end:'ISH', distract:['F','W','M'] },
  { emoji:'🌙', word:'MOON', miss:['M'], end:'OON', distract:['S','N','B'] },
  { emoji:'🎂', word:'CAKE', miss:['C'], end:'AKE', distract:['B','L','M'] },
  { emoji:'🦴', word:'BONE', miss:['B'], end:'ONE', distract:['C','T','N'] },
  { emoji:'🪺', word:'NEST', miss:['N'], end:'EST', distract:['B','R','T'] },
  { emoji:'🌽', word:'CORN', miss:['C'], end:'ORN', distract:['B','H','T'] },
  { emoji:'🦆', word:'DUCK', miss:['D'], end:'UCK', distract:['L','T','B'] },
  { emoji:'🪵', word:'LOG',  miss:['L'], end:'OG',  distract:['D','F','H'] },
  { emoji:'🕸️', word:'WEB',  miss:['W'], end:'EB',  distract:['B','R','T'] },
  { emoji:'🍯', word:'JAM',  miss:['J'], end:'AM',  distract:['H','R','D'] },
];
const WORDS_HARD = [  // two-letter beginnings (blends & digraphs)
  { emoji:'🐸', word:'FROG',  miss:['F','R'], end:'OG',  distract:['C','L','S'] },
  { emoji:'🦀', word:'CRAB',  miss:['C','R'], end:'AB',  distract:['F','L','S'] },
  { emoji:'🚩', word:'FLAG',  miss:['F','L'], end:'AG',  distract:['R','C','S'] },
  { emoji:'⭐', word:'STAR',  miss:['S','T'], end:'AR',  distract:['P','R','C'] },
  { emoji:'🥁', word:'DRUM',  miss:['D','R'], end:'UM',  distract:['F','L','S'] },
  { emoji:'🌳', word:'TREE',  miss:['T','R'], end:'EE',  distract:['F','C','S'] },
  { emoji:'🕐', word:'CLOCK', miss:['C','L'], end:'OCK', distract:['R','S','B'] },
  { emoji:'🔌', word:'PLUG',  miss:['P','L'], end:'UG',  distract:['R','S','B'] },
  { emoji:'🚢', word:'SHIP',  miss:['S','H'], end:'IP',  distract:['C','L','T'] },
  { emoji:'🐟', word:'FISH',  miss:['F','I'], end:'SH',  distract:['C','S','T'] },
  { emoji:'🌟', word:'SPIN',  miss:['S','P'], end:'IN',  distract:['R','L','C'] },
  { emoji:'🧹', word:'BROOM', miss:['B','R'], end:'OOM', distract:['F','L','S'] },
  { emoji:'🥄', word:'SPOON', miss:['S','P'], end:'OON', distract:['M','N','B'] },
  { emoji:'🐍', word:'SNAKE', miss:['S','N'], end:'AKE', distract:['C','L','B'] },
  { emoji:'👑', word:'CROWN', miss:['C','R'], end:'OWN', distract:['F','B','S'] },
  { emoji:'🍞', word:'BREAD', miss:['B','R'], end:'EAD', distract:['F','L','S'] },
  { emoji:'🚂', word:'TRAIN', miss:['T','R'], end:'AIN', distract:['B','C','S'] },
  { emoji:'🧱', word:'BRICK', miss:['B','R'], end:'ICK', distract:['C','F','S'] },
  { emoji:'🌱', word:'PLANT', miss:['P','L'], end:'ANT', distract:['R','C','S'] },
  { emoji:'🐌', word:'SNAIL', miss:['S','N'], end:'AIL', distract:['L','R','T'] },
];

// quantities pool for dynamic counting rounds
const COUNT_EMOJIS = ['🥚','🦕','🍎','⭐','🐢','🦋','🐠','🌸','🐞','🦖','🌟','🍌','🐝','🐚','🦴','🪺'];

// ---------- Letter matching (uppercase <-> lowercase) ----------
const LETTER_SET = ['A','B','D','F','G','M','R','S','T','E'];

// ---------- Full alphabet: picture word + beginning sound ----------
const ALPHABET = [
  { u:'A', l:'a', word:'Apple',     emoji:'🍎', ph:'ah'   },
  { u:'B', l:'b', word:'Bat',       emoji:'🦇', ph:'buh'  },
  { u:'C', l:'c', word:'Cat',       emoji:'🐱', ph:'kuh'  },
  { u:'D', l:'d', word:'Dog',       emoji:'🐶', ph:'duh'  },
  { u:'E', l:'e', word:'Egg',       emoji:'🥚', ph:'eh'   },
  { u:'F', l:'f', word:'Fish',      emoji:'🐟', ph:'fff'  },
  { u:'G', l:'g', word:'Goat',      emoji:'🐐', ph:'guh'  },
  { u:'H', l:'h', word:'Hat',       emoji:'🎩', ph:'huh'  },
  { u:'I', l:'i', word:'Igloo',     emoji:'🛖', ph:'ih'   },
  { u:'J', l:'j', word:'Jellyfish', emoji:'🪼', ph:'juh'  },
  { u:'K', l:'k', word:'Kite',      emoji:'🪁', ph:'kuh'  },
  { u:'L', l:'l', word:'Lion',      emoji:'🦁', ph:'lll'  },
  { u:'M', l:'m', word:'Moon',      emoji:'🌙', ph:'mmm'  },
  { u:'N', l:'n', word:'Nest',      emoji:'🪺', ph:'nnn'  },
  { u:'O', l:'o', word:'Octopus',   emoji:'🐙', ph:'awh'  },
  { u:'P', l:'p', word:'Piano',     emoji:'🎹', ph:'puh'  },
  { u:'Q', l:'q', word:'Queen',     emoji:'👑', ph:'kwuh' },
  { u:'R', l:'r', word:'Rainbow',   emoji:'🌈', ph:'rrr'  },
  { u:'S', l:'s', word:'Sun',       emoji:'🌞', ph:'sss'  },
  { u:'T', l:'t', word:'Tree',      emoji:'🌳', ph:'tuh'  },
  { u:'U', l:'u', word:'Umbrella',  emoji:'☂️', ph:'uh'   },
  { u:'V', l:'v', word:'Volcano',   emoji:'🌋', ph:'vvv'  },
  { u:'W', l:'w', word:'Whale',     emoji:'🐳', ph:'wuh'  },
  { u:'X', l:'x', word:'Fox',       emoji:'🦊', ph:'kss'  },
  { u:'Y', l:'y', word:'Yo-yo',     emoji:'🪀', ph:'yuh'  },
  { u:'Z', l:'z', word:'Zebra',     emoji:'🦓', ph:'zzz'  },
];
// Confusable lowercase pairs — used to make matching tricky later on
const CONFUSE = { b:'d', d:'b', p:'q', q:'p', g:'q', a:'e', e:'a', n:'h', h:'n', m:'w', u:'n', y:'g' };
// Uppercase order for the 20-round match game: easy look-alikes → tricky
const MATCH_ORDER = ['C','O','S','X','V','W','Z','K','T','U','L','F','H','N','M','A','E','G','P','B'];
// Palette to color the abc cards
const CARD_COLORS = ['var(--orange)','var(--teal)','var(--green)','var(--coral)','var(--grape)','var(--sky)','var(--yellow)','var(--pink)'];

// ---------- Tracing letters ----------
const TRACE_LETTERS = ['a','b','c','d','m','s','t','o'];

// ---------- Numbers: count & match ----------
const COUNT_ROUNDS = [
  { emoji:'🥚', count:3 }, { emoji:'🦕', count:5 }, { emoji:'🍎', count:4 },
  { emoji:'⭐', count:6 }, { emoji:'🐢', count:2 }, { emoji:'🦋', count:7 },
  { emoji:'🐠', count:5 }, { emoji:'🌸', count:8 }, { emoji:'🐞', count:4 },
];

// ---------- Animal Planet ----------
const HABITATS = [
  { id:'ocean',   name:'Ocean',   emoji:'🌊', color:'var(--sky)'   },
  { id:'jungle',  name:'Jungle',  emoji:'🌴', color:'var(--green)' },
  { id:'arctic',  name:'Arctic',  emoji:'❄️', color:'var(--teal)'  },
  { id:'savanna', name:'Savanna', emoji:'🌾', color:'var(--orange)'},
];
const ANIMALS = [
  { emoji:'🐬', name:'Dolphin',  habitat:'ocean',   fact:'Dolphins talk to each other with clicks and whistles!' },
  { emoji:'🐙', name:'Octopus',  habitat:'ocean',   fact:'An octopus has three hearts and blue blood!' },
  { emoji:'🐠', name:'Fish',     habitat:'ocean',   fact:'Some fish can change color to hide.' },
  { emoji:'🐒', name:'Monkey',   habitat:'jungle',  fact:'Monkeys use their tails like an extra hand.' },
  { emoji:'🦜', name:'Parrot',   habitat:'jungle',  fact:'Parrots can copy the words people say!' },
  { emoji:'🐸', name:'Frog',     habitat:'jungle',  fact:'A frog drinks water through its skin.' },
  { emoji:'🐧', name:'Penguin',  habitat:'arctic',  fact:'Penguins huddle together to stay warm.' },
  { emoji:'🐻‍❄️', name:'Polar Bear', habitat:'arctic', fact:'Polar bears have black skin under white fur!' },
  { emoji:'🦭', name:'Seal',     habitat:'arctic',  fact:'Seals can sleep underwater and float up to breathe.' },
  { emoji:'🦁', name:'Lion',     habitat:'savanna', fact:'A lion\'s roar can be heard 5 miles away!' },
  { emoji:'🦒', name:'Giraffe',  habitat:'savanna', fact:'A giraffe\'s tongue is dark blue and very long.' },
  { emoji:'🐘', name:'Elephant', habitat:'savanna', fact:'Elephants are so big they cannot jump!' },
];

// ---------- Dino eggs that hatch ----------
const DINO_EGGS = ['🦕','🦖','🦴','🐲','🐉','🦎'];
const DINO_NAMES = ['Bronto','Rexy','Stego','Tri-Tri','Ptera','Veloci'];

Object.assign(window, { SECTIONS, PHONICS, WORDS_EASY, WORDS_HARD, COUNT_EMOJIS, LETTER_SET, ALPHABET, CONFUSE, MATCH_ORDER, CARD_COLORS, TRACE_LETTERS, COUNT_ROUNDS, HABITATS, ANIMALS, DINO_EGGS, DINO_NAMES });
