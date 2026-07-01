/* ============================================================
   SPOT ME IF YOU CAN — dashboard + game wrappers
   ============================================================ */

// run a sequence of rounds, awarding once the set is done
function useRounds(rounds, onComplete, reward) {
  const [i, setI] = React.useState(0);
  const next = () => { if (i + 1 >= rounds.length) onComplete(reward(i + 1)); else setI(i + 1); };
  return [rounds[i], i, rounds.length, next];
}

/* ---------- Hidden Object Hunt ---------- */
function HuntGame({ onComplete, onExit }) {
  const rounds = React.useMemo(() => _spShuffle(HUNT_ROUNDS).slice(0, 4), []);
  const [round, i, total, next] = useRounds(rounds, onComplete, (n) => ({ stars: 3, xp: 30, egg: true, sticker: '🔍', message: `You found everything in ${n} scenes!`, progressKey: 'find', progressTo: 60 }));
  const sc = SPOT_SCENES[round.scene];
  const targetChars = round.goals.map(g => g.c);
  const decoy = sc.deco.filter(d => !targetChars.includes(d));
  return <SpotScene key={i} title={`Hidden Hunt (${i + 1}/${total})`} emoji="🔍" sceneName={sc.name} bg={sc.bg} dark={sc.dark}
    goals={round.goals} decoy={decoy} decoyCount={28} mode="find" color="var(--yellow-d)" onWin={next} onExit={onExit} />;
}

/* ---------- Animal Tracker ---------- */
function AnimalTracker({ onComplete, onExit }) {
  const rounds = React.useMemo(() => _spShuffle(ANIMAL_ROUNDS), []);
  const [round, i, total, next] = useRounds(rounds, onComplete, (n) => ({ stars: 3, xp: 28, egg: true, sticker: '🐾', message: 'You tracked every animal!', progressKey: 'find', progressTo: 55 }));
  const sc = SPOT_SCENES[round.scene];
  return <SpotScene key={i} title={`Animal Tracker (${i + 1}/${total})`} emoji="🐾" sceneName={sc.name} bg={sc.bg}
    goals={round.goals} decoy={round.deco} decoyCount={22} mode="find" color="var(--green-d)" onWin={next} onExit={onExit} />;
}

/* ---------- Count It If You Can ---------- */
function CountIt({ onComplete, onExit }) {
  const rounds = React.useMemo(() => _spShuffle(COUNT_ROUNDS_SPOT).slice(0, 5), []);
  const [round, i, total, next] = useRounds(rounds, onComplete, () => ({ stars: 3, xp: 26, sticker: '🔢', message: 'You counted them all!', progressKey: 'find', progressTo: 50 }));
  const sc = SPOT_SCENES[round.scene];
  const n = 3 + Math.floor(Math.random() * 6);
  const goals = [{ c: round.c, n, l: round.l }];
  return <SpotScene key={i} title={`Count It (${i + 1}/${total})`} emoji="🔢" sceneName={sc.name} bg={sc.bg}
    goals={goals} decoy={round.deco} decoyCount={20} mode="count" color="var(--teal-d)" onWin={next} onExit={onExit} />;
}

/* ---------- Letter / Number / Shape Detective (single-target find) ---------- */
function SingleFind({ rounds, title, emoji, color, reward, onComplete, onExit }) {
  const list = React.useMemo(() => _spShuffle(rounds), []);
  const [round, i, total, next] = useRounds(list, onComplete, reward);
  const sc = SPOT_SCENES[round.scene];
  const goals = [{ c: round.target, n: round.n, l: round.l }];
  // decoys are the look-alike pool (letters/numbers/shapes)
  return <SpotScene key={i} title={`${title} (${i + 1}/${total})`} emoji={emoji} sceneName={`${sc.name} — find ${round.l}`} bg={sc.bg}
    goals={goals} decoy={round.pool} decoyCount={26} mode="find" color={color} onWin={next} onExit={onExit} />;
}
const LetterDetective = (p) => <SingleFind {...p} rounds={LETTER_ROUNDS} title="Letter Detective" emoji="🔤" color="var(--orange-d)"
  reward={() => ({ stars: 3, xp: 28, sticker: '🔤', message: 'Great letter spotting!', progressKey: 'find', progressTo: 55 })} />;
const NumberDetective = (p) => <SingleFind {...p} rounds={NUMBER_ROUNDS} title="Number Detective" emoji="🔢" color="var(--sky-d)"
  reward={() => ({ stars: 3, xp: 28, sticker: '🔢', message: 'Number detective star!', progressKey: 'find', progressTo: 50 })} />;
const ShapeSafari = (p) => <SingleFind {...p} rounds={SHAPE_ROUNDS} title="Shape Safari" emoji="🔺" color="var(--grape-d)"
  reward={() => ({ stars: 3, xp: 26, sticker: '🔺', message: 'You spotted all the shapes!', progressKey: 'find', progressTo: 50 })} />;

