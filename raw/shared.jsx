/* ============================================================
   SHARED — state, speech/phonics, HUD, confetti, reward modal
   ============================================================ */

// ---------- localStorage app state ----------
const SAVE_KEY = 'dinodig_v1';
const DEFAULT_STATE = {
  name: 'Hassan',
  xp: 40, level: 1, stars: 12, eggs: 1, streak: 3,
  soundOn: true,
  hatched: [],                 // dino egg indices hatched
  stickers: [],                // sticker ids
  animalsFound: [],            // animal names discovered
  lettersMastered: ['A','B','C','D','O','S','T','X','M'],
  lettersLearning: ['E','F','G','H','R'],
  numbersMastered: ['1','2','3','4','5','6','7','8'],
  progress: { letter: 35, number: 20, animal: 50 },
  minutesToday: 12,
  week: [14, 18, 9, 22, 16, 0, 12],   // mon..sun minutes
};

function loadState() {
  try {
    const raw = localStorage.getItem(SAVE_KEY);
    if (raw) return { ...DEFAULT_STATE, ...JSON.parse(raw) };
  } catch (e) {}
  return { ...DEFAULT_STATE };
}

function useGame() {
  const [state, setState] = React.useState(loadState);
  React.useEffect(() => {
    try { localStorage.setItem(SAVE_KEY, JSON.stringify(state)); } catch (e) {}
    window.__soundOn = state.soundOn;
  }, [state]);
  const update = (patch) => setState(s => ({ ...s, ...(typeof patch === 'function' ? patch(s) : patch) }));
  return [state, update];
}

// XP needed per level
const xpForLevel = (lvl) => 100 + (lvl - 1) * 60;

// ---------- Speech / phonics ----------
function speak(text, opts = {}) {
  if (!window.__soundOn) return;
  try {
    const synth = window.speechSynthesis;
    if (!synth) return;
    synth.cancel();
    const u = new SpeechSynthesisUtterance(text);
    u.rate = opts.rate ?? 0.92;
    u.pitch = opts.pitch ?? 1.15;
    u.volume = 1;
    synth.speak(u);
  } catch (e) {}
}
// say a letter's beginning sound then a word: "b... buh... bat!"
function sayPhonics(letter, word) {
  if (!window.__soundOn) return;
  const snd = PHONICS[letter] || letter;
  speak(`${snd}. ${word}!`, { rate: 0.85 });
}
function sayLetterSound(letter) {
  speak(PHONICS[letter] || letter, { rate: 0.8 });
}
Object.assign(window, { speak, sayPhonics, sayLetterSound });

// ---------- Confetti ----------
function Confetti({ go }) {
  const colors = ['#FF8A3D','#2BB3C6','#7BC043','#FFC53D','#FF6B6B','#8B7BE0'];
  const pieces = React.useMemo(() =>
    Array.from({ length: 70 }, (_, i) => ({
      left: Math.random() * 100,
      delay: Math.random() * 0.5,
      dur: 1.6 + Math.random() * 1.4,
      color: colors[i % colors.length],
      rot: Math.random() * 360,
      round: Math.random() > 0.6,
    })), [go]);
  if (!go) return null;
  return (
    <div className="confetti">
      {pieces.map((p, i) => (
        <i key={i} style={{
          left: p.left + '%', background: p.color,
          borderRadius: p.round ? '50%' : '3px',
          transform: `rotate(${p.rot}deg)`,
          animationDuration: p.dur + 's', animationDelay: p.delay + 's',
        }} />
      ))}
    </div>
  );
}

// ---------- Say button ----------
function SayBtn({ onClick, label = 'Hear it' }) {
  return (
    <button className="say" onClick={onClick} aria-label={label} title={label}>🔊</button>
  );
}

// ---------- Top HUD ----------
function Hud({ state, update, onCollections, onParent, title }) {
  const need = xpForLevel(state.level);
  const pct = Math.min(100, Math.round((state.xp / need) * 100));
  return (
    <div className="hud">
      <div className="avatar">
        <div className="avatar__face">🧒</div>
        <div>
          <div className="avatar__name">{state.name}</div>
          <div className="avatar__lvl">Level {state.level} • Explorer</div>
        </div>
      </div>

      <div className="xpbar" title={`${state.xp} / ${need} XP`}>
        <div className="xpbar__fill" style={{ width: pct + '%' }} />
        <div className="xpbar__txt">{state.xp} / {need} XP</div>
      </div>

      <div className="hud__spacer" />

      <div className="coin coin--streak" title="Day streak">
        <span className="ic">🔥</span>{state.streak}
      </div>
      <div className="coin coin--star" onClick={onCollections} title="Stars & collections">
        <span className="ic">⭐</span>{state.stars}
      </div>
      <div className="coin coin--egg" onClick={onCollections} title="Dino eggs">
        <span className="ic">🥚</span>{state.eggs}
      </div>

      <button className={'icon-btn' + (state.soundOn ? ' on' : '')}
        onClick={() => update(s => ({ soundOn: !s.soundOn }))}
        title="Sound on/off">{state.soundOn ? '🔊' : '🔇'}</button>
      <button className="icon-btn" onClick={onParent} title="Grown-ups">👪</button>
    </div>
  );
}

