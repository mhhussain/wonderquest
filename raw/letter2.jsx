/* ============================================================
   LETTER ADVENTURE — (3) Match Big & Small + (4) Trace Letters
   plus the 4-section menu
   ============================================================ */

/* ============================================================
   (3) MATCH BIG & SMALL — 20 rounds, easy → tricky
   ============================================================ */
function MatchLetters({ deck, onComplete, onExit }) {
  const rounds = React.useMemo(() =>
  (deck || MATCH_ORDER.map((U) => ALPHABET.find((a) => a.u === U))).map((item) => {
    const answer = item.l;
    const wrong = new Set();
    if (CONFUSE[answer]) wrong.add(CONFUSE[answer]); // force confusable when one exists
    const pool = shuffle(ALPHABET.map((a) => a.l).filter((l) => l !== answer));
    for (const l of pool) {if (wrong.size >= 2) break;wrong.add(l);}
    return { U: item.u, answer, emoji: item.emoji, word: item.word, choices: shuffle([answer, ...[...wrong].slice(0, 2)]) };
  }), []);
  const N = rounds.length;
  const [i, setI] = React.useState(0);
  const [picked, setPicked] = React.useState(null);
  const [cheer, setCheer] = React.useState(false);
  const [score, setScore] = React.useState(0);
  const round = rounds[i];

  React.useEffect(() => {setPicked(null);setCheer(false);const t = setTimeout(() => speak(`Find the little ${round.U}`, { rate: .9 }), 300);return () => clearTimeout(t);}, [i]);

  const choose = (l) => {
    if (picked && picked.ok) return;
    const ok = l === round.answer;
    setPicked({ l, ok });
    if (ok) {
      setCheer(true);
      setScore((s) => s + 1);
      speak(`Yes! Big ${round.U}, little ${round.answer}.`, { rate: .9 });
      setTimeout(() => {
        if (i + 1 >= N) onComplete({
          stars: 5, xp: 36, egg: true, sticker: '🏅',
          message: `You matched ${score + 1} of ${N} letters — even the tricky ones!`,
          progressKey: 'letter', progressTo: 80
        });else
        setI(i + 1);
      }, 1100);
    } else {
      speak('Try again!', { rate: .95 });
      setTimeout(() => setPicked(null), 520);
    }
  };

  const tricky = i >= 15;
  return (
    <div className="act" style={{ position: 'relative' }}>
      {cheer && <div className="cheer">🦖 <span>{['Yay!', 'Great!', 'Wow!', 'Nice!', 'Super!'][i % 5]}</span> 🎉</div>}
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div>
          <div className="act__title">Match Big &amp; Small 🧲</div>
          <div className="act__sub">{tricky ? 'Tricky ones now — look closely!' : 'Tap the little letter that matches'}</div>
        </div>
        <div className="hud__spacer" />
        <div className="act__sub" style={{ marginRight: 10 }}>Round {i + 1} / {N}</div>
        <div className="xpbar" style={{ maxWidth: 160 }}>
          <div className="xpbar__fill" style={{ width: i / N * 100 + '%', background: 'linear-gradient(90deg,var(--orange),var(--coral))' }} />
        </div>
      </div>

      <div className="act__body">
        <div className="prompt">Which little letter is this?
          <SayBtn onClick={() => speak(`Big ${round.U}`, { rate: .9 })} /></div>

        <div className="scene-card" style={{ width: 220, height: 200, justifyContent: 'center', gap: 4 }}>
          <div style={{ fontFamily: 'var(--font-head)', fontWeight: 800, fontSize: 130, color: 'var(--orange)', lineHeight: 1 }}>{round.U}</div>
          <div style={{ fontWeight: 800, color: 'var(--ink-soft)' }}><span className="match-illus">{round.emoji}</span> {round.word}</div>
        </div>

        <div className="match-grid" style={{ gridTemplateColumns: 'repeat(3, 120px)' }}>
          {round.choices.map((l, k) => {
            const isPick = picked && picked.l === l;
            const cls = isPick ? picked.ok ? ' match-ok' : ' match-no' : '';
            return <button key={k} className={'card-btn' + cls} style={{ height: 120, fontSize: 64, color: 'var(--teal-d)', fontFamily: "Nunito" }}
            onClick={() => choose(l)}>{l}</button>;
          })}
        </div>
      </div>
    </div>);

}

/* ============================================================
   (4) TRACE LETTERS — uppercase + lowercase side by side
   ============================================================ */
