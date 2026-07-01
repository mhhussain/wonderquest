/* ============================================================
   HOOROF — Games B: Find, Shape Builder, Letter Pop, Safari
   + dashboard
   ============================================================ */

/* ---------- Find the Letter (reuses SpotScene) ---------- */
function HrfFind({ onComplete, onExit }) {
  const rounds = React.useMemo(() => _hShuffle(HRF).slice(0, 4), []);
  const [i, setI] = React.useState(0);
  const h = rounds[i];
  const decoy = React.useMemo(() => {
    const fam = hrfFamily(h.g);
    const extra = _hShuffle(HRF.map(x => x.g).filter(g => g !== h.g && !fam.includes(g))).slice(0, 5);
    return [...fam, ...extra, ...fam];
  }, [i]);
  const n = 3 + (i % 3);
  return <SpotScene key={i}
    title={`Find the Letter (${i + 1}/4)`} emoji="🔎"
    sceneName={`Find the letter ${h.tr}`} bg="#FBEFD2"
    goals={[{ c: h.g, n, l: h.tr }]} decoy={decoy} decoyCount={24}
    mode="find" color="var(--teal-d)"
    onWin={() => { if (i + 1 >= 4) onComplete({ stars: 3, xp: 28, egg: true, sticker: '🔎', message: 'Sharp eyes! You found all the letters!', progressKey: 'letter', progressTo: 55 }); else setI(i + 1); }}
    onExit={onExit} />;
}

/* ---------- Safari Letter Hunt ---------- */
const HRF_SAFARI = ['🌴','🐪','🏜️','⛺','🌵','🪨','☀️','🐫','🧺','🫖'];
function HrfSafari({ onComplete, onExit }) {
  const rounds = React.useMemo(() => _hShuffle(['ا','ب','م','ل','س','ت']).slice(0, 3), []);
  const [i, setI] = React.useState(0);
  const g = rounds[i];
  const h = HRF_BY_G[g];
  const decoy = React.useMemo(() => {
    const fam = hrfFamily(g);
    return [...HRF_SAFARI, ...fam, ...HRF_SAFARI];
  }, [i]);
  const n = 3;
  return <SpotScene key={i}
    title={`Safari Letter Hunt (${i + 1}/3)`} emoji="🐪"
    sceneName={`Desert hunt — find ${h.tr}`} bg="#F2D98C"
    goals={[{ c: g, n, l: h.tr }]} decoy={decoy} decoyCount={22}
    mode="find" color="var(--orange-d)"
    onWin={() => { if (i + 1 >= 3) onComplete({ stars: 3, xp: 30, egg: true, sticker: '🐪', message: 'Desert letter explorer!', progressKey: 'letter', progressTo: 60 }); else setI(i + 1); }}
    onExit={onExit} />;
}

