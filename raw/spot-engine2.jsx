/* ============================================================
   SPOT ME — Match the Socks + Spot the Difference
   ============================================================ */

/* ---------- a single sock rendered as a styled shape ---------- */
function Sock({ color, pattern, faded, onClick, picked, matched }) {
  const patBg = {
    solid: color,
    stripe: `repeating-linear-gradient(45deg, ${color} 0 8px, #fff7 8px 14px)`,
    dots: `radial-gradient(#fff9 22%, transparent 24%) 0 0/14px 14px, ${color}`,
    zig: `repeating-linear-gradient(135deg, ${color} 0 7px, #0002 7px 12px)`,
  }[pattern] || color;
  return (
    <button className={'sock' + (picked ? ' picked' : '') + (matched ? ' matched' : '')}
      onClick={onClick} disabled={matched} aria-label="sock">
      <span className="sock__shape" style={{ background: patBg, opacity: faded ? .3 : 1 }} />
    </button>
  );
}

function MatchSocks({ level, onWin, onExit }) {
  const cfg = SOCK_LEVELS[level] || SOCK_LEVELS[0];
  const socks = React.useMemo(() => {
    const out = [];
    const colors = _spShuffle(SOCK_COLORS).slice(0, cfg.pairs);
    for (let i = 0; i < cfg.pairs; i++) {
      const color = cfg.by === 'pattern' ? SOCK_COLORS[2] : colors[i];
      const pattern = cfg.by === 'color' ? 'solid' : SOCK_PATTERNS[i % SOCK_PATTERNS.length];
      const sig = color + '|' + pattern;
      out.push({ id: 'a' + i, color, pattern, sig }, { id: 'b' + i, color, pattern, sig });
    }
    return _spShuffle(out);
  }, []);
  const [matched, setMatched] = React.useState({});
  const [pick, setPick] = React.useState(null);
  const [shake, setShake] = React.useState(null);
  const wonRef = React.useRef(false);

  React.useEffect(() => { const t = setTimeout(() => speak(cfg.say, { rate: .92 }), 400); return () => clearTimeout(t); }, []);

  const click = (s) => {
    if (matched[s.id] || (pick && pick.id === s.id)) return;
    if (!pick) { setPick(s); return; }
    if (pick.sig === s.sig) {
      const nm = { ...matched, [pick.id]: true, [s.id]: true };
      setMatched(nm); setPick(null);
      speak('Match!', { rate: .95, pitch: 1.15 });
      if (Object.keys(nm).length >= cfg.pairs * 2 && !wonRef.current) { wonRef.current = true; setTimeout(onWin, 800); }
    } else {
      setShake(s.id); speak('Not a match, try again!', { rate: .95 });
      setTimeout(() => { setShake(null); setPick(null); }, 600);
    }
  };

  const pairsDone = Object.keys(matched).length / 2;
  return (
    <div className="act">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Detective</button>
        <div><div className="act__title">🧦 Match the Socks</div>
          <div className="act__sub">{cfg.say}</div></div>
        <div className="hud__spacer" />
        <div className="spot-counter" style={{ background: 'var(--grape)' }}>🧦 {pairsDone}/{cfg.pairs}</div>
      </div>
      <div className="act__body">
        <div className="sock-pile">
          {socks.map(s => (
            <div key={s.id} className={shake === s.id ? 'shake-x' : ''}>
              <Sock color={s.color} pattern={s.pattern} picked={pick && pick.id === s.id}
                matched={!!matched[s.id]} onClick={() => click(s)} />
            </div>
          ))}
        </div>
        <div className="spot-hint">🧺 Tap two socks that are the same!</div>
      </div>
    </div>
  );
}

