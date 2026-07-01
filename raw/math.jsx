/* ============================================================
   LITTLE MATH LAB — visual addition, subtraction & comparing
   Objects first; the equation is revealed only after solving.
   Stations share the app's level + reward system.
   ============================================================ */

/* ---------- helpers ---------- */
const FOODS = [
{ e: '🍎', n: 'apples' }, { e: '🍌', n: 'bananas' }, { e: '🍓', n: 'strawberries' },
{ e: '🍇', n: 'grapes' }, { e: '🍊', n: 'oranges' }, { e: '🥕', n: 'carrots' },
{ e: '🌽', n: 'corn cobs' }, { e: '🥦', n: 'broccoli' }, { e: '🍉', n: 'watermelons' },
{ e: '🍐', n: 'pears' }, { e: '🍑', n: 'peaches' }, { e: '🍒', n: 'cherries' },
{ e: '🍅', n: 'tomatoes' }, { e: '🥔', n: 'potatoes' }, { e: '🍆', n: 'eggplants' },
{ e: '🥒', n: 'cucumbers' }, { e: '🫐', n: 'blueberries' }, { e: '🥝', n: 'kiwis' },
{ e: '🍍', n: 'pineapples' }, { e: '🥬', n: 'lettuce' }];

const ZOO_ANIMALS = [
{ e: '🦁', n: 'lions' }, { e: '🐘', n: 'elephants' }, { e: '🦒', n: 'giraffes' },
{ e: '🐵', n: 'monkeys' }, { e: '🦓', n: 'zebras' }, { e: '🐯', n: 'tigers' },
{ e: '🦛', n: 'hippos' }, { e: '🐍', n: 'snakes' }, { e: '🦩', n: 'flamingos' },
{ e: '🐧', n: 'penguins' }, { e: '🐢', n: 'turtles' }, { e: '🦘', n: 'kangaroos' },
{ e: '🐼', n: 'pandas' }, { e: '🦜', n: 'parrots' }, { e: '🐪', n: 'camels' },
{ e: '🦏', n: 'rhinos' }, { e: '🐊', n: 'crocodiles' }, { e: '🦚', n: 'peacocks' }];

const GEMS = [
{ e: '💎', n: 'diamonds' }, { e: '🔴', n: 'rubies' }, { e: '🔵', n: 'sapphires' },
{ e: '🟢', n: 'emeralds' }, { e: '🟣', n: 'amethysts' }, { e: '🟡', n: 'gold stones' },
{ e: '🟠', n: 'amber stones' }, { e: '⚪', n: 'pearls' }, { e: '🔶', n: 'topaz gems' },
{ e: '🔷', n: 'aqua gems' }, { e: '🟤', n: 'bronze stones' }, { e: '🪙', n: 'gold coins' }];

function _mathChoices(answer, n = 4, lo = 0, hi = 20) {
  const set = new Set([answer]);
  while (set.size < n) {
    const d = answer + (Math.floor(Math.random() * 5) - 2);
    if (d >= lo && d <= hi && d !== answer) set.add(d);
  }
  return shuffle([...set]);
}
function ObjGroup({ emoji, count, counted, base, onTap, tint }) {
  return (
    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, justifyContent: 'center', maxWidth: 300 }}>
      {Array.from({ length: count }).map((_, k) => {
        const id = base + k;
        const on = counted.includes(id);
        return (
          <button key={id} onClick={() => onTap(id)}
          style={{
            border: 'none', background: 'transparent', cursor: 'pointer', fontSize: 46, lineHeight: 1, padding: 0,
            transform: on ? 'scale(1.16)' : 'scale(1)', transition: 'transform .16s',
            filter: tint ? 'none' : 'none'
          }}>
            <span style={{ position: 'relative' }}>
              {emoji}
              {on && <span style={{
                position: 'absolute', top: -8, right: -10, fontSize: 15, background: 'var(--green)', color: '#fff',
                borderRadius: '50%', width: 21, height: 21, display: 'grid', placeItems: 'center',
                fontFamily: 'var(--font-head)', fontWeight: 800
              }}>{counted.indexOf(id) + 1}</span>}
            </span>
          </button>);

      })}
    </div>);

}

