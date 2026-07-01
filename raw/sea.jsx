/* ============================================================
   UNDER THE SEA — ocean animals + Whale World
   (part of Amazing Animal Planet)
   ============================================================ */

/* most-interesting ocean facts */
const OCEAN_FACTS = [
  { e:'🐙', n:'Octopus',   f:'An octopus can grow back an arm if it loses one! It also has THREE hearts and blue blood.' },
  { e:'🪼', n:'Jellyfish', f:'Jellyfish have no brain, no heart, and no bones — and some glow in the dark!' },
  { e:'⭐', n:'Starfish',  f:'A starfish can grow a whole new arm, and it pushes its stomach OUT to eat!' },
  { e:'🦈', n:'Shark',     f:'Sharks have lived in the ocean longer than there have been trees on Earth!' },
  { e:'🐡', n:'Pufferfish',f:'A pufferfish puffs up into a spiky ball to scare away anything hungry.' },
  { e:'🦐', n:'Pistol Shrimp', f:'The pistol shrimp snaps its claw so fast it makes a tiny flash of light and a loud POP!' },
  { e:'🐬', n:'Dolphin',   f:'Dolphins give each other names using special whistle sounds!' },
  { e:'🦦', n:'Sea Otter', f:'Sea otters hold hands while they sleep so they don\'t float apart.' },
  { e:'🐢', n:'Sea Turtle',f:'A sea turtle can hold its breath underwater for hours while it naps.' },
  { e:'🦀', n:'Crab',      f:'Crabs walk sideways and can taste their food with their feet!' },
];

/* whale types — picture, fact, dive depth, sound pitch */
const WHALES = [
  { e:'🐋', n:'Blue Whale',     color:'#3F77C9', dive:200,
    f:'The blue whale is the BIGGEST animal that ever lived — its heart is as big as a small car!', base:54 },
  { e:'🐳', n:'Humpback Whale', color:'#2E8B8B', dive:200,
    f:'Humpback whales sing long songs that can last for hours, and they leap right out of the water!', base:90 },
  { e:'🐋', n:'Sperm Whale',    color:'#6A5ACD', dive:2000,
    f:'The sperm whale dives DEEPER than any other whale — over 2 kilometers down to hunt giant squid!', base:46 },
  { e:'🐳', n:'Orca',           color:'#222b33',
    dive:150, f:'The orca, or killer whale, is actually the largest dolphin and hunts together in family pods!', base:130 },
  { e:'🐋', n:'Beluga Whale',   color:'#7Fb5d6', dive:700,
    f:'The white beluga is called the "canary of the sea" because it chirps and whistles so much!', base:150 },
  { e:'🦄', n:'Narwhal',        color:'#5C8AC9', dive:1500,
    f:'The narwhal is the "unicorn of the sea" — its long tusk is really a giant tooth!', base:120 },
];

/* synthesized whale-call using Web Audio (no audio files needed) */
function whaleCall(base = 80) {
  if (!window.__soundOn) return;
  try {
    const Ctx = window.AudioContext || window.webkitAudioContext;
    const ctx = window.__actx || (window.__actx = new Ctx());
    if (ctx.state === 'suspended') ctx.resume();
    const t = ctx.currentTime;
    const o = ctx.createOscillator(); o.type = 'sine';
    const g = ctx.createGain();
    o.frequency.setValueAtTime(base, t);
    o.frequency.exponentialRampToValueAtTime(base * 1.9, t + 0.6);
    o.frequency.exponentialRampToValueAtTime(base * 0.75, t + 1.7);
    const lfo = ctx.createOscillator(); lfo.frequency.value = 5.5;
    const lfoG = ctx.createGain(); lfoG.gain.value = base * 0.07;
    lfo.connect(lfoG).connect(o.frequency);
    g.gain.setValueAtTime(0, t);
    g.gain.linearRampToValueAtTime(0.28, t + 0.25);
    g.gain.linearRampToValueAtTime(0.26, t + 1.5);
    g.gain.linearRampToValueAtTime(0, t + 2.2);
    o.connect(g).connect(ctx.destination);
    o.start(t); lfo.start(t); o.stop(t + 2.3); lfo.stop(t + 2.3);
  } catch (e) {}
}