/* ---------- Color Quest ---------- */
function ColorQuest({ onComplete, onExit }) {
  const rounds = React.useMemo(() => _spShuffle(COLOR_ROUNDS), []);
  const [round, i, total, next] = useRounds(rounds, onComplete, () => ({ stars: 3, xp: 26, sticker: '🎨', message: 'Colorful detective work!', progressKey: 'find', progressTo: 50 }));
  const sc = SPOT_SCENES[round.scene];
  const grp = COLOR_GROUPS[round.target];
  // targets: pick distinct color items; decoys: items from OTHER color groups
  const targets = React.useMemo(() => _spShuffle(grp.items).slice(0, round.n).map(c => c), [i]);
  const decoy = React.useMemo(() => Object.keys(COLOR_GROUPS).filter(k => k !== round.target)
    .flatMap(k => COLOR_GROUPS[k].items), [i]);
  // build goals as one goal but with mixed target chars → use a custom goal per target char
  const goals = targets.map((c, k) => ({ c, n: 1, l: grp.l }));
  return <SpotScene key={i} title={`Color Quest (${i + 1}/${total})`} emoji="🎨" sceneName={`${sc.name} — find ${grp.l} things`} bg={sc.bg}
    goals={goals} decoy={decoy} decoyCount={20} mode="find" color={grp.sw} headerExtra={grp}
    onWin={next} onExit={onExit} />;
}

/* ---------- Match the Socks (levels) ---------- */
function SocksGame({ onComplete, onExit }) {
  const [round, i, total, next] = useRounds(SOCK_LEVELS, onComplete, () => ({ stars: 3, xp: 28, egg: true, sticker: '🧦', message: 'You matched every sock!', progressKey: 'find', progressTo: 55 }));
  return <MatchSocks key={i} level={i} onWin={next} onExit={onExit} />;
}

/* ---------- Spot the Difference (rounds) ---------- */
function DiffGame({ onComplete, onExit }) {
  const rounds = React.useMemo(() => [
    { scene: 'beach', diffs: 4, extra: ['🐠','⛵','🐬'] },
    { scene: 'playground', diffs: 5, extra: ['🐦','🪁','🐕'] },
    { scene: 'museum', diffs: 5, extra: ['🦖','🦴','🥚'] },
  ], []);
  const [round, i, total, next] = useRounds(rounds, onComplete, () => ({ stars: 3, xp: 30, egg: true, sticker: '🆚', message: 'Sharp eyes! You found every difference!', progressKey: 'find', progressTo: 60 }));
  return <SpotDifference key={i} round={round} onWin={next} onExit={onExit} />;
}

/* ---------- Dashboard ---------- */
const SPOT_CARDS = [
  { id:'hunt',   title:'Hidden Object Hunt', sub:'Find the things',     emoji:'🔍', color:'var(--yellow)' },
  { id:'socks',  title:'Match the Socks',    sub:'Find the pairs',      emoji:'🧦', color:'var(--grape)' },
  { id:'count',  title:'Count It If You Can',sub:'Tap & count',         emoji:'🔢', color:'var(--teal)' },
  { id:'letter', title:'Letter Detective',   sub:'Find the letters',    emoji:'🔤', color:'var(--orange)' },
  { id:'shape',  title:'Shape Safari',       sub:'Find the shapes',     emoji:'🔺', color:'var(--grape)' },
  { id:'animal', title:'Animal Tracker',     sub:'Find the animals',    emoji:'🐾', color:'var(--green)' },
  { id:'diff',   title:'Spot the Difference',sub:'Whats changed?',      emoji:'🆚', color:'var(--coral)' },
  { id:'color',  title:'Color Quest',        sub:'Find by color',       emoji:'🎨', color:'var(--pink)' },
  { id:'number', title:'Number Detective',   sub:'Find the numbers',    emoji:'🕵️', color:'var(--sky)' },
];

const SPOT_GAMES = { hunt:HuntGame, socks:SocksGame, count:CountIt, letter:LetterDetective,
  shape:ShapeSafari, animal:AnimalTracker, diff:DiffGame, color:ColorQuest, number:NumberDetective };

function SpotMe({ onComplete, onExit }) {
  const [game, setGame] = React.useState(null);
  React.useEffect(() => { if (!game) speak('Spot me if you can! Pick a detective game.', { rate: .92 }); }, [game]);
  if (game) {
    const G = SPOT_GAMES[game];
    return <G onComplete={onComplete} onExit={() => setGame(null)} />;
  }
  return (
    <div className="act spot-dash-bg">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Map</button>
        <div><div className="act__title">🔍 Spot Me If You Can!</div>
          <div className="act__sub">Become a super detective — tap, find & count!</div></div>
      </div>
      <div className="act__body" style={{ justifyContent: 'center' }}>
        <div className="spot-dash">
          {SPOT_CARDS.map(c => (
            <button key={c.id} className="spot-dashcard" style={{ background: c.color }}
              onClick={() => { speak(c.title, { rate: .95 }); setGame(c.id); }}>
              <span className="spot-dashcard__deco" />
              <span className="spot-dashcard__e">{c.emoji}</span>
              <span className="spot-dashcard__t">{c.title}</span>
              <span className="spot-dashcard__s">{c.sub}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { SpotMe });