/* A clearly-readable open treasure chest holding its contents on a light tray */
function TreasureChest({ children }) {
  return (
    <div className="tchest">
      <div className="tchest__lid" aria-hidden="true" />
      <span className="tchest__strap tchest__strap--l" aria-hidden="true" />
      <span className="tchest__strap tchest__strap--r" aria-hidden="true" />
      <div className="tchest__body">
        <span className="tchest__lock" aria-hidden="true" />
        <div className="tchest__inside">{children}</div>
      </div>
    </div>);

}

/* ============================================================
   COUNT — "How many lions are in the zoo?"
   Tap each animal to count, then pick the number.
   ============================================================ */
function ZooCountGame({ deck, theme, onComplete, onExit }) {
  const rounds = React.useMemo(() => (deck || []).slice().sort((a, b) => a.count - b.count), []);
  const N = rounds.length;
  // a distinct zoo animal per round (no repeats within a game)
  const animals = React.useMemo(() => shuffle(ZOO_ANIMALS).slice(0, N), []);
  const [i, setI] = React.useState(0);
  const [counted, setCounted] = React.useState([]);
  const [picked, setPicked] = React.useState(null);
  const r = rounds[i];
  const a = animals[i] || { e: '🦁', n: 'animals' };
  const ans = r.count;
  const choices = React.useMemo(() => _mathChoices(ans, 4, 1, 12), [i]);
  const solved = picked === ans;

  React.useEffect(() => {setCounted([]);setPicked(null);
    const t = setTimeout(() => speak(`How many ${a.n} are in the zoo? Tap each one to count!`, { rate: .9 }), 350);
    return () => clearTimeout(t);}, [i]);

  const tap = (id) => {if (counted.includes(id)) return;const nx = [...counted, id];setCounted(nx);speak(String(nx.length), { rate: .9, pitch: 1.2 });};
  const choose = (n) => {
    if (solved) return;setPicked(n);
    if (n === ans) {
      speak(`Yes! ${ans} ${a.n}!`, { rate: .9 });
      setTimeout(() => {if (i + 1 >= N) onComplete({ stars: 3, xp: 28, egg: true, message: 'You counted the whole zoo!', progressKey: 'math', progressTo: 50 });else setI(i + 1);}, 1500);
    } else setTimeout(() => setPicked((p) => p === n ? null : p), 500);
  };

  return (
    <div className="act">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div><div className="act__title">{theme.emoji} {theme.title}</div>
          <div className="act__sub">Tap each animal, then pick how many</div></div>
        <div className="hud__spacer" />
        <div className="act__sub" style={{ marginRight: 10 }}>Round {i + 1} / {N}</div>
        <div className="xpbar" style={{ maxWidth: 150 }}><div className="xpbar__fill" style={{ width: i / N * 100 + '%', background: 'linear-gradient(90deg,var(--orange),var(--yellow))' }} /></div>
      </div>

      <div className="act__body">
        <div className="prompt" style={{ fontSize: 24 }}>
          <span>How many {a.e} in the zoo?</span>
          <SayBtn onClick={() => speak(`How many ${a.n} are in the zoo?`, { rate: .9 })} />
        </div>

        <div className="scene-card" style={{ minWidth: 480, minHeight: 180, justifyContent: 'center', padding: '22px 28px' }}>
          <ObjGroup emoji={a.e} count={r.count} counted={counted} base={0} onTap={tap} />
          {solved && <div style={{ marginTop: 10, fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 56, color: 'var(--orange-d)', animation: 'pop .4s' }}>{ans} {a.e}</div>}
        </div>

        <div className="match-grid" style={{ gridTemplateColumns: 'repeat(4, 92px)' }}>
          {choices.map((n, k) => {const cls = picked === n ? n === ans ? ' match-ok' : ' match-no' : '';return (
            <button key={k} className={'card-btn' + cls} style={{ height: 92, fontSize: 56, color: 'var(--orange-d)' }} onClick={() => choose(n)}>{n}</button>);})}
        </div>
      </div>
    </div>);

}

/* ============================================================
   ADDITION — "Rex has 2 🍎. Give him 3 more!"
   ============================================================ */
