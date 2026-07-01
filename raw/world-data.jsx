/* ============================================================
   AROUND THE WORLD — data: 7 continents
   ============================================================ */

const WORLD = [
  {
    id: 'africa', name: 'Africa', emoji: '🦁', theme: 'Safari Adventure',
    color: '#E8893B', color2: '#F2B441', badge: '🦁', badgeName: 'Safari Badge',
    blurb: "Let's go on a safari!",
    facts: [
      'Africa has the world\'s largest hot desert — the Sahara!',
      'Giraffes are the tallest animals on Earth.',
      'Elephants are the largest land animals.',
    ],
    animals: [
      { e: '🦁', n: 'Lion',     f: "A lion's roar can be heard 5 miles away!" },
      { e: '🐘', n: 'Elephant', f: 'Elephants are so big they cannot jump!' },
      { e: '🦒', n: 'Giraffe',  f: "A giraffe's tongue is dark blue and very long." },
      { e: '🦓', n: 'Zebra',    f: 'Every zebra has its own pattern of stripes.' },
      { e: '🦛', n: 'Hippo',    f: 'Hippos can hold their breath underwater for 5 minutes.' },
      { e: '🐆', n: 'Cheetah',  f: 'Cheetahs are the fastest animals on land!' },
    ],
    mission: { find: '🦁', n: 'lions', count: 4 },
  },
  {
    id: 'asia', name: 'Asia', emoji: '🐼', theme: 'Panda Mountain',
    color: '#D85B6A', color2: '#F2899A', badge: '🐼', badgeName: 'Panda Badge',
    blurb: 'Climb the panda mountains!',
    facts: [
      'Asia is the largest continent on Earth.',
      'Pandas come from the mountains of Asia.',
      'Mount Everest, the tallest mountain, is in Asia.',
    ],
    animals: [
      { e: '🐼', n: 'Panda',        f: 'Pandas eat bamboo for 12 hours every day!' },
      { e: '🐯', n: 'Tiger',        f: 'Tigers are the biggest wild cats in the world.' },
      { e: '🦧', n: 'Orangutan',    f: 'Orangutans build a new nest in the trees every night.' },
      { e: '🐆', n: 'Snow Leopard', f: 'Snow leopards wrap their long tails around them like a scarf.' },
      { e: '🦝', n: 'Red Panda',    f: 'Red pandas are about the size of a house cat.' },
      { e: '🐘', n: 'Elephant',     f: 'Asian elephants have smaller ears than African ones.' },
    ],
    mission: { find: '🐼', n: 'pandas', count: 4 },
  },
  {
    id: 'australia', name: 'Australia', emoji: '🦘', theme: 'Outback Discovery',
    color: '#C9742E', color2: '#E8A54B', badge: '🦘', badgeName: 'Outback Badge',
    blurb: 'Hop across the outback!',
    facts: [
      'Australia is both a country AND a continent.',
      'Kangaroos can hop as fast as a car drives in town!',
      'Koalas sleep up to 20 hours every day.',
    ],
    animals: [
      { e: '🦘', n: 'Kangaroo', f: 'Baby kangaroos are called joeys and ride in a pouch.' },
      { e: '🐨', n: 'Koala',    f: 'Koalas sleep most of the day in gum trees.' },
      { e: '🦡', n: 'Wombat',   f: 'Wombat poop is shaped like little cubes!' },
      { e: '🐦', n: 'Emu',      f: 'Emus are big birds that cannot fly but run very fast.' },
      { e: '🐊', n: 'Crocodile',f: 'Saltwater crocodiles are the largest reptiles alive.' },
      { e: '🐠', n: 'Reef Fish',f: 'The Great Barrier Reef is the biggest coral reef on Earth.' },
    ],
    mission: { find: '🦘', n: 'kangaroos', count: 3 },
  },
  {
    id: 'antarctica', name: 'Antarctica', emoji: '🐧', theme: 'Frozen Mission',
    color: '#4C8FB5', color2: '#8FC4DE', badge: '🐧', badgeName: 'Polar Badge',
    blurb: 'Explore the frozen ice!',
    facts: [
      'Antarctica is the coldest place on Earth.',
      'No people live there forever — only visiting scientists.',
      'It is covered by a thick blanket of ice.',
    ],
    animals: [
      { e: '🐧', n: 'Penguin', f: 'Penguins huddle together to stay warm in the cold.' },
      { e: '🦭', n: 'Seal',    f: 'Seals can sleep underwater and float up to breathe.' },
      { e: '🐋', n: 'Whale',   f: 'The blue whale is the largest animal that ever lived!' },
      { e: '🐦‍⬛', n: 'Skua',  f: 'Skuas are brave birds that fly over the icy sea.' },
      { e: '🦐', n: 'Krill',   f: 'Tiny krill feed almost every animal in Antarctica.' },
      { e: '❄️', n: 'Ice',     f: 'Antarctic ice can be thousands of years old.' },
    ],
    mission: { find: '🐧', n: 'penguins', count: 5 },
  },
  {
    id: 'namerica', name: 'North America', emoji: '🦅', theme: 'Forest & Lakes',
    color: '#5C9E58', color2: '#92C77E', badge: '🦅', badgeName: 'Forest Badge',
    blurb: 'Discover forests and lakes!',
    facts: [
      'North America has the huge Great Lakes — like inland seas.',
      'The bald eagle is a famous bird found here.',
      'It has tall mountains, big forests, and wide canyons.',
    ],
    animals: [
      { e: '🐻', n: 'Bear',       f: 'Bears take a long winter sleep called hibernation.' },
      { e: '🦬', n: 'Bison',      f: 'Bison are the largest land animals in North America.' },
      { e: '🦅', n: 'Bald Eagle', f: 'Bald eagles build the biggest nests of any bird.' },
      { e: '🫎', n: 'Moose',      f: 'Moose are great swimmers and love the water.' },
      { e: '🦝', n: 'Raccoon',    f: 'Raccoons wash their food with their clever paws.' },
      { e: '🦫', n: 'Beaver',     f: 'Beavers build dams across rivers with sticks.' },
    ],
    mission: { find: '🦅', n: 'eagles', count: 4 },
  },
  {
    id: 'samerica', name: 'South America', emoji: '🦥', theme: 'Amazon Rainforest',
    color: '#3FA68A', color2: '#7CCBB0', badge: '🦥', badgeName: 'Jungle Badge',
    blurb: 'Swing through the rainforest!',
    facts: [
      'The Amazon is the biggest rainforest in the world.',
      'Sloths move so slowly that plants grow on their fur!',
      'It is home to more kinds of animals than anywhere else.',
    ],
    animals: [
      { e: '🦥', n: 'Sloth',    f: 'Sloths sleep up to 15 hours and move very, very slowly.' },
      { e: '🦙', n: 'Llama',    f: 'Llamas hum to talk to each other.' },
      { e: '🐆', n: 'Jaguar',   f: 'Jaguars are great swimmers and love the water.' },
      { e: '🦫', n: 'Capybara', f: 'Capybaras are the largest rodents in the world.' },
      { e: '🦜', n: 'Toucan',   f: 'A toucan\'s big colorful beak helps it reach fruit.' },
      { e: '🐒', n: 'Monkey',   f: 'Monkeys use their tails like an extra hand.' },
    ],
    mission: { find: '🦥', n: 'sloths', count: 3 },
  },
  {
    id: 'europe', name: 'Europe', emoji: '🦊', theme: 'Castles & Forests',
    color: '#8E72C7', color2: '#B7A2E0', badge: '🏰', badgeName: 'Castle Badge',
    blurb: 'Visit castles and forests!',
    facts: [
      'Europe has thousands of old castles to explore.',
      'Some of the world\'s oldest cities are in Europe.',
      'You can ride trains between many countries.',
    ],
    animals: [
      { e: '🦔', n: 'Hedgehog', f: 'Hedgehogs roll into a spiky ball when they feel scared.' },
      { e: '🦊', n: 'Fox',      f: 'Foxes can hear a mouse moving under the snow.' },
      { e: '🦌', n: 'Deer',     f: 'Deer grow new antlers on their heads every year.' },
      { e: '🦉', n: 'Owl',      f: 'Owls can turn their heads almost all the way around.' },
      { e: '🐗', n: 'Boar',     f: 'Wild boars love to roll in the mud to stay cool.' },
      { e: '🐿️', n: 'Squirrel', f: 'Squirrels hide thousands of nuts to eat in winter.' },
    ],
    mission: { find: '🦊', n: 'foxes', count: 4 },
  },
];

// World Wonder cards (collectible)
const WONDER_CARDS = [
  { e: '🐼', t: 'Pandas live in Asia.' },
  { e: '🦘', t: 'Kangaroos live in Australia.' },
  { e: '🐧', t: 'Penguins thrive in Antarctica.' },
  { e: '🦁', t: 'Lions roam the African safari.' },
  { e: '🦥', t: 'Sloths hang in South America.' },
  { e: '🦅', t: 'Bald eagles soar in North America.' },
  { e: '🦊', t: 'Foxes roam European forests.' },
];

Object.assign(window, { WORLD, WONDER_CARDS });
