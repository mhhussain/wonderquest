/* ============================================================
   HOOROF — Games A: Learn, Trace, Hear & Match, Match memory
   ============================================================ */

function _hShuffle(a){const x=[...a];for(let i=x.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[x[i],x[j]]=[x[j],x[i]];}return x;}

/* ---------- Cluster picker (used by Learn & Trace) ---------- */
function ClusterPick({ title, emoji, color, onPick, onExit }) {
  React.useEffect(() => { speak(title, { rate: .95 }); }, []);
  return (
    <div className="act hrf-bg" dir="ltr">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Hoorof</button>
        <div><div className="act__title">{emoji} {title}</div>
          <div className="act__sub">Pick a letter group</div></div>
      </div>
      <div className="act__body" style={{ justifyContent: 'center' }}>
        <div className="hrf-clusters">
          {HRF_CLUSTERS.map(c => (
            <button key={c.id} className="hrf-cluster" style={{ background: color }} onClick={() => onPick(c)}>
              <span className="hrf-cluster__g" dir="rtl">{c.letters.join(' ')}</span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

/* ---------- Learn the Letter ---------- */
function HrfLearn({ onComplete, onExit }) {
  const [cluster, setCluster] = React.useState(null);
  const [i, setI] = React.useState(0);
  const [wobble, setWobble] = React.useState(false);
  if (!cluster) return <ClusterPick title="Learn the Letter" emoji="🔤" color="var(--teal)"
    onPick={(c) => { setCluster(c); setI(0); }} onExit={onExit} />;

  const h = HRF_BY_G[cluster.letters[i]];
  const total = cluster.letters.length;

  return (
    <HrfLearnView key={h.g} h={h} i={i} total={total} wobble={wobble}
      onBack={() => setCluster(null)}
      onWobble={() => { setWobble(true); setTimeout(() => setWobble(false), 600); }}
      onNext={() => { if (i + 1 >= total) onComplete({ stars: 3, xp: 20, sticker: '🐪', message: 'You learned new Arabic letters!', progressKey: 'letter', progressTo: 40 }); else setI(i + 1); }} />
  );
}
function HrfLearnView({ h, i, total, wobble, onBack, onWobble, onNext }) {
  React.useEffect(() => { const t = setTimeout(() => sayLetter(h, false), 350); return () => clearTimeout(t); }, [h]);
  return (
    <div className="act hrf-bg" dir="ltr">
      <div className="act__bar">
        <button className="back-btn" onClick={onBack}>⟵ Hoorof</button>
        <div><div className="act__title">🔤 Learn the Letter</div>
          <div className="act__sub">{h.tr} • “{h.snd}”</div></div>
        <div className="hud__spacer" />
        <div className="dots" dir="ltr">{Array.from({ length: total }).map((_, k) => <i key={k} className={k < i ? 'done' : k === i ? 'cur' : ''} />)}</div>
      </div>
      <div className="act__body" style={{ gap: 18 }}>
        <button className={'hrf-giant' + (wobble ? ' wobble' : '')} onClick={() => { onWobble(); sayLetter(h, false); }}>
          {h.g}
        </button>
        <div className="hrf-name">{h.tr} <button className="say" onClick={() => sayLetter(h, false)}>🔊</button></div>
        <button className="hrf-example" onClick={() => sayLetter(h, true)}>
          <span className="hrf-example__e">{h.e}</span>
          <span className="hrf-example__w" dir="rtl">{h.w}</span>
          <span className="hrf-example__tr" dir="ltr">{h.wtr}</span>
        </button>
        <button className="btn btn--teal btn--lg" onClick={onNext}><span>{i + 1 >= total ? '✓ Done' : 'Next →'}</span></button>
      </div>
    </div>
  );
}

/* ---------- Trace the Letter ---------- */
function HrfTrace({ onComplete, onExit }) {
  const [cluster, setCluster] = React.useState(null);
  const [i, setI] = React.useState(0);
  const [ready, setReady] = React.useState(false);
  const [celebrate, setCelebrate] = React.useState(false);
  const [resetN, setResetN] = React.useState(0);

  if (!cluster) return <ClusterPick title="Trace the Letter" emoji="✏️" color="var(--green)"
    onPick={(c) => { setCluster(c); setI(0); setReady(false); }} onExit={onExit} />;

  const h = HRF_BY_G[cluster.letters[i]];
  const total = cluster.letters.length;

  return (
    <HrfTraceView key={h.g + resetN} h={h} i={i} total={total} ready={ready} celebrate={celebrate}
      resetKey={h.g + '-' + resetN}
      onReady={() => setReady(true)} onRestart={() => { setReady(false); setResetN(n => n + 1); }}
      onBack={() => setCluster(null)}
      onNext={() => {
        setCelebrate(true); sayLetter(h, false);
        setTimeout(() => {
          setCelebrate(false); setReady(false);
          if (i + 1 >= total) onComplete({ stars: 3, xp: 22, sticker: '✏️', message: 'Beautiful Arabic tracing!', progressKey: 'letter', progressTo: 45 });
          else setI(i + 1);
        }, 1400);
      }} />
  );
}
function HrfTraceView({ h, i, total, ready, celebrate, resetKey, onReady, onRestart, onBack, onNext }) {
  React.useEffect(() => { const t = setTimeout(() => speakArabic(`اِرْسُم ${h.nm}`, `Trace ${h.tr}`), 350); return () => clearTimeout(t); }, [resetKey]);
  return (
    <div className="act hrf-bg" dir="ltr">
      <div className="act__bar">
        <button className="back-btn" onClick={onBack}>⟵ Hoorof</button>
        <div><div className="act__title">✏️ Trace the Letter</div>
          <div className="act__sub">{h.tr}</div></div>
        <div className="hud__spacer" />
        <div className="dots" dir="ltr">{Array.from({ length: total }).map((_, k) => <i key={k} className={k < i ? 'done' : k === i ? 'cur' : ''} />)}</div>
      </div>
      <div className="act__body" style={{ gap: 14 }}>
        <div className="hrf-name">{h.tr} <button className="say" onClick={() => sayLetter(h, false)}>🔊</button></div>
        <div className={'trace-wrap' + (celebrate ? ' celebrate' : '')} style={{ width: 340, height: 340, position: 'relative' }}>
          <Sparkle show={celebrate} />
          <TraceCanvas width={340} height={340} resetKey={resetKey} threshold={16} onCovered={onReady} color="rgba(43,179,198,0.9)">
            <div className="trace-letter hrf-trace-guide" style={{ fontSize: 250, color: '#EAF0E2' }}>{h.g}</div>
            <div className="trace-letter hrf-trace-guide" style={{ fontSize: 250, color: 'transparent', WebkitTextStroke: '3px #C9D7BC' }}>{h.g}</div>
          </TraceCanvas>
        </div>
        <div style={{ display: 'flex', gap: 12 }} dir="ltr">
          <button className="btn btn--ghost" onClick={onRestart}>↺ Try again</button>
          <button className="btn btn--green" onClick={onNext} disabled={!ready} style={!ready ? { opacity: .45 } : { animation: 'pop .5s' }}>
            {ready ? '✓ Great!' : '… Trace the letter'}
          </button>
        </div>
      </div>
    </div>
  );
}

/* ---------- Hear & Match ---------- */
function HrfHearMatch({ onComplete, onExit }) {
  const N = 8;
  const rounds = React.useMemo(() => _hShuffle(HRF).slice(0, N), []);
  const [i, setI] = React.useState(0);
  const [picked, setPicked] = React.useState(null);
  const h = rounds[i];
  const options = React.useMemo(() => {
    const sibs = _hShuffle(hrfFamily(h.g));
    const picks = sibs.slice(0, 2);
    if (picks.length < 2) {
      const extra = _hShuffle(HRF.map(x => x.g).filter(g => g !== h.g && !picks.includes(g)));
      while (picks.length < 2) picks.push(extra.shift());
    }
    return _hShuffle([h.g, ...picks]);
  }, [i]);

  React.useEffect(() => { setPicked(null); const t = setTimeout(() => sayLetter(h, false), 450); return () => clearTimeout(t); }, [i]);

  const choose = (g) => {
    if (picked && picked.ok) return;
    const ok = g === h.g;
    setPicked({ g, ok });
    if (ok) {
      speakArabic(`أَحْسَنْت! ${h.nm}`, `Yes! ${h.tr}`);
      setTimeout(() => { if (i + 1 >= N) onComplete({ stars: 4, xp: 28, egg: true, sticker: '🎧', message: 'Great Arabic listening!', progressKey: 'letter', progressTo: 50 }); else setI(i + 1); }, 1100);
    } else { setTimeout(() => setPicked(null), 500); }
  };

  return (
    <div className="act hrf-bg" dir="ltr">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Hoorof</button>
        <div><div className="act__title">🎧 Hear & Match</div>
          <div className="act__sub">Tap the letter you hear</div></div>
        <div className="hud__spacer" />
        <div className="dots" dir="ltr">{rounds.map((_, k) => <i key={k} className={k < i ? 'done' : k === i ? 'cur' : ''} />)}</div>
      </div>
      <div className="act__body" style={{ gap: 22 }}>
        <button className="hrf-listen" onClick={() => sayLetter(h, false)}>🔊<span>Listen</span></button>
        <div className="hrf-choices">
          {options.map((g, k) => {
            const isPick = picked && picked.g === g;
            const cls = isPick ? (picked.ok ? ' ok' : ' no') : '';
            return <button key={k} className={'hrf-choice' + cls} onClick={() => choose(g)}>{g}</button>;
          })}
        </div>
      </div>
    </div>
  );
}

/* ---------- Match the Letters (memory) ---------- */
function HrfMemory({ onComplete, onExit }) {
  const PAIRS = 6;
  const deck = React.useMemo(() => {
    const ls = _hShuffle(HRF).slice(0, PAIRS).map(h => h.g);
    return _hShuffle([...ls, ...ls].map((g, idx) => ({ id: idx, g })));
  }, []);
  const [flipped, setFlipped] = React.useState([]);   // ids currently face-up (unmatched)
  const [matched, setMatched] = React.useState([]);   // ids matched
  const [busy, setBusy] = React.useState(false);
  const wonRef = React.useRef(false);

  React.useEffect(() => { const t = setTimeout(() => speakArabic('جِد الحَرْفَيْنِ المُتَشابِهَيْن!', 'Find the matching letters!'), 400); return () => clearTimeout(t); }, []);

  const tap = (card) => {
    if (busy || flipped.includes(card.id) || matched.includes(card.id)) return;
    const nf = [...flipped, card.id];
    setFlipped(nf);
    speakArabic(HRF_BY_G[card.g].nm, HRF_BY_G[card.g].tr);
    if (nf.length === 2) {
      setBusy(true);
      const [a, b] = nf.map(id => deck.find(c => c.id === id));
      if (a.g === b.g) {
        setTimeout(() => {
          const nm = [...matched, a.id, b.id]; setMatched(nm); setFlipped([]); setBusy(false);
          speakArabic('مُطابَقَة!', 'Match!');
          if (nm.length >= PAIRS * 2 && !wonRef.current) { wonRef.current = true; setTimeout(() => onComplete({ stars: 4, xp: 30, egg: true, sticker: '🧩', message: 'You matched all the letters!', progressKey: 'letter', progressTo: 55 }), 700); }
        }, 650);
      } else {
        setTimeout(() => { setFlipped([]); setBusy(false); }, 900);
      }
    }
  };

  return (
    <div className="act hrf-bg" dir="ltr">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Hoorof</button>
        <div><div className="act__title">🧩 Match the Letters</div>
          <div className="act__sub">Find the matching pairs</div></div>
        <div className="hud__spacer" />
        <div className="spot-counter" style={{ background: 'var(--grape)' }} dir="ltr">🧩 {matched.length / 2}/{PAIRS}</div>
      </div>
      <div className="act__body">
        <div className="hrf-memory">
          {deck.map(card => {
            const up = flipped.includes(card.id) || matched.includes(card.id);
            return (
              <button key={card.id} className={'hrf-mcard' + (up ? ' up' : '') + (matched.includes(card.id) ? ' matched' : '')}
                onClick={() => tap(card)}>
                <span className="hrf-mcard__in">
                  <span className="hrf-mcard__back">✦</span>
                  <span className="hrf-mcard__front">{card.g}</span>
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { HrfLearn, HrfTrace, HrfHearMatch, HrfMemory, ClusterPick, _hShuffle });