// ---------- Reward modal (shown after finishing an activity) ----------
function RewardModal({ result, onClose, onAgain }) {
  React.useEffect(() => { speak('Great job! You earned a reward!', { rate: 0.95 }); }, []);
  return (
    <div className="overlay" onClick={onClose}>
      <Confetti go={true} />
      <div className="modal" onClick={e => e.stopPropagation()}>
        <div className="starburst"><span>⭐</span><span>🏆</span><span>⭐</span></div>
        <h2>Amazing, Hassan!</h2>
        <p>{result.message || 'You finished the adventure!'}</p>
        <div className="reward-row">
          <div className="reward-pill"><span className="n">+{result.stars}</span><span className="l">⭐ Stars</span></div>
          <div className="reward-pill"><span className="n">+{result.xp}</span><span className="l">XP</span></div>
          {result.egg && <div className="reward-pill"><span className="n">🥚</span><span className="l">Dino Egg</span></div>}
          {result.sticker && <div className="reward-pill"><span className="n">{result.sticker}</span><span className="l">Sticker</span></div>}
        </div>
        <div style={{ display: 'flex', gap: 12, justifyContent: 'center' }}>
          <button className="btn btn--ghost" onClick={onClose}>🗺️ Map</button>
          <button className="btn btn--green" onClick={onAgain}>↻ Play again</button>
        </div>
      </div>
    </div>
  );
}

// award helper: returns patch + possible level-up
function applyReward(s, { stars = 0, xp = 0, egg = false, sticker = null, animal = null, progressKey = null, progressTo = null }) {
  let level = s.level, curXp = s.xp + xp;
  while (curXp >= xpForLevel(level)) { curXp -= xpForLevel(level); level++; }
  const patch = {
    stars: s.stars + stars,
    xp: curXp, level,
    eggs: s.eggs + (egg ? 1 : 0),
  };
  if (sticker) patch.stickers = [...new Set([...s.stickers, sticker])];
  if (animal) patch.animalsFound = [...new Set([...s.animalsFound, animal])];
  if (progressKey != null) patch.progress = { ...s.progress, [progressKey]: Math.max(s.progress[progressKey] || 0, progressTo) };
  patch.minutesToday = s.minutesToday + 1;
  return patch;
}

Object.assign(window, { useGame, xpForLevel, Confetti, SayBtn, Hud, RewardModal, applyReward });

/* ============================================================
   LEVELS — deal a question pool across N games of Q questions,
   so no question repeats inside one game and each is reused as
   evenly as possible (≤2× when the pool is large enough).
   ============================================================ */
function _shuffle(a) { const x = [...a]; for (let i = x.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [x[i], x[j]] = [x[j], x[i]]; } return x; }

function dealGames(pool, G = 10, Q = 15, keyOf = (x) => (x.word || x.u || x.id || JSON.stringify(x))) {
  // Fill game-by-game, always drawing the least-used items first. This
  // guarantees NO repeat within a game (when Q <= pool size) and spreads
  // usage so each item repeats as few times as possible across the G games
  // (exactly ≤2× once the pool is ≥ G*Q/2 — e.g. the number pools).
  const usage = new Map(pool.map((it) => [keyOf(it), 0]));
  const byKey = new Map(pool.map((it) => [keyOf(it), it]));
  const groups = [];
  for (let g = 0; g < G; g++) {
    const keys = _shuffle([...usage.keys()]);        // random tie-break
    keys.sort((a, b) => usage.get(a) - usage.get(b)); // least-used first (stable)
    const pick = keys.slice(0, Math.min(Q, keys.length));
    pick.forEach((k) => usage.set(k, usage.get(k) + 1));
    groups.push(_shuffle(pick.map((k) => byKey.get(k))));
  }
  return groups;
}

// per-game-type completion, persisted
function getLevels() { try { return JSON.parse(localStorage.getItem('dinodig_levels') || '{}'); } catch (e) { return {}; } }
function markLevel(typeId, g) {
  const L = getLevels(); L[typeId] = L[typeId] || []; L[typeId][g] = true;
  try { localStorage.setItem('dinodig_levels', JSON.stringify(L)); } catch (e) {}
}

Object.assign(window, { dealGames, getLevels, markLevel });
