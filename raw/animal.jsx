/* ============================================================
   AMAZING ANIMAL PLANET — Habitat sorting + Fun Facts
   ============================================================ */

/* ---------------- Habitat sorting ---------------- */
function HabitatGame({ onComplete, onExit }) {
  const animals = React.useMemo(() => {
    // 1-2 from each habitat, total 6
    const byHab = HABITATS.map(h => shuffle(ANIMALS.filter(a => a.habitat === h.id)));
    const pick = [];
    byHab.forEach(list => { pick.push(list[0]); });
    byHab.forEach(list => { if (pick.length < 6 && list[1]) pick.push(list[1]); });
    return shuffle(pick.slice(0, 6));
  }, []);
  const [placed, setPlaced] = React.useState({});   // animalName -> habitatId
  const [drag, setDrag] = React.useState(null);      // {idx, ox,oy,dx,dy}
  const [overHab, setOverHab] = React.useState(null);
  const [wrong, setWrong] = React.useState(null);
  const habRefs = React.useRef({});
  const placedCount = Object.keys(placed).length;

  React.useEffect(() => { const t = setTimeout(() => speak('Drag each animal to its home!', { rate: .92 }), 350); return () => clearTimeout(t); }, []);

  React.useEffect(() => {
    if (placedCount === animals.length) {
      const t = setTimeout(() => onComplete({
        stars: 3, xp: 30, sticker: '🌍', message: 'Every animal is home! You learned new facts too.',
        progressKey: 'animal', progressTo: 70,
      }), 900);
      return () => clearTimeout(t);
    }
  }, [placedCount]);

  React.useEffect(() => {
    if (!drag) return;
    const move = (e) => {
      const p = e.touches ? e.touches[0] : e;
      setDrag(d => d && ({ ...d, dx: p.clientX - d.ox, dy: p.clientY - d.oy }));
      let found = null;
      for (const h of HABITATS) {
        const r = habRefs.current[h.id]?.getBoundingClientRect();
        if (r && p.clientX > r.left && p.clientX < r.right && p.clientY > r.top && p.clientY < r.bottom) found = h.id;
      }
      setOverHab(found);
    };
    const up = (e) => {
      const a = animals[drag.idx];
      if (overHab) {
        if (overHab === a.habitat) {
          setPlaced(pl => ({ ...pl, [a.name]: a.habitat }));
          speak(a.fact, { rate: .92 });
        } else {
          setWrong(drag.idx); speak('Try another home!', { rate: .95 });
          setTimeout(() => setWrong(null), 450);
        }
      }
      setDrag(null); setOverHab(null);
    };
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
    return () => { window.removeEventListener('pointermove', move); window.removeEventListener('pointerup', up); };
  }, [drag, overHab]);

  const start = (e, idx) => {
    const p = e.touches ? e.touches[0] : e;
    setDrag({ idx, ox: p.clientX, oy: p.clientY, dx: 0, dy: 0 });
  };

  return (
    <div className="act">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div><div className="act__title">Animal Homes 🏡</div>
          <div className="act__sub">Drag each animal to where it lives</div></div>
        <div className="hud__spacer" />
        <div className="act__sub">{placedCount}/{animals.length} home</div>
      </div>

      <div className="act__body" style={{ justifyContent: 'flex-start', paddingTop: 10 }}>
        <div className="habitats">
          {HABITATS.map(h => {
            const here = animals.filter(a => placed[a.name] === h.id);
            return (
              <div key={h.id} ref={el => habRefs.current[h.id] = el}
                className={'habitat' + (overHab === h.id ? ' over' : '')}
                style={{ background: h.color }}>
                <div className="habitat__drop">{here.map(a => <span key={a.name} title={a.name}>{a.emoji}</span>)}</div>
                <div className="hud__spacer" />
                <div className="habitat__emoji">{h.emoji}</div>
                <div className="habitat__name">{h.name}</div>
              </div>
            );
          })}
        </div>

        <div className="prompt" style={{ fontSize: 20, marginTop: 8 }}>
          Pick up an animal <SayBtn onClick={() => speak('Drag each animal to its home', { rate: .92 })} />
        </div>
        <div className="animal-tray">
          {animals.map((a, idx) => {
            if (placed[a.name]) return <div key={idx} className="animal-chip used" />;
            const isDrag = drag && drag.idx === idx;
            return (
              <div key={idx}
                className={'animal-chip' + (isDrag ? ' lift' : '') + (wrong === idx ? ' wrong' : '')}
                style={isDrag ? { transform: `translate(${drag.dx}px, ${drag.dy}px) scale(1.12) rotate(-4deg)` } : undefined}
                onPointerDown={(e) => start(e, idx)}>
                {a.emoji}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

/* ---------------- Fun Fact cards ---------------- */
function FactGame({ onComplete, onExit, onAnimal }) {
  const cards = React.useMemo(() => shuffle(ANIMALS).slice(0, 6), []);
  const [flipped, setFlipped] = React.useState([]);
  const allDone = flipped.length === cards.length;

  const flip = (idx) => {
    if (flipped.includes(idx)) { speak(cards[idx].fact, { rate: .92 }); return; }
    const a = cards[idx];
    setFlipped(f => [...f, idx]);
    speak(`${a.name}. ${a.fact}`, { rate: .92 });
    onAnimal && onAnimal(a.name);
  };

  return (
    <div className="act">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div><div className="act__title">Fun Animal Facts 💡</div>
          <div className="act__sub">Tap a card to discover an amazing fact</div></div>
        <div className="hud__spacer" />
        <div className="act__sub">{flipped.length}/{cards.length} found</div>
      </div>

      <div className="act__body" style={{ justifyContent: 'center' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16, width: '100%', maxWidth: 820 }}>
          {cards.map((a, idx) => {
            const open = flipped.includes(idx);
            return (
              <button key={idx} className={'flip-card' + (open ? ' open' : '')} onClick={() => flip(idx)}>
                <span className="flip-inner">
                  <span className="flip-face flip-front">
                    <span className="fe">{a.emoji}</span>
                    <b className="fn">{a.name}</b>
                    <span className="ft">👆 Tap for a fun fact</span>
                  </span>
                  <span className="flip-face flip-back">
                    <span className="fe">{a.emoji}</span>
                    <b className="fn">{a.name}</b>
                    <span className="ft">{a.fact}</span>
                  </span>
                </span>
              </button>
            );
          })}
        </div>
        {allDone && (
          <button className="btn btn--grape btn--lg" onClick={() => onComplete({
            stars: 3, xp: 24, egg: true, message: 'You discovered 6 animal facts!', progressKey: 'animal', progressTo: 60,
          })}>I learned them all! ⭐</button>
        )}
      </div>
    </div>
  );
}

function AnimalPlanet({ onComplete, onExit, onAnimal }) {
  const [game, setGame] = React.useState(null);
  const games = [
    { id: 'habitat', title: 'Animal Homes', sub: 'Sort by habitat', emoji: '🏡', color: 'var(--grape)' },
    { id: 'facts', title: 'Fun Facts', sub: 'Discover & collect', emoji: '💡', color: 'var(--pink)' },
    { id: 'sea', title: 'Under the Sea', sub: 'Ocean animals & whales', emoji: '🌊', color: 'var(--sky)' },
  ];
  if (game === 'habitat') return <HabitatGame onComplete={onComplete} onExit={() => setGame(null)} />;
  if (game === 'facts') return <FactGame onComplete={onComplete} onExit={() => setGame(null)} onAnimal={onAnimal} />;
  if (game === 'sea') return <UnderTheSea onComplete={onComplete} onExit={() => setGame(null)} />;
  return <ActivityMenu title="Amazing Animal Planet" emoji="🦁" tagline="Meet animals and learn where they live!" games={games} onPick={setGame} onExit={onExit} />;
}

Object.assign(window, { AnimalPlanet });