/* ---------- Spot the Difference ----------
   two panels of the same scattered emoji; a few items in B are
   removed/changed; child taps the spots that differ in panel B
*/
function SpotDifference({ round, onWin, onExit }) {
  const W = 460, H = 430, NDIFF = round.diffs || 5;
  const data = React.useMemo(() => {
    const sc = SPOT_SCENES[round.scene];
    const pool = sc.deco.concat(round.extra || []);
    const n = 18;
    const items = Array.from({ length: n }, (_, k) => ({ k, char: pool[Math.floor(Math.random() * pool.length)] }));
    const pos = placeItems(n, W, H, { size: 38, rot: 14 });
    const placed = items.map((it, i) => ({ ...it, ...pos[i] }));
    // choose diff indices
    const diffIdx = _spShuffle(placed.map(p => p.k)).slice(0, NDIFF);
    const bChanges = {};
    diffIdx.forEach(k => {
      if (Math.random() < 0.5) bChanges[k] = { removed: true };
      else { let nc; do { nc = pool[Math.floor(Math.random() * pool.length)]; } while (nc === placed[k].char); bChanges[k] = { char: nc }; }
    });
    return { placed, diffIdx, bChanges, sc };
  }, []);

  const [found, setFound] = React.useState([]);
  const [miss, setMiss] = React.useState(null);
  const wonRef = React.useRef(false);

  React.useEffect(() => { const t = setTimeout(() => speak(`Find ${NDIFF} differences between the two pictures!`, { rate: .92 }), 400); return () => clearTimeout(t); }, []);

  const tapB = (k, e) => {
    if (data.diffIdx.includes(k)) {
      if (found.includes(k)) return;
      const nf = [...found, k]; setFound(nf);
      speak(String(nf.length), { rate: .95, pitch: 1.2 });
      if (nf.length >= NDIFF && !wonRef.current) { wonRef.current = true; setTimeout(onWin, 800); }
    } else {
      const r = e.currentTarget.getBoundingClientRect();
      const pr = e.currentTarget.closest('.diff-panel').getBoundingClientRect();
      setMiss({ x: e.clientX - pr.left, y: e.clientY - pr.top, id: Date.now() });
      setTimeout(() => setMiss(null), 500);
    }
  };

  const renderItem = (it, panel) => {
    const ch = data.bChanges[it.k];
    if (panel === 'B' && ch?.removed) return null;
    const char = (panel === 'B' && ch?.char) ? ch.char : it.char;
    const isFound = panel === 'B' && found.includes(it.k);
    return (
      <button key={panel + it.k} className={'diff-item' + (isFound ? ' found' : '')}
        style={{ left: it.x + 'px', top: it.y + 'px', fontSize: it.size + 'px', transform: `translate(-50%,-50%) rotate(${it.rot}deg)` }}
        onClick={panel === 'B' ? (e) => tapB(it.k, e) : undefined}>
        {char}{isFound && <span className="diff-ring" />}
      </button>
    );
  };

  // spots that are "removed" in B leave an empty tappable hole
  const holes = data.placed.filter(it => data.bChanges[it.k]?.removed);

  return (
    <div className="act">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Detective</button>
        <div><div className="act__title">🆚 Spot the Difference</div>
          <div className="act__sub">{data.sc.name} — find {NDIFF} differences</div></div>
        <div className="hud__spacer" />
        <div className="spot-counter" style={{ background: 'var(--coral)' }}>🔍 {found.length}/{NDIFF}</div>
      </div>
      <div className="act__body">
        <div className="diff-wrap">
          <div className="diff-panel" style={{ width: W, height: H, background: data.sc.bg }}>
            <span className="diff-tag">Picture 1</span>
            {data.placed.map(it => renderItem(it, 'A'))}
          </div>
          <div className="diff-panel" style={{ width: W, height: H, background: data.sc.bg }}>
            <span className="diff-tag">Picture 2</span>
            {data.placed.map(it => renderItem(it, 'B'))}
            {holes.map(it => (
              <button key={'hole' + it.k} className={'diff-hole' + (found.includes(it.k) ? ' found' : '')}
                style={{ left: it.x + 'px', top: it.y + 'px' }} onClick={(e) => tapB(it.k, e)}>
                {found.includes(it.k) && <span className="diff-ring" />}
              </button>
            ))}
            {miss && <span key={miss.id} className="spot-miss" style={{ left: miss.x, top: miss.y }}>👀</span>}
          </div>
        </div>
        <div className="spot-hint">🔍 Tap what's different in Picture 2!</div>
      </div>
    </div>
  );
}

Object.assign(window, { MatchSocks, SpotDifference, Sock });
