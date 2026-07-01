/* ============================================================
   LETTER ADVENTURE — 4 sections
   This file: menu + (1) Big Letters + (2) Build a Small Letters
   letter2.jsx: (3) Match Big & Small + (4) Trace Letters
   ============================================================ */

const shuffle = (a) => { const x = [...a]; for (let i = x.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [x[i], x[j]] = [x[j], x[i]]; } return x; };

/* ============================================================
   (1) BIG LETTERS — trace uppercase, then phonics word callout
   ============================================================ */
function BigLetters({ deck, onComplete, onExit }) {
  const list = deck || ALPHABET;
  const [idx, setIdx] = React.useState(0);
  const [ready, setReady] = React.useState(false);   // traced enough
  const [celebrate, setCelebrate] = React.useState(false);
  const [resetN, setResetN] = React.useState(0);
  const [stars, setStars] = React.useState(0);
  const item = list[idx];

  React.useEffect(() => {
    setReady(false); setCelebrate(false);
    const t = setTimeout(() => speak(`Trace the big letter ${item.u}`, { rate: .9 }), 350);
    return () => clearTimeout(t);
  }, [idx]);

  const sayWord = () => speak(`${item.u}. ${item.ph}, ${item.ph}, ${item.word}!`, { rate: .8 });

  const celebrateLetter = () => {
    if (celebrate) return;
    setCelebrate(true);
    sayWord();
    const ns = stars + 1; setStars(ns);
    setTimeout(() => {
      if (idx + 1 >= list.length) finish(ns);
      else setIdx(idx + 1);
    }, 1900);
  };

  const finish = (s = stars) => onComplete({
    stars: Math.max(1, Math.round(s / 3)), xp: Math.max(5, s * 4), egg: s >= list.length,
    message: `You traced ${s} big letters and learned their sounds!`,
    progressKey: 'letter', progressTo: 55,
  });

  const restart = () => setResetN(n => n + 1);

  return (
    <div className="act">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div>
          <div className="act__title">Big Letters 🔠</div>
          <div className="act__sub">Trace the letter, then hear its sound</div>
        </div>
        <div className="hud__spacer" />
        <div className="act__sub" style={{ marginRight: 8 }}>Letter {idx + 1} of {list.length}</div>
      </div>

      <div className="act__body" style={{ gap: 14 }}>
        <div className={'bl-label' + (celebrate ? ' bl-pop' : '')}>
          <span style={{ color: 'var(--orange)' }}>{item.u}</span> is for
          <span className="e">{item.emoji}</span> {item.word}
          <SayBtn onClick={sayWord} />
        </div>

        <div className={'trace-wrap' + (celebrate ? ' celebrate' : '')} style={{ width: 320, height: 320, position: 'relative' }}>
          <Sparkle show={celebrate} />
          <TraceCanvas width={320} height={320} resetKey={idx + '-' + resetN} threshold={14} onCovered={() => setReady(true)}>
            <div className="trace-letter" style={{ fontSize: 270, color: '#F4ECDC' }}>{item.u}</div>
            <div className="trace-letter" style={{ fontSize: 270, color: 'transparent', WebkitTextStroke: '3px #DFD0B8' }}>{item.u}</div>
          </TraceCanvas>
        </div>

        <div style={{ display: 'flex', gap: 12 }}>
          <button className="btn btn--ghost" onClick={restart}>↺ Start over</button>
          <button className={'btn btn--orange'} onClick={celebrateLetter}
            disabled={!ready} style={!ready ? { opacity: .45 } : { animation: 'pop .5s' }}>
            {ready ? `✓ Hear it & next` : 'Trace the whole letter…'}
          </button>
        </div>
      </div>
    </div>
  );
}

/* ============================================================
   (2) BUILD A SMALL LETTERS — meet all 26 a–z, tap to hear
   ============================================================ */
function SmallLetters({ deck, onComplete, onExit }) {
  const board = deck || ALPHABET;
  const [found, setFound] = React.useState([]);     // lowercase letters discovered
  const [cur, setCur] = React.useState(null);       // current ALPHABET item
  const [pulse, setPulse] = React.useState(null);
  const [burst, setBurst] = React.useState(false);

  React.useEffect(() => { const t = setTimeout(() => speak('Tap a letter to meet its little partner!', { rate: .92 }), 350); return () => clearTimeout(t); }, []);

  const tap = (it) => {
    setCur(it);
    setPulse(it.u);
    setTimeout(() => setPulse(null), 460);
    speak(`Big ${it.u}, little ${it.l}. ${it.ph}. ${it.word}.`, { rate: .82 });
    setFound(f => {
      if (f.includes(it.u)) return f;
      const nf = [...f, it.u];
      if (nf.length === board.length) {
        setBurst(true);
        setTimeout(() => onComplete({
          stars: 5, xp: 30, egg: true, sticker: 'abc',
          message: 'You met every little letter in this game!',
          progressKey: 'letter', progressTo: 65,
        }), 1400);
      }
      return nf;
    });
  };

  return (
    <div className="act">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div>
          <div className="act__title">Build a Small Letters abc 🐣</div>
          <div className="act__sub">Meet the little letter that matches each big one</div>
        </div>
        <div className="hud__spacer" />
        <div className="act__sub" style={{ marginRight: 8 }}>{found.length} / {board.length} met</div>
      </div>

      <div className="act__body" style={{ justifyContent: 'flex-start', paddingTop: 8 }}>
        <div className="sl-layout">
          <div className="sl-hero">
            <Sparkle show={burst} />
            {cur ? (
              <>
                <div className="pair">{cur.u} {cur.l}</div>
                <div className="e">{cur.emoji}</div>
                <div className="word">{cur.word}</div>
                <div className="sound">sound: “{cur.ph}”</div>
                <button className="btn btn--orange" style={{ marginTop: 6, padding: '10px 20px', fontSize: 16 }}
                  onClick={() => speak(`Big ${cur.u}, little ${cur.l}. ${cur.ph}. ${cur.word}.`, { rate: .82 })}>🔊 Hear again</button>
              </>
            ) : (
              <>
                <div style={{ fontSize: 80 }}>👆</div>
                <div className="sl-hint">Tap any letter<br />to meet it!</div>
              </>
            )}
          </div>

          <div className="abc-grid" style={{ gridTemplateColumns: 'repeat(5, 1fr)' }}>
            {board.map((it, i) => (
              <button key={i}
                className={'abc-card' + (found.includes(it.u) ? ' done' : '') + (pulse === it.u ? ' pulse' : '')}
                style={{ background: CARD_COLORS[i % CARD_COLORS.length] }}
                onClick={() => tap(it)}>
                <span className="pair">{it.u}{it.l}</span>
                <span className="e">{it.emoji}</span>
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { BigLetters, SmallLetters, shuffle });
