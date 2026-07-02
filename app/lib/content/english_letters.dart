/// English letter with uppercase, lowercase, word, emoji, and phonetic.
///
/// Part of the Letter Adventure content ported from raw/data.jsx —
/// accuracy preserved exactly.
class EnglishLetter {
  final String u; // uppercase
  final String l; // lowercase
  final String word; // picture word
  final String emoji;
  final String ph; // phonetic / sound

  const EnglishLetter({
    required this.u,
    required this.l,
    required this.word,
    required this.emoji,
    required this.ph,
  });
}

class WordFamily {
  final String emoji;
  final String word;
  final String end; // fixed family ending
  final List<String> miss; // letter(s) to drag (the missing onset)
  final List<String> distract; // wrong tiles

  const WordFamily({
    required this.emoji,
    required this.word,
    required this.end,
    required this.miss,
    required this.distract,
  });
}

/// Full English alphabet: 26 letters A–Z with picture words and phonetic sounds.
const List<EnglishLetter> kEnglishLetters = [
  EnglishLetter(u: 'A', l: 'a', word: 'Apple', emoji: '🍎', ph: 'ah'),
  EnglishLetter(u: 'B', l: 'b', word: 'Bat', emoji: '🦇', ph: 'buh'),
  EnglishLetter(u: 'C', l: 'c', word: 'Cat', emoji: '🐱', ph: 'kuh'),
  EnglishLetter(u: 'D', l: 'd', word: 'Dog', emoji: '🐶', ph: 'duh'),
  EnglishLetter(u: 'E', l: 'e', word: 'Egg', emoji: '🥚', ph: 'eh'),
  EnglishLetter(u: 'F', l: 'f', word: 'Fish', emoji: '🐟', ph: 'fff'),
  EnglishLetter(u: 'G', l: 'g', word: 'Goat', emoji: '🐐', ph: 'guh'),
  EnglishLetter(u: 'H', l: 'h', word: 'Hat', emoji: '🎩', ph: 'huh'),
  EnglishLetter(u: 'I', l: 'i', word: 'Igloo', emoji: '🛖', ph: 'ih'),
  EnglishLetter(u: 'J', l: 'j', word: 'Jellyfish', emoji: '🪼', ph: 'juh'),
  EnglishLetter(u: 'K', l: 'k', word: 'Kite', emoji: '🪁', ph: 'kuh'),
  EnglishLetter(u: 'L', l: 'l', word: 'Lion', emoji: '🦁', ph: 'lll'),
  EnglishLetter(u: 'M', l: 'm', word: 'Moon', emoji: '🌙', ph: 'mmm'),
  EnglishLetter(u: 'N', l: 'n', word: 'Nest', emoji: '🪺', ph: 'nnn'),
  EnglishLetter(u: 'O', l: 'o', word: 'Octopus', emoji: '🐙', ph: 'awh'),
  EnglishLetter(u: 'P', l: 'p', word: 'Piano', emoji: '🎹', ph: 'puh'),
  EnglishLetter(u: 'Q', l: 'q', word: 'Queen', emoji: '👑', ph: 'kwuh'),
  EnglishLetter(u: 'R', l: 'r', word: 'Rainbow', emoji: '🌈', ph: 'rrr'),
  EnglishLetter(u: 'S', l: 's', word: 'Sun', emoji: '🌞', ph: 'sss'),
  EnglishLetter(u: 'T', l: 't', word: 'Tree', emoji: '🌳', ph: 'tuh'),
  EnglishLetter(u: 'U', l: 'u', word: 'Umbrella', emoji: '☂️', ph: 'uh'),
  EnglishLetter(u: 'V', l: 'v', word: 'Volcano', emoji: '🌋', ph: 'vvv'),
  EnglishLetter(u: 'W', l: 'w', word: 'Whale', emoji: '🐳', ph: 'wuh'),
  EnglishLetter(u: 'X', l: 'x', word: 'Fox', emoji: '🦊', ph: 'kss'),
  EnglishLetter(u: 'Y', l: 'y', word: 'Yo-yo', emoji: '🪀', ph: 'yuh'),
  EnglishLetter(u: 'Z', l: 'z', word: 'Zebra', emoji: '🦓', ph: 'zzz'),
];