/* ---------- Shape Builder (add the dots) ---------- */
// build a dotted letter from its dotless base + the right dots
const DOT_OPTIONS = ['1a','2a','3a','1b','2b','0'];   // a=above b=below, count
function dotLabel(d) {
  const map = { '1a':'1 dot above', '2a':'2 dots above', '3a':'3 dots above', '1b':'1 dot below', '2b':'2 dots below', '0':'no dots' };
  return map[d] || d;
}
function HrfBuilder({ onComplete, onExit }) {
  const dotted = React.useMemo(() => _hShuffle(HRF.filter(h => h.base && h.dots)).slice(0, 6), []);
  const [i, setI] = React.useState(0);
  const [picked, setPicked] = React.useState(null);
  const [done, setDone] = React.useState(false);
  const h = dotted[i];
  const options = React.useMemo(() => {
    const wrong = _hShuffle(DOT_OPTIONS.filter(d => d !== h.dots)).slice(0, 2);
    return _hShuffle([h.dots, ...wrong]);
  }, [i]);

  React.useEffect(() => { setPicked(null); setDone(false); const t = setTimeout(() => speakArabic(`أَضِف النُّقَط لِتَصْنَع ${h.nm}`, `Add the dots to make ${h.tr}`), 400); return () => clearTimeout(t); }, [i]);

  const choose = (d) => {
    if (done) return;
    setPicked(d);
    if (d === h.dots) {
      setDone(true); sayLetter(h, false);
      setTimeout(() => { if (i + 1 >= dotted.length) onComplete({ stars: 3, xp: 26, sticker: '🖍️', message: 'You built the letters with the right dots!', progressKey: 'letter', progressTo: 50 }); else setI(i + 1); }, 1300);
    } else { setTimeout(() => setPicked(p => p === d ? null : p), 500); }
  };

  // render dots overlay on the base
  const Dots = ({ d }) => {
    const cnt = parseInt(d[0]) || 0; const above = d[1] === 'a';
    if (!cnt) return null;
    return <span className={'hrf-dots ' + (above ? 'above' : 'below')}>{'•'.repeat(cnt).split('').map((x, k) => <i key={k} />)}</span>;
  };

  return (
    <div className="act hrf-bg" dir="ltr">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Hoorof</button>
        <div><div className="act__title">🖍️ Shape Builder</div>
          <div className="act__sub">Add the dots to build the letter</div></div>
        <div className="hud__spacer" />
        <div className="dots" dir="ltr">{dotted.map((_, k) => <i key={k} className={k < i ? 'done' : k === i ? 'cur' : ''} />)}</div>
      </div>
      <div className="act__body" style={{ gap: 18 }}>
        <div className="hrf-target">Make: <b>{h.tr}</b> <button className="say" onClick={() => sayLetter(h, false)}>🔊</button></div>
        <div className="hrf-build-stage">
          <span className="hrf-build-base">{done ? h.g : h.base}</span>
        </div>
        <div className="hrf-dotopts">
          {options.map((d, k) => {
            const isPick = picked === d;
            const cls = isPick ? (d === h.dots ? ' ok' : ' no') : '';
            return (
              <button key={k} className={'hrf-dotopt' + cls} onClick={() => choose(d)}>
                <span className="hrf-dotopt__demo">
                  <span className="hrf-dotopt__base">{h.base}</span>
                  <Dots d={d} />
                </span>
                <span className="hrf-dotopt__lbl">{dotLabel(d)}</span>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

/* ---------- Letter Pop (balloons) ---------- */
function HrfPop({ onComplete, onExit }) {
  const GOAL = 6;
  const [target, setTarget] = React.useState(() => HRF[Math.floor(Math.random() * HRF.length)]);
  const [balloons, setBalloons] = React.useState([]);
  const [score, setScore] = React.useState(0);
  const [pop, setPop] = React.useState(null);
  const idRef = React.useRef(0);
  const targetRef = React.useRef(target);
  const scoreRef = React.useRef(0);
  const wonRef = React.useRef(false);
  const COLORS = ['#FF8A3D','#2BB3C6','#7BC043','#FF6B6B','#8B7BE0','#4AA8E0','#F472A8','#FFC53D'];

  React.useEffect(() => { targetRef.current = target; }, [target]);
  React.useEffect(() => { const t = setTimeout(() => speakArabic(`جِد ${target.nm}`, `Find ${target.tr}`), 400); return () => clearTimeout(t); }, [target]);

  // spawn balloons
  React.useEffect(() => {
    const spawn = setInterval(() => {
      setBalloons(bs => {
        if (bs.length > 7) return bs;
        const tgt = targetRef.current;
        // ~40% chance the spawned balloon is the current target
        const isT = Math.random() < 0.42;
        let g = isT ? tgt.g : _hShuffle(HRF.map(h => h.g).filter(x => x !== tgt.g))[0];
        const id = ++idRef.current;
        return [...bs, { id, g, left: 6 + Math.random() * 84, color: COLORS[id % COLORS.length], dur: 6 + Math.random() * 3 }];
      });
    }, 850);
    return () => clearInterval(spawn);
  }, []);

  const remove = (id) => setBalloons(bs => bs.filter(b => b.id !== id));

  const tap = (b, e) => {
    if (b.g === targetRef.current.g) {
      const ns = scoreRef.current + 1; scoreRef.current = ns; setScore(ns);
      setPop({ x: e.clientX, y: e.clientY, id: Date.now() });
      setTimeout(() => setPop(null), 500);
      speak(String(ns), { rate: .95, pitch: 1.2 });
      remove(b.id);
      if (ns >= GOAL && !wonRef.current) { wonRef.current = true; setTimeout(() => onComplete({ stars: 4, xp: 30, egg: true, sticker: '🎈', message: 'Pop star! You found all the letters!', progressKey: 'letter', progressTo: 55 }), 600); }
      else {
        // new target every 2 correct
        if (ns % 2 === 0) { const nt = HRF[Math.floor(Math.random() * HRF.length)]; setTarget(nt); }
      }
    } else {
      remove(b.id);
      speakArabic('لا، حاوِل مَرَّة أُخْرَى', 'No, try again');
    }
  };

  return (
    <div className="act hrf-bg" dir="ltr">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Hoorof</button>
        <div><div className="act__title">🎈 Letter Pop</div>
          <div className="act__sub">Pop the matching letter!</div></div>
        <div className="hud__spacer" />
        <div className="hrf-pop-target">Find <b>{target.g}</b> <button className="say" onClick={() => speakArabic(`جِد ${target.nm}`, `Find ${target.tr}`)}>🔊</button></div>
        <div className="spot-counter" style={{ background: 'var(--coral)', marginInlineStart: 10 }} dir="ltr">🎈 {score}/{GOAL}</div>
      </div>
      <div className="act__body" style={{ paddingTop: 0 }}>
        <div className="hrf-sky">
          {balloons.map(b => (
            <button key={b.id} className="balloon" style={{ left: b.left + '%', '--bc': b.color, animationDuration: b.dur + 's' }}
              onClick={(e) => tap(b, e)} onAnimationEnd={() => remove(b.id)}>
              <span className="balloon__g">{b.g}</span>
              <span className="balloon__tie" />
            </button>
          ))}
          {pop && <span key={pop.id} className="balloon-pop" style={{ left: pop.x, top: pop.y }}>💥</span>}
        </div>
        <div className="spot-hint">🎈 Pop the correct balloon before it floats away!</div>
      </div>
    </div>
  );
}

/* ---------- Hoorof dashboard ---------- */
const HRF_CARDS = [
  { id:'learn',  title:'تَعَلَّم الحَرْف', en:'Learn the Letter', emoji:'🔤', color:'var(--teal)' },
  { id:'trace',  title:'اِرْسُم الحَرْف',  en:'Trace the Letter', emoji:'✏️', color:'var(--green)' },
  { id:'hear',   title:'اِسْمَع وَطابِق',  en:'Hear & Match',     emoji:'🎧', color:'var(--grape)' },
  { id:'memory', title:'طابِق الحُرُوف',   en:'Match the Letters',emoji:'🧩', color:'var(--orange)' },
  { id:'find',   title:'جِد الحَرْف',      en:'Find the Letter',  emoji:'🔎', color:'var(--yellow)' },
  { id:'build',  title:'اِبْنِ الحَرْف',    en:'Shape Builder',    emoji:'🖍️', color:'var(--pink)' },
  { id:'pop',    title:'فَرْقِع الحَرْف',   en:'Letter Pop',       emoji:'🎈', color:'var(--coral)' },
  { id:'safari', title:'صَحْرَاء الحُرُوف', en:'Safari Letter Hunt',emoji:'🐪', color:'var(--sky)' },
];
const HRF_GAMES = { learn:HrfLearn, trace:HrfTrace, hear:HrfHearMatch, memory:HrfMemory, find:HrfFind, build:HrfBuilder, pop:HrfPop, safari:HrfSafari };

function Hoorof({ onComplete, onExit }) {
  const [game, setGame] = React.useState(null);
  React.useEffect(() => { if (!game) { const t = setTimeout(() => speak('Hoorof! Pick a game'), 300); return () => clearTimeout(t); } }, [game]);
  if (game) { const G = HRF_GAMES[game]; return <G onComplete={onComplete} onExit={() => setGame(null)} />; }
  return (
    <div className="act hrf-dash-bg" dir="ltr">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Map</button>
        <div><div className="act__title">🐪 Hoorof — Arabic Letters</div>
          <div className="act__sub">Arabic Letter Adventure — tap, hear, trace & find!</div></div>
      </div>
      <div className="act__body" style={{ justifyContent: 'center' }}>
        <div className="hrf-dash">
          {HRF_CARDS.map(c => (
            <button key={c.id} className="hrf-dashcard" style={{ background: c.color }} onClick={() => { speak(c.en); setGame(c.id); }}>
              <span className="hrf-dashcard__deco" />
              <span className="hrf-dashcard__e">{c.emoji}</span>
              <span className="hrf-dashcard__t" dir="ltr">{c.en}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { HrfFind, HrfSafari, HrfBuilder, HrfPop, Hoorof });