/* ---------- Ocean Facts activity ---------- */
function OceanFacts({ onComplete, onExit }) {
  const cards = React.useMemo(() => shuffle(OCEAN_FACTS).slice(0, 8), []);
  const [found, setFound] = React.useState([]);
  const [cur, setCur] = React.useState(null);
  const allDone = found.length === cards.length;

  React.useEffect(() => { const t = setTimeout(() => speak('Tap a sea creature to learn an amazing fact!', { rate: .92 }), 400); return () => clearTimeout(t); }, []);

  const tap = (a) => {
    setCur(a);
    speak(`${a.n}. ${a.f}`, { rate: .92 });
    if (!found.includes(a.n)) setFound(f => [...f, a.n]);
  };

  return (
    <div className="act sea-bg">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div><div className="act__title">🫧 Ocean Facts</div>
          <div className="act__sub">Tap each sea creature for an amazing fact</div></div>
        <div className="hud__spacer" />
        <div className="find-count" style={{ background: 'var(--sky)' }}>🐚 {found.length}/{cards.length}</div>
      </div>
      <div className="act__body" style={{ justifyContent: 'flex-start', paddingTop: 8, gap: 14 }}>
        <div className="sea-fact" style={cur ? null : { opacity: .7 }}>
          {cur ? <><b>{cur.e} {cur.n}</b><span>{cur.f}</span></>
               : <span style={{ color: 'var(--ink-soft)', fontWeight: 700 }}>👆 Tap a sea creature below to hear something amazing!</span>}
        </div>
        <div className="sea-grid">
          {cards.map((a, i) => (
            <button key={i} className={'sea-card' + (found.includes(a.n) ? ' seen' : '')} onClick={() => tap(a)}>
              <span className="sea-card__e">{a.e}</span>
              <span className="sea-card__n">{a.n}</span>
            </button>
          ))}
        </div>
        {allDone && (
          <button className="btn btn--lg" style={{ background: 'var(--sky)', boxShadow: '0 5px 0 var(--sky-d)' }}
            onClick={() => onComplete({ stars: 3, xp: 26, egg: true, sticker: '🐙', message: 'You learned all the ocean facts!', progressKey: 'animal', progressTo: 70 })}>
            <span>I learned them all! ⭐</span></button>
        )}
      </div>
    </div>
  );
}