function AddGame({ deck, theme, onComplete, onExit }) {
  const rounds = React.useMemo(() => (deck || []).slice().sort((a, b) => a.a + a.b - (b.a + b.b)), []);
  const N = rounds.length;
  // a distinct fruit/veggie (or gemstone) per round — no repeats within a game
  const variedPool = theme.gems ? GEMS : FOODS;
  const foods = React.useMemo(() => theme.varied || theme.gems ? shuffle(variedPool).slice(0, N) : null, []);
  const [i, setI] = React.useState(0);
  const [counted, setCounted] = React.useState([]);
  const [picked, setPicked] = React.useState(null);
  const r = rounds[i];
  const food = foods ? foods[i] : { e: theme.obj, n: theme.obj_name };
  const ans = r.a + r.b;
  const choices = React.useMemo(() => _mathChoices(ans), [i]);
  const solved = picked === ans;

  React.useEffect(() => {setCounted([]);setPicked(null);
    const t = setTimeout(() => speak(`${theme.char} has ${r.a} ${food.n}. Give ${r.b} more! How many altogether?`, { rate: .9 }), 350);
    return () => clearTimeout(t);}, [i]);

  const tap = (id) => {if (counted.includes(id)) return;const nx = [...counted, id];setCounted(nx);speak(String(nx.length), { rate: .9, pitch: 1.2 });};
  const choose = (n) => {
    if (solved) return;setPicked(n);
    if (n === ans) {
      speak(`${r.a} plus ${r.b} equals ${ans}!`, { rate: .9 });
      setTimeout(() => {if (i + 1 >= N) onComplete({ stars: 3, xp: 30, egg: true, message: 'You added like a math star!', progressKey: 'math', progressTo: 60 });else setI(i + 1);}, 1600);
    } else setTimeout(() => setPicked((p) => p === n ? null : p), 500);
  };

  return (
    <div className="act">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div><div className="act__title">{theme.emoji} {theme.title}</div>
          <div className="act__sub">Count them all together</div></div>
        <div className="hud__spacer" />
        <div className="act__sub" style={{ marginRight: 10 }}>Round {i + 1} / {N}</div>
        <div className="xpbar" style={{ maxWidth: 150 }}><div className="xpbar__fill" style={{ width: i / N * 100 + '%', background: 'linear-gradient(90deg,var(--green),var(--teal))' }} /></div>
      </div>

      <div className="act__body">
        <div className="prompt" style={{ fontSize: 24 }}>
          <span>{theme.char} has {r.a} {food.e}, give {r.b} more!</span>
          <SayBtn onClick={() => speak(`${theme.char} has ${r.a} ${food.n}. Give ${r.b} more!`, { rate: .9 })} />
        </div>

        {theme.gems ?
        <TreasureChest>
            <ObjGroup emoji={food.e} count={r.a} counted={counted} base={0} onTap={tap} />
            <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 46, color: '#7a4e1d' }}>➕</div>
            <ObjGroup emoji={food.e} count={r.b} counted={counted} base={100} onTap={tap} />
            {solved && <div style={{ marginLeft: 8, fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 60, color: '#7a4e1d', animation: 'pop .4s' }}>= {ans}</div>}
          </TreasureChest> :

        <div className="scene-card" style={{ flexDirection: 'row', gap: 18, alignItems: 'center', minWidth: 520, minHeight: 180, padding: '22px 28px' }}>
            <ObjGroup emoji={food.e} count={r.a} counted={counted} base={0} onTap={tap} />
            <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 46, color: 'var(--green-d)' }}>➕</div>
            <ObjGroup emoji={food.e} count={r.b} counted={counted} base={100} onTap={tap} />
            {solved && <div style={{ marginLeft: 8, fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 60, color: 'var(--green-d)', animation: 'pop .4s' }}>= {ans}</div>}
          </div>}


        <div className="match-grid" style={{ gridTemplateColumns: 'repeat(4, 116px)' }}>
          {choices.map((n, k) => {const cls = picked === n ? n === ans ? ' match-ok' : ' match-no' : '';return (
              <button key={k} className={'card-btn' + cls} style={{ height: 116, fontSize: 72, color: 'var(--green-d)' }} onClick={() => choose(n)}>{n}</button>);})}
        </div>
      </div>
    </div>);

}

