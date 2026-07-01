/* ============================================================
   SPOT ME — engines
   placeItems: jittered-grid scatter that avoids heavy overlap
   SpotScene: multi-goal "find/count" engine over a scattered field
   ============================================================ */

function _spShuffle(a){const x=[...a];for(let i=x.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[x[i],x[j]]=[x[j],x[i]];}return x;}

// place n items into a W×H field using a jittered grid
function placeItems(n, W, H, opts = {}) {
  const pad = opts.pad ?? 46;
  const cols = Math.ceil(Math.sqrt(n * (W / H)));
  const rows = Math.ceil(n / cols);
  const cells = [];
  for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) cells.push({ r, c });
  const pick = _spShuffle(cells).slice(0, n);
  const cw = (W - pad * 2) / cols, ch = (H - pad * 2) / rows;
  return pick.map(({ r, c }) => ({
    x: pad + c * cw + cw * (0.2 + Math.random() * 0.6),
    y: pad + r * ch + ch * (0.2 + Math.random() * 0.6),
    rot: (Math.random() * 2 - 1) * (opts.rot ?? 18),
    size: (opts.size ?? 40) * (0.82 + Math.random() * 0.4),
    z: Math.floor(Math.random() * 5),
  }));
}

/* ---------- SpotScene: find/count engine ----------
   goals: [{c, n, l, color?}]   — targets to find (n each)
   decoy: [chars]               — scenery distractors
   mode:  'find' | 'count'
*/
function SpotScene({ title, emoji, sceneName, bg, dark, goals, decoy, decoyCount = 26,
                     mode = 'find', onWin, onExit, color = 'var(--yellow)', headerExtra }) {
  const W = 980, H = 520;
  const build = React.useMemo(() => {
    const items = [];
    goals.forEach((g, gi) => { for (let k = 0; k < g.n; k++) items.push({ key: 'g' + gi + '_' + k, char: g.c, gi, target: true }); });
    const pool = decoy && decoy.length ? decoy : ['🌿','🍃','☁️','🪨'];
    for (let k = 0; k < decoyCount; k++) {
      let ch = pool[Math.floor(Math.random() * pool.length)];
      items.push({ key: 'd' + k, char: ch, target: false });
    }
    const shuffled = _spShuffle(items);
    const pos = placeItems(shuffled.length, W, H, { size: mode === 'count' ? 46 : 42 });
    return shuffled.map((it, i) => ({ ...it, ...pos[i] }));
  }, []);

  const totalTargets = goals.reduce((s, g) => s + g.n, 0);
  const [found, setFound] = React.useState({});       // key -> true
  const [miss, setMiss] = React.useState(null);       // {x,y} ripple for wrong tap
  const foundCount = Object.keys(found).length;
  const wonRef = React.useRef(false);

  React.useEffect(() => {
    const say = mode === 'count'
      ? `How many ${goals[0].l}? Tap each one to count!`
      : 'Find them all! ' + goals.map(g => `${g.n} ${g.l}`).join(', ');
    const t = setTimeout(() => speak(say, { rate: .92 }), 400);
    return () => clearTimeout(t);
  }, []);

  const perGoal = (gi) => Object.keys(found).filter(k => k.startsWith('g' + gi + '_')).length;

  const tap = (it, e) => {
    if (it.target) {
      if (found[it.key]) return;
      setFound(prev => {
        const nf = { ...prev, [it.key]: true };
        const c = Object.keys(nf).length;
        speak(String(c), { rate: .95, pitch: 1.2 });
        if (c >= totalTargets && !wonRef.current) {
          wonRef.current = true;
          setTimeout(() => onWin(), 800);
        }
        return nf;
      });
    } else {
      const rect = e.currentTarget.parentElement.getBoundingClientRect();
      setMiss({ x: e.clientX - rect.left, y: e.clientY - rect.top, id: Date.now() });
      setTimeout(() => setMiss(null), 500);
    }
  };

  return (
    <div className="act">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Detective</button>
        <div>
          <div className="act__title">{emoji} {title}</div>
          <div className="act__sub">{sceneName}</div>
        </div>
        <div className="hud__spacer" />
        {mode === 'count'
          ? <div className="spot-counter" style={{ background: color }}>{goals[0].c} {foundCount}</div>
          : <div className="spot-goals">
              {goals.map((g, gi) => (
                <div key={gi} className={'spot-goal' + (perGoal(gi) >= g.n ? ' done' : '')}>
                  <span className="spot-goal__c">{g.c}</span>
                  <span className="spot-goal__n">{perGoal(gi)}/{g.n}</span>
                </div>
              ))}
            </div>}
      </div>

      <div className="act__body" style={{ paddingTop: 4 }}>
        {mode === 'count' && (
          <div className="count-q">How many {goals[0].c} can you find?
            <SayBtn onClick={() => speak(`How many ${goals[0].l}?`, { rate: .92 })} /></div>
        )}
        <div className="spot-scene" style={{ width: W, height: H, background: bg, maxWidth: '94%' }}>
          {build.map(it => {
            const isFound = !!found[it.key];
            return (
              <button key={it.key}
                className={'spot-item' + (isFound ? ' found' : '') + (it.target && mode === 'count' ? '' : '')}
                style={{ left: it.x + 'px', top: it.y + 'px', fontSize: it.size + 'px',
                  transform: `translate(-50%,-50%) rotate(${it.rot}deg)`, zIndex: isFound ? 30 : it.z }}
                onClick={(e) => tap(it, e)}>
                <span className="spot-item__c">{it.char}</span>
                {isFound && mode === 'count' && <span className="spot-item__num" style={{ background: color }}>{Object.keys(found).indexOf(it.key) + 1}</span>}
                {isFound && mode !== 'count' && <span className="spot-item__ring" style={{ borderColor: color }} />}
              </button>
            );
          })}
          {miss && <span key={miss.id} className="spot-miss" style={{ left: miss.x, top: miss.y }}>👀</span>}
          {mode === 'count' && foundCount > 0 && foundCount === totalTargets && (
            <div className="count-done">That's {totalTargets}! 🎉</div>
          )}
        </div>
        {mode === 'find' && <div className="spot-hint">🔍 Tap the hidden things — look carefully!</div>}
      </div>
    </div>
  );
}

Object.assign(window, { placeItems, SpotScene, _spShuffle });
