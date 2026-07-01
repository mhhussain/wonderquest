/* ============================================================
   LETTER ADVENTURE — (5) READING WORDS (drag-to-build)
   Picture + word family. Easy = drag 1 letter, Hard = drag 2.
   ============================================================ */

function ReadingWords({ deck, onComplete, onExit }) {
  // 15 words from the dealt deck, single-letter (easy) first so it ramps up
  const rounds = React.useMemo(() => {
    const src = deck || [...shuffle(WORDS_EASY).slice(0, 9), ...shuffle(WORDS_HARD).slice(0, 6)];
    return [...src].sort((a, b) => a.miss.length - b.miss.length);
  }, []);
  const N = rounds.length;
  const [i, setI] = React.useState(0);
  const [filled, setFilled] = React.useState([]);        // letters placed, in slot order
  const [drag, setDrag] = React.useState(null);          // {letter, idx, ox,oy,dx,dy}
  const [overFrame, setOverFrame] = React.useState(false);
  const [wrongIdx, setWrongIdx] = React.useState(null);
  const [score, setScore] = React.useState(0);
  const frameRef = React.useRef(null);
  const round = rounds[i];
  const slots = round.miss.length;
  const done = filled.length >= slots;

  const tiles = React.useMemo(() => shuffle([...round.miss, ...round.distract]), [i]);

  React.useEffect(() => {
    setFilled([]);
    const t = setTimeout(() => speak(`What word is this? ${round.word}`, { rate: .82 }), 350);
    return () => clearTimeout(t);
  }, [i]);

  // celebrate when fully built
  React.useEffect(() => {
    if (!done) return;
    const ph = round.miss.map(l => PHONICS[l] || l).join('. ');
    speak(`${ph}. ${round.word}!`, { rate: .8 });
    const ns = score + 1; setScore(ns);
    const t = setTimeout(() => {
      if (i + 1 >= N) onComplete({
        stars: 5, xp: 40, egg: true, sticker: '📖',
        message: `You read ${ns} words — you're really reading now, Hassan!`,
        progressKey: 'letter', progressTo: 90,
      });
      else setI(i + 1);
    }, 1500);
    return () => clearTimeout(t);
  }, [done]);

  React.useEffect(() => {
    if (!drag) return;
    const move = (e) => {
      const p = e.touches ? e.touches[0] : e;
      setDrag(d => d && ({ ...d, dx: p.clientX - d.ox, dy: p.clientY - d.oy }));
      const r = frameRef.current?.getBoundingClientRect();
      if (r) setOverFrame(p.clientX > r.left - 20 && p.clientX < r.right + 20 && p.clientY > r.top - 20 && p.clientY < r.bottom + 40);
    };
    const up = (e) => {
      const p = e.changedTouches ? e.changedTouches[0] : e;
      const r = frameRef.current?.getBoundingClientRect();
      const hit = r && p.clientX > r.left - 20 && p.clientX < r.right + 20 && p.clientY > r.top - 20 && p.clientY < r.bottom + 40;
      if (hit) {
        // which slot does this letter belong to? next unfilled slot that needs it
        const needIdx = filled.length;     // slots fill left-to-right in order
        if (round.miss[needIdx] === drag.letter) {
          setFilled(f => [...f, drag.letter]);
          speak(PHONICS[drag.letter] || drag.letter, { rate: .8 });
        } else {
          setWrongIdx(drag.idx);
          speak('Try another letter!', { rate: .95 });
          setTimeout(() => setWrongIdx(null), 450);
        }
      }
      setDrag(null); setOverFrame(false);
    };
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
    return () => { window.removeEventListener('pointermove', move); window.removeEventListener('pointerup', up); };
  }, [drag, filled, i]);

  const start = (e, letter, idx) => {
    if (done) return;
    const p = e.touches ? e.touches[0] : e;
    setDrag({ letter, idx, ox: p.clientX, oy: p.clientY, dx: 0, dy: 0 });
  };

  // a tile is "used" once its letter has been correctly placed (count duplicates)
  const usedCount = {};
  filled.forEach(l => { usedCount[l] = (usedCount[l] || 0) + 1; });
  const placedSoFar = {};

  const hard = round.miss.length > 1;
  return (
    <div className="act" style={{ position: 'relative' }}>
      {done && <div className="cheer">📖 <span>{round.word}!</span> 🎉</div>}
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div>
          <div className="act__title">Reading Words 📖</div>
          <div className="act__sub">{hard ? 'Two letters now — sound them out!' : 'Drag the first letter to finish the word'}</div>
        </div>
        <div className="hud__spacer" />
        <div className="act__sub" style={{ marginRight: 10 }}>Word {i + 1} / {N}</div>
        <div className="xpbar" style={{ maxWidth: 160 }}>
          <div className="xpbar__fill" style={{ width: (i / N * 100) + '%', background: 'linear-gradient(90deg,var(--coral),var(--orange))' }} />
        </div>
      </div>

      <div className="act__body">
        <div className="prompt">
          Finish the word!
          <SayBtn onClick={() => speak(round.word, { rate: .8 })} />
        </div>

        <div className="scene-card" style={{ flexDirection: 'row', gap: 30, alignItems: 'center', padding: '24px 36px' }}>
          <Sparkle show={done} />
          <div className="big-emoji" style={{ fontSize: 110 }}>{round.emoji}</div>
          <div className="wordframe" ref={frameRef} style={{ fontSize: 72 }}>
            {round.miss.map((need, si) => {
              const isFilled = si < filled.length;
              return (
                <div key={si}
                  className={'slot' + (overFrame && si === filled.length ? ' over' : '') + (isFilled ? ' filled' : '')}
                  style={{ width: 80, height: 100 }}>
                  {isFilled ? filled[si] : '?'}
                </div>
              );
            })}
            <span>{round.end}</span>
          </div>
        </div>

        <div className="tiletray">
          {tiles.map((letter, idx) => {
            const isDragging = drag && drag.idx === idx;
            // mark as used: if this letter is in miss and already placed enough times
            placedSoFar[letter] = placedSoFar[letter] || 0;
            const totalNeeded = round.miss.filter(m => m === letter).length;
            const alreadyPlaced = filled.filter(m => m === letter).length;
            // count how many earlier identical tiles exist to decide which to grey
            const earlierSame = tiles.slice(0, idx).filter(t => t === letter).length;
            const isUsed = round.miss.includes(letter) && earlierSame < alreadyPlaced;
            return (
              <div key={idx}
                className={'tile' + (isDragging ? ' lift' : '') + (wrongIdx === idx ? ' wrong' : '') + (isUsed ? ' used' : '')}
                style={isDragging ? { transform: `translate(${drag.dx}px, ${drag.dy}px) scale(1.12) rotate(-3deg)` } : undefined}
                onPointerDown={(e) => !isUsed && start(e, letter, idx)}>
                {letter}
              </div>
            );
          })}
        </div>
        <div className="act__sub" style={{ opacity: .8 }}>Tap 🔊 to hear the word, then drag the letter{slots > 1 ? 's' : ''} up.</div>
      </div>
    </div>
  );
}

Object.assign(window, { ReadingWords });