/* ---------- Whale World activity ---------- */
function WhaleWorld({ onComplete, onExit }) {
  const [sel, setSel] = React.useState(0);
  const [heard, setHeard] = React.useState([]);
  const w = WHALES[sel];
  const maxDepth = 2000;

  React.useEffect(() => { const t = setTimeout(() => speak('Welcome to Whale World! Tap a whale to meet it.', { rate: .92 }), 400); return () => clearTimeout(t); }, []);
  React.useEffect(() => {
    const t = setTimeout(() => speak(w.n, { rate: .9 }), 250);
    setHeard(h => h.includes(sel) ? h : [...h, sel]);
    return () => clearTimeout(t);
  }, [sel]);

  const hearCall = () => { speak(`${w.n} says…`, { rate: .9 }); setTimeout(() => whaleCall(w.base), 700); };

  return (
    <div className="act sea-bg sea-bg--deep">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div><div className="act__title">🐋 Whale World</div>
          <div className="act__sub">Meet the whales — hear their calls & see their dives</div></div>
        <div className="hud__spacer" />
        <div className="find-count" style={{ background: 'var(--sky)' }}>🐋 {heard.length}/{WHALES.length}</div>
      </div>

      <div className="act__body" style={{ justifyContent: 'flex-start', paddingTop: 6 }}>
        <div className="whale-layout">
          {/* whale picker */}
          <div className="whale-list">
            {WHALES.map((wh, i) => (
              <button key={i} className={'whale-pick' + (i === sel ? ' on' : '')}
                style={i === sel ? { background: wh.color } : null} onClick={() => setSel(i)}>
                <span className="whale-pick__e">{wh.e}</span>
                <span className="whale-pick__n">{wh.n}</span>
              </button>
            ))}
          </div>

          {/* detail */}
          <div className="whale-detail" style={{ '--wc': w.color }}>
            <div className="whale-hero">
              <div className="whale-pic">
                <span className="whale-pic__e">{w.e}</span>
                <image-slot id={'whale-' + w.n.replace(/\s/g,'')} class="whale-photo" shape="rounded" radius="18"
                  placeholder={'photo of a ' + w.n}></image-slot>
              </div>
              <div className="whale-info">
                <h3>{w.n}</h3>
                <p>{w.f}</p>
                <div className="whale-btns">
                  <button className="btn" style={{ background: w.color, boxShadow: '0 4px 0 rgba(0,0,0,.2)' }} onClick={hearCall}>
                    <span>🔊 Hear its call</span></button>
                  <button className="btn btn--ghost" onClick={() => speak(`${w.n}. ${w.f}`, { rate: .9 })}><span>📖 Read fact</span></button>
                </div>
              </div>
            </div>

            {/* dive depth meter */}
            <div className="dive">
              <div className="dive__label">🌊 How deep does it dive?</div>
              <div className="dive__meter">
                <div className="dive__fill" style={{ height: Math.max(8, w.dive / maxDepth * 100) + '%', background: w.color }}>
                  <span className="dive__whale">{w.e}</span>
                </div>
                <span className="dive__depth">{w.dive} m deep</span>
                <span className="dive__floor">🪨 sea floor</span>
              </div>
            </div>

            {/* video placeholder */}
            <div className="whale-video">
              <div className="whale-video__frame">
                <button className="whale-video__play" onClick={() => speak(`Watch the ${w.n} dive deep into the ocean!`, { rate: .92 })}>▶</button>
                <span className="whale-video__cap">{w.n} dive video</span>
              </div>
              <div className="whale-video__hint">🎬 Drop a real {w.n} video clip here</div>
            </div>
          </div>
        </div>

        {heard.length === WHALES.length && (
          <button className="btn btn--lg" style={{ background: 'var(--sky)', boxShadow: '0 5px 0 var(--sky-d)', marginTop: 6 }}
            onClick={() => onComplete({ stars: 3, xp: 28, egg: true, sticker: '🐋', message: 'You met every kind of whale!', progressKey: 'animal', progressTo: 75 })}>
            <span>I met all the whales! ⭐</span></button>
        )}
      </div>
    </div>
  );
}

/* ---------- Under the Sea menu ---------- */
function UnderTheSea({ onComplete, onExit }) {
  const [game, setGame] = React.useState(null);
  const games = [
    { id: 'facts',  title: 'Ocean Facts',  sub: 'Amazing sea creatures', emoji: '🫧', color: 'var(--sky)' },
    { id: 'whales', title: 'Whale World',  sub: 'Calls, dives & videos',  emoji: '🐋', color: 'var(--teal)' },
  ];
  if (game === 'facts')  return <OceanFacts onComplete={onComplete} onExit={() => setGame(null)} />;
  if (game === 'whales') return <WhaleWorld onComplete={onComplete} onExit={() => setGame(null)} />;
  return <ActivityMenu title="Under the Sea" emoji="🌊" tagline="Dive in to meet amazing ocean animals!" games={games} onPick={setGame} onExit={onExit} />;
}

Object.assign(window, { OCEAN_FACTS, WHALES, whaleCall, OceanFacts, WhaleWorld, UnderTheSea });