/* ============================================================
   SUBTRACTION — "There were 5 🥚. 2 hatched. How many left?"
   ============================================================ */
function SubGame({ deck, theme, onComplete, onExit }) {
  const rounds = React.useMemo(() => (deck || []).slice().sort((a, b) => a.total - b.total), []);
  const N = rounds.length;
  const [i, setI] = React.useState(0);
  const [picked, setPicked] = React.useState(null);
  const r = rounds[i];
  const ans = r.total - r.take;
  const choices = React.useMemo(() => _mathChoices(ans), [i]);
  const solved = picked === ans;

  React.useEffect(() => {setPicked(null);
    const t = setTimeout(() => speak(`There were ${r.total} ${theme.obj_name}. ${r.take} ${theme.action}. How many are left?`, { rate: .9 }), 350);
    return () => clearTimeout(t);}, [i]);

  const choose = (n) => {
    if (solved) return;setPicked(n);
    if (n === ans) {
      speak(`${r.total} take away ${r.take} equals ${ans}!`, { rate: .9 });
      setTimeout(() => {if (i + 1 >= N) onComplete({ stars: 3, xp: 30, egg: true, message: 'Super subtracting!', progressKey: 'math', progressTo: 55 });else setI(i + 1);}, 1600);
    } else setTimeout(() => setPicked((p) => p === n ? null : p), 500);
  };

  return (
    <div className="act">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div><div className="act__title">{theme.emoji} {theme.title}</div>
          <div className="act__sub">How many are left?</div></div>
        <div className="hud__spacer" />
        <div className="act__sub" style={{ marginRight: 10 }}>Round {i + 1} / {N}</div>
        <div className="xpbar" style={{ maxWidth: 150 }}><div className="xpbar__fill" style={{ width: i / N * 100 + '%', background: 'linear-gradient(90deg,var(--coral),var(--orange))' }} /></div>
      </div>

      <div className="act__body">
        <div className="prompt" style={{ fontSize: 24 }}>
          <span>{r.total} {theme.obj}, {r.take} {theme.action}!</span>
          <SayBtn onClick={() => speak(`There were ${r.total} ${theme.obj_name}. ${r.take} ${theme.action}.`, { rate: .9 })} />
        </div>

        <div className="scene-card" style={{ minWidth: 480, minHeight: 170, justifyContent: 'center', padding: '22px 28px', position: 'relative', overflow: 'visible' }}>
          {theme.monkey && <div className="monkey-eat" key={'monkey' + i} aria-hidden="true">
            <span className="vine">🌿</span><span className="monkey">🐵</span>
          </div>}
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10, justifyContent: 'center', maxWidth: 440 }}>
            {Array.from({ length: r.total }).map((_, k) => {
              const gone = k >= r.total - r.take;
              if (gone && theme.monkey) {
                // super-transparent "ghost" where the cookie used to be
                return <span key={k} style={{ fontSize: 46, lineHeight: 1, opacity: .12, filter: 'grayscale(1)' }}>{theme.obj}</span>;
              }
              if (gone && theme.hatch) {
                // egg cracks open and a baby dino pops out (staggered)
                const babies = ['🦕', '🦖', '🐉'];
                const baby = babies[k % babies.length];
                const d = (k - (r.total - r.take)) * 0.4;
                return (
                  <span key={`hatch-${i}-${k}`} className="egg-hatch" style={{ '--d': d + 's' }}>
                    <span className="shell">🥚</span>
                    <span className="crack">💥</span>
                    <span className="baby">{baby}</span>
                  </span>
                );
              }
              return <span key={k} style={{ fontSize: 46, lineHeight: 1, transition: 'opacity .4s, transform .4s',
                opacity: gone ? .22 : 1, transform: gone ? 'scale(.8) translateY(-6px)' : 'none',
                filter: gone ? 'grayscale(1)' : 'none' }}>{gone ? theme.gone : theme.obj}</span>;
            })}
          </div>
          {solved && <div style={{ marginTop: 10, fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 52, color: 'var(--coral-d)', animation: 'pop .4s' }}>{r.total} − {r.take} = {ans}</div>}
        </div>

        <div className="match-grid" style={{ gridTemplateColumns: 'repeat(4, 116px)' }}>
          {choices.map((n, k) => {const cls = picked === n ? n === ans ? ' match-ok' : ' match-no' : '';return (
              <button key={k} className={'card-btn' + cls} style={{ height: 116, fontSize: 72, color: 'var(--coral-d)' }} onClick={() => choose(n)}>{n}</button>);})}
        </div>
      </div>
    </div>);

}

