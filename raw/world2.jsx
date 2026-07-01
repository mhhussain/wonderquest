/* ============================================================
   AROUND THE WORLD — continent page, passport, controller
   ============================================================ */

/* ============================================================
   CONTINENT — animals (tap for facts) + fun facts + mission
   ============================================================ */
function Continent({ continent, world, onMission, onCards, onLeave, onCollectAnimal }) {
  const [found, setFound] = React.useState([]);   // animal names tapped
  const [cur, setCur] = React.useState(null);
  const [factI, setFactI] = React.useState(0);
  const c = continent;

  React.useEffect(() => { const t = setTimeout(() => speak(`${c.theme}! Tap the animals to learn about them.`, { rate: .92 }), 500); return () => clearTimeout(t); }, []);

  const tapAnimal = (a) => {
    setCur(a);
    speak(`${a.n}. ${a.f}`, { rate: .92 });
    if (!found.includes(a.n)) { setFound(f => [...f, a.n]); onCollectAnimal && onCollectAnimal(a.n); }
  };
  const nextFact = () => { const ni = (factI + 1) % c.facts.length; setFactI(ni); speak(c.facts[ni], { rate: .92 }); };

  return (
    <div className="act" style={{ background: `linear-gradient(180deg, ${c.color2}2e, ${c.color}1f)` }}>
      <div className="act__bar">
        <button className="back-btn" onClick={onLeave}>⟵ World</button>
        <div>
          <div className="act__title">{c.emoji} {c.name}</div>
          <div className="act__sub">{c.theme}</div>
        </div>
        <div className="hud__spacer" />
        <div className="find-count" style={{ background: c.color }}>🦁 {found.length}/{c.animals.length}</div>
      </div>

      <div className="act__body" style={{ justifyContent: 'flex-start', paddingTop: 6, gap: 14 }}>
        {/* fun fact ribbon */}
        <button className="fact-ribbon" style={{ '--c1': c.color }} onClick={nextFact}>
          <span className="fact-ribbon__icon">💡</span>
          <span className="fact-ribbon__txt">{c.facts[factI]}</span>
          <span className="fact-ribbon__say">🔊</span>
        </button>

        {/* animal grid */}
        <div className="animal-world">
          {c.animals.map((a, i) => (
            <button key={i} className={'animal-world__card' + (found.includes(a.n) ? ' seen' : '')}
              onClick={() => tapAnimal(a)}>
              <span className="animal-world__e">{a.e}</span>
              <span className="animal-world__n">{a.n}</span>
            </button>
          ))}
        </div>

        {/* current animal fact bubble */}
        <div className="animal-fact" style={cur ? { '--c1': c.color } : { opacity: .6 }}>
          {cur
            ? <><b>{cur.e} {cur.n}</b><span>{cur.f}</span></>
            : <span style={{ color: 'var(--ink-soft)', fontWeight: 700 }}>👆 Tap an animal to hear a fun fact!</span>}
        </div>

        <div className="continent-actions">
          <button className="btn btn--lg" style={{ background: c.color, boxShadow: '0 5px 0 ' + c.color2 }}
            onClick={() => onMission(c)}><span>🔍 Find the {c.mission.count} {c.mission.n}!</span></button>
          <button className="btn btn--lg btn--ghost"
            onClick={() => onCards(c)}><span>🃏 Discovery Cards</span></button>
        </div>
      </div>
    </div>
  );
}

/* ============================================================
   PASSPORT — stamps, badges, wonder cards
   ============================================================ */
