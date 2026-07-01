/* ============================================================
   NUMBER KINGDOM — Count & Match, Missing Number
   ============================================================ */

/* ---------------- Count & Match ---------------- */
function CountGame({ deck, onComplete, onExit }) {
  const rounds = React.useMemo(() => deck ||
    Array.from({ length: 15 }, (_, k) => ({
      emoji: COUNT_EMOJIS[Math.floor(Math.random() * COUNT_EMOJIS.length)],
      count: 1 + Math.floor(Math.random() * Math.min(12, 4 + Math.floor(k / 2))),
    })), []);
  const N = rounds.length;
  const [i, setI] = React.useState(0);
  const [counted, setCounted] = React.useState([]);   // indices tapped
  const [picked, setPicked] = React.useState(null);
  const round = rounds[i];

  const options = React.useMemo(() => {
    const set = new Set([round.count]);
    while (set.size < 4) { const d = round.count + (Math.floor(Math.random() * 5) - 2); if (d >= 1 && d <= 12) set.add(d); }
    return shuffle([...set]);
  }, [i]);

  React.useEffect(() => { setCounted([]); setPicked(null); const t = setTimeout(() => speak('Count them, then tap the number!', { rate: .92 }), 300); return () => clearTimeout(t); }, [i]);

  const tapObj = (k) => {
    if (counted.includes(k)) return;
    const next = [...counted, k];
    setCounted(next);
    speak(String(next.length), { rate: .9, pitch: 1.2 });
  };

  const choose = (n) => {
    if (picked === round.count) return;
    setPicked(n);
    if (n === round.count) {
      speak(`${round.count}! That's right!`, { rate: .92 });
      setTimeout(() => {
        if (i + 1 >= N) onComplete({ stars: 3, xp: 28, egg: true, message: 'You counted like a champion!', progressKey: 'number', progressTo: 55 });
        else setI(i + 1);
      }, 1100);
    } else {
      setTimeout(() => setPicked(null), 500);
    }
  };

  return (
    <div className="act">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div><div className="act__title">Count & Match 🔢</div>
          <div className="act__sub">Tap each one to count, then pick the number</div></div>
        <div className="hud__spacer" />
        <div className="act__sub" style={{ marginRight: 10 }}>Round {i + 1} / {N}</div>
        <div className="xpbar" style={{ maxWidth: 150 }}>
          <div className="xpbar__fill" style={{ width: (i / N * 100) + '%', background: 'linear-gradient(90deg,var(--teal),var(--sky))' }} />
        </div>
      </div>

      <div className="act__body">
        <div className="prompt">How many? <SayBtn onClick={() => speak('How many are there?', { rate: .92 })} /></div>
        <div className="scene-card" style={{ minWidth: 480, minHeight: 200, justifyContent: 'center' }}>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 14, justifyContent: 'center', maxWidth: 460 }}>
            {Array.from({ length: round.count }).map((_, k) => (
              <button key={k} onClick={() => tapObj(k)}
                style={{
                  border: 'none', background: 'transparent', cursor: 'pointer', fontSize: 60, lineHeight: 1,
                  transform: counted.includes(k) ? 'scale(1.18)' : 'scale(1)',
                  filter: counted.includes(k) ? 'none' : 'grayscale(.15)',
                  transition: 'transform .18s',
                }}>
                <span style={{ position: 'relative' }}>
                  {round.emoji}
                  {counted.includes(k) && <span style={{
                    position: 'absolute', top: -10, right: -12, fontSize: 20,
                    background: 'var(--green)', color: '#fff', borderRadius: '50%',
                    width: 26, height: 26, display: 'grid', placeItems: 'center', fontFamily: 'var(--font-head)', fontWeight: 800,
                  }}>{counted.indexOf(k) + 1}</span>}
                </span>
              </button>
            ))}
          </div>
        </div>
        <div className="match-grid" style={{ gridTemplateColumns: 'repeat(4, 96px)' }}>
          {options.map((n, k) => {
            const isPick = picked === n;
            const cls = isPick ? (n === round.count ? ' match-ok' : ' match-no') : '';
            return <button key={k} className={'card-btn' + cls} style={{ height: 96, fontSize: 48, color: 'var(--teal-d)' }}
              onClick={() => choose(n)}>{n}</button>;
          })}
        </div>
      </div>
    </div>
  );
}