/* ============================================================
   MORE OR LESS — tap the group with more (or fewer)
   ============================================================ */
function CompareGame({ deck, theme, onComplete, onExit }) {
  const rounds = React.useMemo(() => (deck || []).map((d, k) => ({ ...d, more: k % 2 === 0 })), []);
  const N = rounds.length;
  const [i, setI] = React.useState(0);
  const [picked, setPicked] = React.useState(null);
  const r = rounds[i];
  const want = r.more ? 'more' : 'fewer';
  const correct = r.more ? r.a > r.b ? 'A' : 'B' : r.a < r.b ? 'A' : 'B';
  const solved = picked === correct;

  React.useEffect(() => {setPicked(null);
    const t = setTimeout(() => speak(`Which group has ${want}?`, { rate: .92 }), 350);
    return () => clearTimeout(t);}, [i]);

  const choose = (side) => {
    if (solved) return;setPicked(side);
    if (side === correct) {
      speak(`Yes! That group has ${want}.`, { rate: .92 });
      setTimeout(() => {if (i + 1 >= N) onComplete({ stars: 3, xp: 26, sticker: '⚖️', message: 'You know more and less!', progressKey: 'math', progressTo: 50 });else setI(i + 1);}, 1100);
    } else setTimeout(() => setPicked(null), 500);
  };

  const panel = (side, count) =>
  <button onClick={() => choose(side)}
  style={{ border: '5px solid ' + (picked === side ? side === correct ? 'var(--green)' : 'var(--coral)' : 'transparent'),
    background: '#fff', borderRadius: 'var(--r-lg)', boxShadow: 'var(--shadow)', cursor: 'pointer',
    padding: 18, width: 320, minHeight: 230, display: 'flex', flexWrap: 'wrap', gap: 8,
    alignContent: 'center', justifyContent: 'center', transition: 'border-color .15s, transform .12s',
    transform: picked === side && side === correct ? 'scale(1.03)' : 'scale(1)' }}>
      {Array.from({ length: count }).map((_, k) => <span key={k} style={{ fontSize: 40, lineHeight: 1 }}>{theme.obj}</span>)}
      {solved && side === correct && <div style={{ width: '100%', textAlign: 'center', marginTop: 6, fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 26, color: 'var(--green-d)' }}>{count}!</div>}
    </button>;


  return (
    <div className="act">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div><div className="act__title">{theme.emoji} {theme.title}</div>
          <div className="act__sub">Compare the two groups</div></div>
        <div className="hud__spacer" />
        <div className="act__sub" style={{ marginRight: 10 }}>Round {i + 1} / {N}</div>
        <div className="xpbar" style={{ maxWidth: 150 }}><div className="xpbar__fill" style={{ width: i / N * 100 + '%', background: 'linear-gradient(90deg,var(--grape),var(--sky))' }} /></div>
      </div>

      <div className="act__body">
        <div className="prompt"><span>Which group has <b style={{ color: r.more ? 'var(--green-d)' : 'var(--coral-d)' }}>{want === 'more' ? 'MORE' : 'FEWER'}</b>?</span>
          <SayBtn onClick={() => speak(`Which group has ${want}?`, { rate: .92 })} /></div>
        <div style={{ display: 'flex', gap: 24 }}>
          {panel('A', r.a)}
          {panel('B', r.b)}
        </div>
      </div>
    </div>);

}

/* ============================================================
   STATION MAP + routing through GameLevels
   ============================================================ */