/// Confusable lowercase pairs used to make letter matching tricky.
const Map<String, String> kConfusables = {
  'b': 'd',
  'd': 'b',
  'p': 'q',
  'q': 'p',
  'g': 'q',
  'a': 'e',
  'e': 'a',
  'n': 'h',
  'h': 'n',
  'm': 'w',
  'u': 'n',
  'y': 'g',
};

/// Uppercase letter order for 20-round match game: easy look-alikes → tricky.
const List<String> kMatchOrder = [
  'C',
  'O',
  'S',
  'X',
  'V',
  'W',
  'Z',
  'K',
  'T',
  'U',
  'L',
  'F',
  'H',
  'N',
  'M',
  'A',
  'E',
  'G',
  'P',
  'B',
];

/// Reading word families: 75 unique words (55 single-letter onsets + 20 two-letter blends).
/// Single-letter families are "easy"; two-letter blends are "hard".
const List<WordFamily> kWordFamilies = [
  // _AT
  WordFamily(emoji: '🦇', word: 'BAT', miss: ['B'], end: 'AT', distract: ['C', 'H', 'R']),
  WordFamily(emoji: '🐱', word: 'CAT', miss: ['C'], end: 'AT', distract: ['M', 'R', 'S']),
  WordFamily(emoji: '🎩', word: 'HAT', miss: ['H'], end: 'AT', distract: ['B', 'S', 'F']),
  WordFamily(emoji: '🐀', word: 'RAT', miss: ['R'], end: 'AT', distract: ['C', 'N', 'P']),
  // _AD
  WordFamily(emoji: '👨', word: 'DAD', miss: ['D'], end: 'AD', distract: ['S', 'M', 'B']),
  WordFamily(emoji: '😢', word: 'SAD', miss: ['S'], end: 'AD', distract: ['D', 'M', 'P']),
  WordFamily(emoji: '🛍️', word: 'BAG', miss: ['B'], end: 'AG', distract: ['T', 'R', 'W']),
  // _ED
  WordFamily(emoji: '🛏️', word: 'BED', miss: ['B'], end: 'ED', distract: ['R', 'T', 'L']),
  WordFamily(emoji: '🟥', word: 'RED', miss: ['R'], end: 'ED', distract: ['B', 'N', 'W']),
  // _UT
  WordFamily(emoji: '🥜', word: 'NUT', miss: ['N'], end: 'UT', distract: ['C', 'H', 'B']),
  WordFamily(emoji: '✂️', word: 'CUT', miss: ['C'], end: 'UT', distract: ['N', 'H', 'G']),
  // _AN
  WordFamily(emoji: '🚐', word: 'VAN', miss: ['V'], end: 'AN', distract: ['F', 'P', 'C']),
  WordFamily(emoji: '🪭', word: 'FAN', miss: ['F'], end: 'AN', distract: ['V', 'P', 'M']),
  WordFamily(emoji: '🍳', word: 'PAN', miss: ['P'], end: 'AN', distract: ['F', 'C', 'V']),
  WordFamily(emoji: '🥫', word: 'CAN', miss: ['C'], end: 'AN', distract: ['P', 'F', 'M']),
  // _OCK
  WordFamily(emoji: '🧦', word: 'SOCK', miss: ['S'], end: 'OCK', distract: ['L', 'R', 'D']),
  WordFamily(emoji: '🔒', word: 'LOCK', miss: ['L'], end: 'OCK', distract: ['S', 'R', 'B']),
  WordFamily(emoji: '🪨', word: 'ROCK', miss: ['R'], end: 'OCK', distract: ['S', 'L', 'M']),
  // bonus families
  WordFamily(emoji: '🖊️', word: 'PEN', miss: ['P'], end: 'EN', distract: ['T', 'D', 'B']),
  WordFamily(emoji: '🐶', word: 'DOG', miss: ['D'], end: 'OG', distract: ['L', 'F', 'H']),
  WordFamily(emoji: '🌞', word: 'SUN', miss: ['S'], end: 'UN', distract: ['B', 'R', 'F']),
  WordFamily(emoji: '🐔', word: 'HEN', miss: ['H'], end: 'EN', distract: ['T', 'P', 'D']),
  // more single-letter words
  WordFamily(emoji: '🚗', word: 'CAR', miss: ['C'], end: 'AR', distract: ['J', 'B', 'F']),
  WordFamily(emoji: '🫙', word: 'JAR', miss: ['J'], end: 'AR', distract: ['C', 'B', 'T']),
  WordFamily(emoji: '🧢', word: 'CAP', miss: ['C'], end: 'AP', distract: ['M', 'N', 'T']),
  WordFamily(emoji: '🗺️', word: 'MAP', miss: ['M'], end: 'AP', distract: ['C', 'N', 'T']),
  WordFamily(emoji: '😴', word: 'NAP', miss: ['N'], end: 'AP', distract: ['C', 'M', 'L']),
  WordFamily(emoji: '📦', word: 'BOX', miss: ['B'], end: 'OX', distract: ['F', 'C', 'M']),
  WordFamily(emoji: '🐛', word: 'BUG', miss: ['B'], end: 'UG', distract: ['M', 'R', 'J']),
  WordFamily(emoji: '☕', word: 'MUG', miss: ['M'], end: 'UG', distract: ['B', 'R', 'J']),
  WordFamily(emoji: '📌', word: 'PIN', miss: ['P'], end: 'IN', distract: ['B', 'F', 'T']),
  WordFamily(emoji: '🗑️', word: 'BIN', miss: ['B'], end: 'IN', distract: ['P', 'F', 'W']),
  WordFamily(emoji: '🍲', word: 'POT', miss: ['P'], end: 'OT', distract: ['D', 'H', 'C']),
  WordFamily(emoji: '🔥', word: 'HOT', miss: ['H'], end: 'OT', distract: ['P', 'D', 'C']),
  WordFamily(emoji: '🐮', word: 'COW', miss: ['C'], end: 'OW', distract: ['B', 'N', 'H']),
  WordFamily(emoji: '🐝', word: 'BEE', miss: ['B'], end: 'EE', distract: ['S', 'T', 'F']),
  WordFamily(emoji: '🏷️', word: 'TAG', miss: ['T'], end: 'AG', distract: ['B', 'W', 'R']),
  WordFamily(emoji: '⚽', word: 'BALL', miss: ['B'], end: 'ALL', distract: ['T', 'W', 'F']),
  WordFamily(emoji: '🔔', word: 'BELL', miss: ['B'], end: 'ELL', distract: ['T', 'S', 'W']),
  WordFamily(emoji: '💍', word: 'RING', miss: ['R'], end: 'ING', distract: ['K', 'S', 'W']),
  WordFamily(emoji: '🤴', word: 'KING', miss: ['K'], end: 'ING', distract: ['R', 'S', 'W']),
  WordFamily(emoji: '✋', word: 'HAND', miss: ['H'], end: 'AND', distract: ['S', 'B', 'L']),
  WordFamily(emoji: '🔑', word: 'KEY', miss: ['K'], end: 'EY', distract: ['B', 'T', 'M']),
  WordFamily(emoji: '🐐', word: 'GOAT', miss: ['G'], end: 'OAT', distract: ['C', 'B', 'M']),
  WordFamily(emoji: '🧥', word: 'COAT', miss: ['C'], end: 'OAT', distract: ['G', 'B', 'M']),
  WordFamily(emoji: '🍽️', word: 'DISH', miss: ['D'], end: 'ISH', distract: ['F', 'W', 'M']),
  WordFamily(emoji: '🌙', word: 'MOON', miss: ['M'], end: 'OON', distract: ['S', 'N', 'B']),
  WordFamily(emoji: '🎂', word: 'CAKE', miss: ['C'], end: 'AKE', distract: ['B', 'L', 'M']),
  WordFamily(emoji: '🦴', word: 'BONE', miss: ['B'], end: 'ONE', distract: ['C', 'T', 'N']),
  WordFamily(emoji: '🪺', word: 'NEST', miss: ['N'], end: 'EST', distract: ['B', 'R', 'T']),
  WordFamily(emoji: '🌽', word: 'CORN', miss: ['C'], end: 'ORN', distract: ['B', 'H', 'T']),
  WordFamily(emoji: '🦆', word: 'DUCK', miss: ['D'], end: 'UCK', distract: ['L', 'T', 'B']),
  WordFamily(emoji: '🪵', word: 'LOG', miss: ['L'], end: 'OG', distract: ['D', 'F', 'H']),
  WordFamily(emoji: '🕸️', word: 'WEB', miss: ['W'], end: 'EB', distract: ['B', 'R', 'T']),
  WordFamily(emoji: '🍯', word: 'JAM', miss: ['J'], end: 'AM', distract: ['H', 'R', 'D']),
  // two-letter blends (20 families)
  WordFamily(emoji: '🐸', word: 'FROG', miss: ['F', 'R'], end: 'OG', distract: ['C', 'L', 'S']),
  WordFamily(emoji: '🦀', word: 'CRAB', miss: ['C', 'R'], end: 'AB', distract: ['F', 'L', 'S']),
  WordFamily(emoji: '🚩', word: 'FLAG', miss: ['F', 'L'], end: 'AG', distract: ['R', 'C', 'S']),
  WordFamily(emoji: '⭐', word: 'STAR', miss: ['S', 'T'], end: 'AR', distract: ['P', 'R', 'C']),
  WordFamily(emoji: '🥁', word: 'DRUM', miss: ['D', 'R'], end: 'UM', distract: ['F', 'L', 'S']),
  WordFamily(emoji: '🌳', word: 'TREE', miss: ['T', 'R'], end: 'EE', distract: ['F', 'C', 'S']),
  WordFamily(emoji: '🕐', word: 'CLOCK', miss: ['C', 'L'], end: 'OCK', distract: ['R', 'S', 'B']),
  WordFamily(emoji: '🔌', word: 'PLUG', miss: ['P', 'L'], end: 'UG', distract: ['R', 'S', 'B']),
  WordFamily(emoji: '🚢', word: 'SHIP', miss: ['S', 'H'], end: 'IP', distract: ['C', 'L', 'T']),
  WordFamily(emoji: '🐟', word: 'FISH', miss: ['F', 'I'], end: 'SH', distract: ['C', 'S', 'T']),
  WordFamily(emoji: '🌟', word: 'SPIN', miss: ['S', 'P'], end: 'IN', distract: ['R', 'L', 'C']),
  WordFamily(emoji: '🧹', word: 'BROOM', miss: ['B', 'R'], end: 'OOM', distract: ['F', 'L', 'S']),
  WordFamily(emoji: '🥄', word: 'SPOON', miss: ['S', 'P'], end: 'OON', distract: ['M', 'N', 'B']),
  WordFamily(emoji: '🐍', word: 'SNAKE', miss: ['S', 'N'], end: 'AKE', distract: ['C', 'L', 'B']),
  WordFamily(emoji: '👑', word: 'CROWN', miss: ['C', 'R'], end: 'OWN', distract: ['F', 'B', 'S']),
  WordFamily(emoji: '🍞', word: 'BREAD', miss: ['B', 'R'], end: 'EAD', distract: ['F', 'L', 'S']),
  WordFamily(emoji: '🚂', word: 'TRAIN', miss: ['T', 'R'], end: 'AIN', distract: ['B', 'C', 'S']),
  WordFamily(emoji: '🧱', word: 'BRICK', miss: ['B', 'R'], end: 'ICK', distract: ['C', 'F', 'S']),
  WordFamily(emoji: '🌱', word: 'PLANT', miss: ['P', 'L'], end: 'ANT', distract: ['R', 'C', 'S']),
  WordFamily(emoji: '🐌', word: 'SNAIL', miss: ['S', 'N'], end: 'AIL', distract: ['L', 'R', 'T']),
];
