/* ============================================================
   WORLD DISCOVERY CARDS — data
   Each card: id, emoji, title, fact, sticker, game {type, ...params}
   game types: collect | order | build | decorate | find
   ============================================================ */

const CARD_SETS = {
  africa: [
    { e:'🏜️', title:'Sahara Desert', fact:'The Sahara is the largest hot desert on Earth. It is in Africa!', sticker:'🐪',
      game:{ type:'collect', who:'🐪', item:'💧', n:6, say:'Help the camel collect water drops!' } },
    { e:'🦒', title:'Tallest Animal', fact:'Giraffes are the tallest animals in the whole world!', sticker:'🦒',
      game:{ type:'order', items:[{e:'🐁',s:1},{e:'🐈',s:2},{e:'🦓',s:3},{e:'🦒',s:4}], say:'Tap the animals from shortest to tallest!' } },
    { e:'🦁', title:'King Lion', fact:'Lions are called the kings of the savanna.', sticker:'🦁',
      game:{ type:'find', target:'🦁', n:4, deco:['🌾','🌳','🪨','🌅'], say:'Find the hidden lion cubs!' } },
  ],
  asia: [
    { e:'🐼', title:'Giant Panda', fact:'Pandas live naturally only in Asia. They love bamboo!', sticker:'🐼',
      game:{ type:'collect', who:'🐼', item:'🎋', n:6, say:'Help the panda collect bamboo!' } },
    { e:'🏯', title:'Great Wall', fact:'The Great Wall of China is one of the longest walls ever built!', sticker:'🏯',
      game:{ type:'build', pieces:['🧱','🧱','🧱','🏯'], say:'Tap the blocks to rebuild the Great Wall!' } },
    { e:'⛰️', title:'Mount Everest', fact:'Mount Everest is the tallest mountain on Earth!', sticker:'🚩',
      game:{ type:'collect', who:'🧗', item:'🚩', n:5, say:'Climb up and collect the flags!' } },
  ],
  europe: [
    { e:'🗼', title:'Eiffel Tower', fact:'The Eiffel Tower is in Paris, France. It is made of iron!', sticker:'🗼',
      game:{ type:'build', pieces:['🟫','🔲','🔼','🗼'], say:'Stack the pieces to build the Eiffel Tower!' } },
    { e:'🏰', title:'Castles', fact:'Europe is famous for its big stone castles.', sticker:'🏰',
      game:{ type:'build', pieces:['🟫','🧱','🚪','🏰'], say:'Build your own castle, tap each piece!' } },
    { e:'🦔', title:'Hedgehog', fact:'Hedgehogs roll into a spiky ball when they feel scared.', sticker:'🦔',
      game:{ type:'find', target:'🦔', n:4, deco:['🍂','🌰','🌲','🍄'], say:'Find the hidden hedgehogs!' } },
  ],
  namerica: [
    { e:'🦅', title:'Bald Eagle', fact:'The bald eagle is a famous bird of North America.', sticker:'🦅',
      game:{ type:'collect', who:'🦅', item:'⭐', n:6, say:'Fly the eagle and collect the stars!' } },
    { e:'🦬', title:'American Bison', fact:'Bison are some of the largest animals in North America.', sticker:'🦬',
      game:{ type:'collect', who:'🦬', item:'🌾', n:6, say:'Help the bison herd find grass!' } },
    { e:'🌊', title:'Great Lakes', fact:'The Great Lakes hold a huge amount of the world\'s fresh water.', sticker:'🌊',
      game:{ type:'decorate', base:'🗺️', spot:'💧', n:5, say:'Tap to fill the Great Lakes with water!' } },
  ],
  samerica: [
    { e:'🌳', title:'Amazon Jungle', fact:'The Amazon is the largest rainforest on Earth!', sticker:'🌳',
      game:{ type:'find', target:'🐒', n:4, deco:['🌴','🌿','🍃','🌺'], say:'Find the hidden jungle monkeys!' } },
    { e:'🦥', title:'Slow Sloth', fact:'Sloths move very, very slowly through the trees.', sticker:'🦥',
      game:{ type:'order', items:[{e:'🦥',s:1},{e:'🐢',s:2},{e:'🐇',s:3},{e:'🐆',s:4}], say:'Tap the animals from slowest to fastest!' } },
    { e:'🦜', title:'Toucan', fact:'Toucans have big, colorful beaks to reach fruit.', sticker:'🦜',
      game:{ type:'decorate', base:'🦜', spot:'🌈', n:5, say:'Decorate the toucan with rainbow colors!' } },
  ],
  australia: [
    { e:'🦘', title:'Kangaroo', fact:'Kangaroos are native to Australia. Babies are called joeys!', sticker:'🦘',
      game:{ type:'collect', who:'🦘', item:'👶', n:5, say:'Hop and collect the baby joeys!' } },
    { e:'🐨', title:'Sleepy Koala', fact:'Koalas sleep for most of the day in gum trees.', sticker:'🐨',
      game:{ type:'collect', who:'🐨', item:'🌿', n:6, say:'Help the koala find eucalyptus leaves!' } },
    { e:'🐠', title:'Great Reef', fact:'The Great Barrier Reef is the largest coral reef in the world!', sticker:'🐠',
      game:{ type:'find', target:'🐠', n:5, deco:['🪸','🐚','🌊','🦀'], say:'Find the colorful reef fish!' } },
  ],
  antarctica: [
    { e:'🐧', title:'Penguin', fact:'Penguins live in icy Antarctica and slide on their bellies!', sticker:'🐧',
      game:{ type:'collect', who:'🐧', item:'🐟', n:6, say:'Slide the penguin and catch the fish!' } },
    { e:'❄️', title:'Coldest Place', fact:'Antarctica is the coldest continent on Earth. Bundle up!', sticker:'🧣',
      game:{ type:'decorate', base:'🧑', spot:'🧣', n:4, say:'Dress the explorer warmly for the cold!' } },
    { e:'🐋', title:'Blue Whale', fact:'The blue whale is the largest animal that has ever lived!', sticker:'🐋',
      game:{ type:'order', items:[{e:'🐟',s:1},{e:'🐬',s:2},{e:'🦈',s:3},{e:'🐋',s:4}], say:'Tap the sea animals from smallest to biggest!' } },
  ],
};

// flat list with continent + id
const ALL_CARDS = [];
Object.keys(CARD_SETS).forEach(cont => CARD_SETS[cont].forEach((c, i) => ALL_CARDS.push({ ...c, id: cont + '-' + i, cont })));

Object.assign(window, { CARD_SETS, ALL_CARDS });