const MATH_STATIONS = [
{ id: 'snack', title: 'Dino Snack Time', emoji: '🦖', color: 'var(--green)', type: 'add', obj: '🍎', obj_name: 'apples', char: 'Rex', varied: true },
{ id: 'zoo', title: 'Count the Zoo', emoji: '🦁', color: 'var(--orange)', type: 'count', obj: '🦁', obj_name: 'animals' },
{ id: 'gems', title: 'Treasure Hunt', emoji: '💎', color: 'var(--teal)', type: 'add', obj: '💎', obj_name: 'gems', char: 'The chest', gems: true },
{ id: 'eggs', title: 'Lost Dino Eggs', emoji: '🥚', color: 'var(--coral)', type: 'sub', obj: '🥚', obj_name: 'eggs', action: 'hatched', gone: '🦕', hatch: true },
{ id: 'cookie', title: 'Cookie Math', emoji: '🍪', color: 'var(--yellow)', type: 'sub', obj: '🍪', obj_name: 'cookies', action: 'were eaten', gone: '😋', monkey: true },
{ id: 'morles', title: 'More or Less', emoji: '⚖️', color: 'var(--grape)', type: 'compare', obj: '🦕' }];


function makeAddPool() {
  const out = [];for (let a = 1; a <= 9; a++) for (let b = 1; b <= 9; b++) if (a + b <= 16) out.push({ a, b });
  return out;
}
function makeSubPool() {
  const out = [];for (let total = 2; total <= 12; total++) for (let take = 1; take < total; take++) out.push({ total, take });
  return out;
}
function makeCountPool() {
  const out = [];for (let count = 1; count <= 12; count++) out.push({ count });
  return out;
}
function makeComparePool() {
  const out = [];for (let a = 1; a <= 12; a++) for (let b = 1; b <= 12; b++) if (a !== b) out.push({ a, b });
  return out;
}

function MathLab({ onComplete, onExit }) {
  const [station, setStation] = React.useState(null);
  const pools = React.useMemo(() => ({ add: makeAddPool(), sub: makeSubPool(), count: makeCountPool(), compare: makeComparePool() }), []);

  React.useEffect(() => {if (!station) speak('Welcome to the Math Lab! Pick an adventure.', { rate: .95 });}, [station]);

  if (station) {
    const s = station;
    const pool = pools[s.type];
    const keyOf = s.type === 'add' ? (x) => x.a + '+' + x.b : s.type === 'sub' ? (x) => x.total + '-' + x.take : s.type === 'count' ? (x) => 'c' + x.count : (x) => x.a + 'v' + x.b;
    const Game = s.type === 'add' ? AddGame : s.type === 'sub' ? SubGame : s.type === 'count' ? ZooCountGame : CompareGame;
    return <GameLevels typeId={'math_' + s.id} title={s.title} emoji={s.emoji} color={s.color}
    pool={pool} keyOf={keyOf} games={4} perGame={10} onComplete={onComplete} onExit={() => setStation(null)}
    render={(deck, g, done, exit) => <Game deck={deck} theme={s} onComplete={done} onExit={exit} />} />;
  }

  return (
    <div className="act sky-bg">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Map</button>
        <div><div className="act__title">➕ Little Math Lab</div>
          <div className="act__sub">Help everyone with counting, adding and taking away!</div></div>
      </div>
      <div className="act__body" style={{ justifyContent: 'center' }}>
        <div className="lands" style={{ gridTemplateColumns: 'repeat(3, 240px)', gap: 18 }}>
          {MATH_STATIONS.map((s) =>
          <button key={s.id} className="land" style={{ background: s.color, minHeight: 150 }}
          onClick={() => {speak(s.title, { rate: .95 });setStation(s);}}>
              <span className="land__deco" />
              <span className="land__emoji" style={{ fontSize: 50 }}>{s.emoji}</span>
              <span className="land__title">{s.title}</span>
              <span className="land__sub">{s.type === 'add' ? 'Adding' : s.type === 'sub' ? 'Taking away' : s.type === 'count' ? 'Counting' : 'More or less'}</span>
              <span className="land__pill">▶ Play</span>
            </button>
          )}
        </div>
      </div>
    </div>);

}

Object.assign(window, { MathLab });