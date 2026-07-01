/* ============================================================
   HOME — Dino Expedition Map dashboard
   ============================================================ */

function Land({ s, progress, onOpen }) {
  const locked = !s.playable;
  return (
    <button
      className={'land' + (locked ? ' land--locked' : '')}
      style={{ background: s.color }}
      onClick={() => { if (!locked) { speak(s.title, { rate: .95 }); onOpen(s.id); } else { speak('Coming soon!', { rate: .95 }); } }}
    >
      <span className="land__deco" />
      <span className="land__deco2" />
      {s.playable
        ? <span className="land__pill">▶ Play</span>
        : <span className="land__pill">🔒 Soon</span>}
      <span className="land__emoji">{s.emoji}</span>
      <span className="land__title">{s.title}</span>
      <span className="land__sub">{s.sub}</span>
      {s.playable && (
        <span className="land__progress"><i style={{ width: (progress || 0) + '%' }} /></span>
      )}
      {locked && <span className="land__lock">🔒</span>}
    </button>
  );
}

function Home({ state, update, onOpen, onCollections, onParent }) {
  const playable = SECTIONS.filter(s => s.playable);
  const soon = SECTIONS.filter(s => !s.playable);
  const tips = [
    "Let's learn lowercase letters today! Tap Letter Adventure.",
    "I found a dino egg! Finish an adventure to hatch it. 🥚",
    "Ready to explore? Pick any land on the map!",
  ];
  const tip = tips[(state.streak || 0) % tips.length];

  return (
    <div className="app sky-bg">
      <Hud state={state} update={update} title="Map"
        onCollections={onCollections} onParent={onParent} />

      <div className="home">
        <div className="home__hero">
          <div className="mascot">🦖</div>
          <div className="home__hello">
            <h1>Hi {state.name}! 👋</h1>
            <p>Where should we explore today?</p>
          </div>
          <div className="mascot-bubble">
            <strong>Rexy says:</strong><br />{tip}
          </div>
        </div>

        <div className="home__section-title">🗺️ Your Expedition Map</div>
        <div className="lands" style={{ marginTop: 12 }}>
          {playable.map(s => (
            <Land key={s.id} s={s} progress={state.progress[s.id]} onOpen={onOpen} />
          ))}
        </div>

        <div className="home__section-title">🧭 More lands to unlock <span style={{ fontSize: 14, fontWeight: 700, color: 'var(--ink-soft)' }}>— keep earning eggs!</span></div>
        <div className="lands" style={{ marginTop: 12 }}>
          {soon.map(s => (
            <Land key={s.id} s={s} onOpen={onOpen} />
          ))}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { Home });