function Passport({ world, onClose }) {
  const visited = world.visited || {};
  const cards = world.cards || [];
  React.useEffect(() => { speak('Here is your explorer passport!', { rate: .95 }); }, []);
  return (
    <div className="overlay" onClick={onClose}>
      <div className="passport" onClick={e => e.stopPropagation()}>
        <button className="modal__close" onClick={onClose}>✕</button>
        <div className="passport__head">
          <span style={{ fontSize: 34 }}>🛂</span>
          <div>
            <h2 style={{ margin: 0 }}>Explorer Passport</h2>
            <p style={{ margin: 0 }}>Hassan • World Explorer</p>
          </div>
          <div className="hud__spacer" />
          <div className="passport__pts">🌟 {Object.keys(visited).length * 25} pts</div>
        </div>

        <div className="passport__label">📍 Continent Stamps</div>
        <div className="passport__stamps">
          {WORLD.map(c => {
            const got = visited[c.id];
            return (
              <div key={c.id} className={'stamp' + (got ? ' got' : '')} style={got ? { '--c1': c.color } : {}}>
                <span className="stamp__e">{got ? c.badge : '❔'}</span>
                <span className="stamp__n">{c.name}</span>
                {got && <span className="stamp__ring">✓</span>}
              </div>
            );
          })}
        </div>

        <div className="passport__label">🃏 World Wonder Cards <span style={{ fontWeight: 700, color: 'var(--ink-soft)' }}>— {cards.length}/{WONDER_CARDS.length}</span></div>
        <div className="passport__cards">
          {WONDER_CARDS.map((w, i) => {
            const got = cards.includes(w.e);
            return (
              <div key={i} className={'wonder' + (got ? '' : ' locked')}
                onClick={() => got && speak(w.t, { rate: .92 })}>
                <span className="wonder__e">{got ? w.e : '🔒'}</span>
                <span className="wonder__t">{got ? w.t : 'Keep exploring!'}</span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

/* ============================================================
   CONTROLLER
   ============================================================ */
function AroundWorld({ onComplete, onExit, onAnimal }) {
  const [world, setWorld] = React.useState(loadWorld);
  const [view, setView] = React.useState('map');     // map | flying | continent | mission | cards | card
  const [active, setActive] = React.useState(null);
  const [activeCard, setActiveCard] = React.useState(null);
  const [showPass, setShowPass] = React.useState(false);

  const persist = (w) => { setWorld(w); saveWorld(w); };

  const pick = (c) => { setActive(c); setView('flying'); };
  const arrived = () => setView('continent');
  const leave = () => { setView('map'); setActive(null); };

  const collectAnimal = (name) => onAnimal && onAnimal(name);

  const startMission = (c) => setView('mission');
  const openCards = (c) => setView('cards');
  const playCard = (card) => { setActiveCard(card); setView('card'); };
  const collectCard = () => {
    const card = activeCard;
    const w = { ...world, discovery: { ...(world.discovery || {}), [card.id]: true } };
    persist(w);
    onComplete({
      stars: 2, xp: 18, sticker: card.sticker, silent: true,
      message: `You collected the ${card.title} Discovery Card!`,
      progressKey: 'world', progressTo: world.progress || 0,
    });
    setView('cards');
  };

  const missionDone = (c = active) => {
    // award stamp + badge + a wonder card + app rewards
    const card = ({ africa:'🦁', asia:'🐼', australia:'🦘', antarctica:'🐧', namerica:'🦅', samerica:'🦥', europe:'🦊' })[c.id];
    const w = {
      ...world,
      visited: { ...(world.visited||{}), [c.id]: true },
      cards: [...new Set([...(world.cards||[]), card])],
    };
    persist(w);
    onComplete({
      stars: 3, xp: 32, sticker: c.badge, egg: true,
      message: `You earned the ${c.badgeName} in ${c.name}!`,
      progressKey: 'world', progressTo: Math.round(Object.keys(w.visited).length / 7 * 100),
    });
  };

  let body;
  if (view === 'map')
    body = <WorldMap world={world} onPick={pick} onPassport={() => setShowPass(true)} onExit={onExit} />;
  else if (view === 'flying')
    body = <Travel continent={active} onArrive={arrived} />;
  else if (view === 'continent')
    body = <Continent continent={active} world={world} onMission={startMission} onCards={openCards} onLeave={leave} onCollectAnimal={collectAnimal} />;
  else if (view === 'mission')
    body = <Discovery continent={active} onDone={() => missionDone()} onBack={() => setView('continent')} />;
  else if (view === 'cards')
    body = <DiscoveryDeck continent={active} world={world} onPlay={playCard} onBack={() => setView('continent')} />;
  else if (view === 'card')
    body = <DiscoveryCard card={activeCard} color={active.color} color2={active.color2} onWin={collectCard} onExit={() => setView('cards')} />;

  return (
    <>
      {body}
      {showPass && <Passport world={world} onClose={() => setShowPass(false)} />}
    </>
  );
}

Object.assign(window, { Continent, Passport, AroundWorld });