function TraceLetters({ deck, onComplete, onExit }) {
  const letters = React.useMemo(() => deck || shuffle(ALPHABET).slice(0, 20), []);
  const N = letters.length;
  const [i, setI] = React.useState(0);
  const [ready, setReady] = React.useState(false);
  const [celebrate, setCelebrate] = React.useState(false);
  const [resetN, setResetN] = React.useState(0);
  const item = letters[i];

  React.useEffect(() => {
    setReady(false);setCelebrate(false);
    const t = setTimeout(() => speak(`Trace big ${item.u} and little ${item.l}`, { rate: .88 }), 350);
    return () => clearTimeout(t);
  }, [i]);

  const next = () => {
    if (celebrate) return;
    setCelebrate(true);
    speak(`${item.u} and ${item.l}. ${item.ph}. ${item.word}!`, { rate: .82 });
    setTimeout(() => {
      if (i + 1 >= N) onComplete({
        stars: 4, xp: 30, sticker: '✏️',
        message: 'Beautiful tracing — big AND little letters!',
        progressKey: 'letter', progressTo: 70
      });else
      setI(i + 1);
    }, 1500);
  };

  return (
    <div className="act">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div>
          <div className="act__title">Trace Big &amp; Little ✏️</div>
          <div className="act__sub">Trace both letters with your finger or Apple Pencil</div>
        </div>
        <div className="hud__spacer" />
        <div className="act__sub" style={{ marginRight: 8 }}>Letter {i + 1} / {N}</div>
      </div>

      <div className="act__body" style={{ gap: 14 }}>
        <div className="bl-label">
          <span className="e">{item.emoji}</span> {item.word}
          <SayBtn onClick={() => speak(`${item.u} and ${item.l}. ${item.ph}. ${item.word}!`, { rate: .82 })} />
        </div>

        <div className={'trace-wrap' + (celebrate ? ' celebrate' : '')} style={{ width: 620, height: 300, position: 'relative' }}>
          <Sparkle show={celebrate} />
          <TraceCanvas width={620} height={300} resetKey={i + '-' + resetN} threshold={20} onCovered={() => setReady(true)} color="rgba(123,192,67,0.9)">
            {/* divider */}
            <div style={{ position: 'absolute', left: '50%', top: 28, bottom: 28, width: 3, background: '#F0E5D2', borderRadius: 4 }} />
            {/* uppercase guide (left) */}
            <div className="trace-letter" style={{ left: 0, right: '50%', fontSize: 220, color: '#F4ECDC' }}>{item.u}</div>
            <div className="trace-letter" style={{ left: 0, right: '50%', fontSize: 220, color: 'transparent', WebkitTextStroke: '3px #DFD0B8' }}>{item.u}</div>
            {/* lowercase guide (right) */}
            <div className="trace-letter" style={{ left: '50%', right: 0, fontSize: 220, color: '#F4ECDC' }}>{item.l}</div>
            <div className="trace-letter" style={{ left: '50%', right: 0, fontSize: 220, color: 'transparent', WebkitTextStroke: '3px #DFD0B8' }}>{item.l}</div>
          </TraceCanvas>
        </div>

        <div style={{ display: 'flex', gap: 12 }}>
          <button className="btn btn--ghost" onClick={() => setResetN((n) => n + 1)}>↺ Start over</button>
          <button className="btn btn--green" onClick={next} disabled={!ready}
          style={!ready ? { opacity: .45 } : { animation: 'pop .5s' }}>
            {ready ? '✓ Hear it & next' : 'Trace both letters…'}
          </button>
        </div>
      </div>
    </div>);

}

/* ============================================================
   LETTER ADVENTURE menu — 4 sections
   ============================================================ */
function LetterAdventure({ onComplete, onExit }) {
  const [game, setGame] = React.useState(null);
  const games = [
  { id: 'big', title: 'Big Letters', sub: '10 games', emoji: '🔠', color: 'var(--orange)' },
  { id: 'small', title: 'Build Small abc', sub: '10 games', emoji: '🐣', color: 'var(--teal)' },
  { id: 'word', title: 'Reading Words', sub: '10 games', emoji: '📖', color: 'var(--coral)' },
  { id: 'match', title: 'Match Letters', sub: '10 games', emoji: '🧲', color: 'var(--grape)' },
  { id: 'trace', title: 'Trace Letters', sub: '10 games', emoji: '✏️', color: 'var(--green)' }];

  const back = () => setGame(null);
  const wordPool = [...WORDS_EASY, ...WORDS_HARD];

  if (game === 'big') return <GameLevels typeId="big" title="Big Letters" emoji="🔠" color="var(--orange)"
    pool={ALPHABET} keyOf={x => x.u} onComplete={onComplete} onExit={back}
    render={(deck, g, done, exit) => <BigLetters deck={deck} onComplete={done} onExit={exit} />} />;
  if (game === 'small') return <GameLevels typeId="small" title="Build Small abc" emoji="🐣" color="var(--teal)"
    pool={ALPHABET} keyOf={x => x.u} onComplete={onComplete} onExit={back}
    render={(deck, g, done, exit) => <SmallLetters deck={deck} onComplete={done} onExit={exit} />} />;
  if (game === 'word') return <GameLevels typeId="word" title="Reading Words" emoji="📖" color="var(--coral)"
    pool={wordPool} keyOf={x => x.word} onComplete={onComplete} onExit={back}
    render={(deck, g, done, exit) => <ReadingWords deck={deck} onComplete={done} onExit={exit} />} />;
  if (game === 'match') return <GameLevels typeId="match" title="Match Letters" emoji="🧲" color="var(--grape)"
    pool={ALPHABET} keyOf={x => x.u} onComplete={onComplete} onExit={back}
    render={(deck, g, done, exit) => <MatchLetters deck={deck} onComplete={done} onExit={exit} />} />;
  if (game === 'trace') return <GameLevels typeId="trace" title="Trace Letters" emoji="✏️" color="var(--green)"
    pool={ALPHABET} keyOf={x => x.u} onComplete={onComplete} onExit={back}
    render={(deck, g, done, exit) => <TraceLetters deck={deck} onComplete={done} onExit={exit} />} />;
  return <ActivityMenu title="Letter Adventure" emoji="🔤" tagline="Letters, sounds, reading words and tracing!" games={games} onPick={setGame} onExit={onExit} />;
}

Object.assign(window, { MatchLetters, TraceLetters, LetterAdventure });