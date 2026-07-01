/* ============================================================
   ActivityMenu (game picker) + Collections book modal
   ============================================================ */

function ActivityMenu({ title, emoji, tagline, games, onPick, onExit, accent }) {
  React.useEffect(() => { speak(tagline, { rate: .95 }); }, []);
  return (
    <div className="act sky-bg">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Map</button>
        <div>
          <div className="act__title">{emoji} {title}</div>
          <div className="act__sub">{tagline}</div>
        </div>
      </div>
      <div className="act__body" style={{ justifyContent: 'center' }}>
        <div className="lands" style={{ gridTemplateColumns: `repeat(${games.length}, ${games.length >= 5 ? 200 : games.length >= 4 ? 218 : 230}px)`, gap: games.length >= 5 ? 13 : games.length >= 4 ? 16 : 22 }}>
          {games.map(g => (
            <button key={g.id} className="land" style={{ background: g.color, minHeight: 200 }}
              onClick={() => { speak(g.title, { rate: .95 }); onPick(g.id); }}>
              <span className="land__deco" />
              <span className="land__emoji" style={{ fontSize: games.length >= 5 ? 54 : 60 }}>{g.emoji}</span>
              <span className="land__title" style={{ fontSize: games.length >= 5 ? 20 : 22 }}>{g.title}</span>
              <span className="land__sub">{g.sub}</span>
              <span className="land__pill">▶ Play</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

/* ---------------- Collections modal ---------------- */
function Collections({ state, onClose }) {
  const [tab, setTab] = React.useState('eggs');
  const tabs = [
    { id: 'eggs', label: '🥚 Dino Eggs' },
    { id: 'animals', label: '🦁 Animal Book' },
    { id: 'stickers', label: '✨ Stickers' },
    { id: 'badges', label: '🏅 Badges' },
  ];

  return (
    <div className="overlay" onClick={onClose}>
      <div className="modal" style={{ maxWidth: 720, textAlign: 'left' }} onClick={e => e.stopPropagation()}>
        <button className="modal__close" onClick={onClose}>✕</button>
        <h2 style={{ textAlign: 'center' }}>My Treasure Chest 🧰</h2>
        <div className="tabs">
          {tabs.map(t => (
            <button key={t.id} className={'tab' + (tab === t.id ? ' on' : '')} onClick={() => setTab(t.id)}>{t.label}</button>
          ))}
        </div>

        {tab === 'eggs' && (
          <div className="collection">
            {DINO_EGGS.map((d, k) => {
              const hatched = k < state.eggs;
              return (
                <div key={k} className={'coll-item' + (hatched ? '' : ' locked')}>
                  <span className="e">{hatched ? d : '🥚'}</span>
                  <span className="nm">{hatched ? DINO_NAMES[k] : '???'}</span>
                </div>
              );
            })}
          </div>
        )}

        {tab === 'animals' && (
          <div className="collection">
            {ANIMALS.map((a, k) => {
              const found = state.animalsFound.includes(a.name);
              return (
                <div key={k} className={'coll-item' + (found ? '' : ' locked')}
                  onClick={() => found && speak(a.fact, { rate: .92 })} style={found ? { cursor: 'pointer' } : undefined}>
                  <span className="e">{a.emoji}</span>
                  <span className="nm">{found ? a.name : '???'}</span>
                </div>
              );
            })}
          </div>
        )}

        {tab === 'stickers' && (
          <div className="collection">
            {(state.stickers.length ? state.stickers : ['🔠','✏️']).map((s, k) => (
              <div key={k} className="coll-item"><span className="e">{s}</span></div>
            ))}
            {Array.from({ length: Math.max(0, 8 - state.stickers.length) }).map((_, k) => (
              <div key={'x' + k} className="coll-item locked"><span className="e">✨</span></div>
            ))}
          </div>
        )}

        {tab === 'badges' && (
          <div className="collection" style={{ gridTemplateColumns: 'repeat(4,1fr)' }}>
            {[
              { e: '🔥', nm: '3-Day Streak', got: state.streak >= 3 },
              { e: '⭐', nm: 'Star Collector', got: state.stars >= 10 },
              { e: '🔤', nm: 'Letter Hero', got: state.progress.letter >= 40 },
              { e: '🥚', nm: 'Egg Hatcher', got: state.eggs >= 2 },
              { e: '🔢', nm: 'Number Whiz', got: state.progress.number >= 40 },
              { e: '🦁', nm: 'Animal Friend', got: state.animalsFound.length >= 3 },
              { e: '🏆', nm: 'Level 2', got: state.level >= 2 },
              { e: '🎓', nm: 'GSRP Ready', got: false },
            ].map((b, k) => (
              <div key={k} className={'coll-item' + (b.got ? '' : ' locked')}>
                <span className="e">{b.e}</span><span className="nm">{b.nm}</span>
              </div>
            ))}
          </div>
        )}

        <div style={{ textAlign: 'center', marginTop: 18 }}>
          <button className="btn btn--green" onClick={onClose}>Keep exploring →</button>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { ActivityMenu, Collections });