/* ---------------- Missing Number ---------------- */
function MissingNumber({ deck, onComplete, onExit }) {
  const rounds = React.useMemo(() => deck ||
    Array.from({ length: 15 }, (_, k) => {
      const span = k < 9 ? 5 : 6;
      const start = 1 + Math.floor(Math.random() * (k < 9 ? 6 : 14));
      const seq = Array.from({ length: span }, (_, j) => start + j);
      const missIdx = 1 + Math.floor(Math.random() * (span - 2));
      return { seq, missIdx, answer: seq[missIdx] };
    }), []);
  const N = rounds.length;
  const [i, setI] = React.useState(0);
  const [picked, setPicked] = React.useState(null);
  const round = rounds[i];
  const options = React.useMemo(() => {
    const set = new Set([round.answer]);
    while (set.size < 3) { const d = round.answer + (Math.floor(Math.random() * 5) - 2); if (d >= 1 && d <= 20 && d !== round.answer) set.add(d); }
    return shuffle([...set]);
  }, [i]);

  React.useEffect(() => { setPicked(null); const t = setTimeout(() => speak('Which number is missing?', { rate: .92 }), 300); return () => clearTimeout(t); }, [i]);

  const choose = (n) => {
    if (picked === round.answer) return;
    setPicked(n);
    if (n === round.answer) {
      speak(`${n}! Perfect!`, { rate: .92 });
      setTimeout(() => {
        if (i + 1 >= N) onComplete({ stars: 3, xp: 26, sticker: '🔢', message: 'You know your number order!', progressKey: 'number', progressTo: 50 });
        else setI(i + 1);
      }, 1000);
    } else setTimeout(() => setPicked(null), 500);
  };

  return (
    <div className="act">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div><div className="act__title">Missing Number 🧮</div>
          <div className="act__sub">Which number fills the gap?</div></div>
        <div className="hud__spacer" />
        <div className="act__sub" style={{ marginRight: 10 }}>Round {i + 1} / {N}</div>
        <div className="xpbar" style={{ maxWidth: 150 }}>
          <div className="xpbar__fill" style={{ width: (i / N * 100) + '%', background: 'linear-gradient(90deg,var(--sky),var(--teal))' }} />
        </div>
      </div>

      <div className="act__body">
        <div className="prompt">Find the missing number <SayBtn onClick={() => speak('Which number is missing?', { rate: .92 })} /></div>
        <div className="scene-card" style={{ flexDirection: 'row', gap: 14, padding: '28px 30px' }}>
          {round.seq.map((n, k) => (
            <div key={k} style={{
              width: 76, height: 92, borderRadius: 18, display: 'grid', placeItems: 'center',
              fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 46,
              background: k === round.missIdx ? '#FFF3E6' : 'var(--teal)',
              color: k === round.missIdx ? 'var(--orange)' : '#fff',
              border: k === round.missIdx ? '5px dashed var(--orange)' : 'none',
            }}>{k === round.missIdx ? (picked === round.answer ? round.answer : '?') : n}</div>
          ))}
        </div>
        <div className="match-grid" style={{ gridTemplateColumns: 'repeat(3, 110px)' }}>
          {options.map((n, k) => {
            const isPick = picked === n;
            const cls = isPick ? (n === round.answer ? ' match-ok' : ' match-no') : '';
            return <button key={k} className={'card-btn' + cls} style={{ height: 110, fontSize: 52, color: 'var(--teal-d)' }}
              onClick={() => choose(n)}>{n}</button>;
          })}
        </div>
      </div>
    </div>
  );
}

function NumberKingdom({ onComplete, onExit }) {
  const [game, setGame] = React.useState(null);
  const games = [
    { id: 'count', title: 'Count & Match', sub: '10 games', emoji: '🧮', color: 'var(--teal)' },
    { id: 'missing', title: 'Missing Number', sub: '10 games', emoji: '🔟', color: 'var(--sky)' },
  ];
  const back = () => setGame(null);

  // unique pools (≥75) so each question repeats at most twice across 10 games
  const countPool = React.useMemo(() => {
    const seen = new Set(), pool = [];
    while (pool.length < 90) {
      const emoji = COUNT_EMOJIS[Math.floor(Math.random() * COUNT_EMOJIS.length)];
      const count = 1 + Math.floor(Math.random() * 12);
      const k = emoji + count;
      if (!seen.has(k)) { seen.add(k); pool.push({ emoji, count }); }
    }
    return pool;
  }, []);
  const missingPool = React.useMemo(() => {
    const seen = new Set(), pool = [];
    while (pool.length < 90) {
      const span = 4 + Math.floor(Math.random() * 3);            // 4–6 long
      const start = 1 + Math.floor(Math.random() * 14);
      const seq = Array.from({ length: span }, (_, j) => start + j);
      const missIdx = 1 + Math.floor(Math.random() * (span - 2));
      const k = start + '-' + span + '-' + missIdx;
      if (!seen.has(k)) { seen.add(k); pool.push({ seq, missIdx, answer: seq[missIdx] }); }
    }
    return pool;
  }, []);

  if (game === 'count') return <GameLevels typeId="count" title="Count & Match" emoji="🧮" color="var(--teal)"
    pool={countPool} keyOf={x => x.emoji + x.count} onComplete={onComplete} onExit={back}
    render={(deck, g, done, exit) => <CountGame deck={deck} onComplete={done} onExit={exit} />} />;
  if (game === 'missing') return <GameLevels typeId="missing" title="Missing Number" emoji="🔟" color="var(--sky)"
    pool={missingPool} keyOf={x => x.seq.join('-') + x.missIdx} onComplete={onComplete} onExit={back}
    render={(deck, g, done, exit) => <MissingNumber deck={deck} onComplete={done} onExit={exit} />} />;
  return <ActivityMenu title="Number Kingdom" emoji="🔢" tagline="Count, match and learn your numbers!" games={games} onPick={setGame} onExit={onExit} />;
}

Object.assign(window, { NumberKingdom });
