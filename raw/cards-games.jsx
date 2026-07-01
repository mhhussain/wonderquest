/* ============================================================
   DISCOVERY CARD MINI-GAMES — reusable engines
   Each: ({ game, color, onWin }) ; calls onWin() on success
   ============================================================ */

function _cShuffle(a){const x=[...a];for(let i=x.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[x[i],x[j]]=[x[j],x[i]];}return x;}

/* ---------- COLLECT: tap the floating items ---------- */
function CollectMini({ game, color, onWin }) {
  const n = game.n;
  const initPos = React.useMemo(() =>
    Array.from({ length: n }, () => ({ left: 10 + Math.random() * 76, top: 14 + Math.random() * 60 })), []);
  const [got, setGot] = React.useState([]);
  const gotRef = React.useRef([]);
  const [pos, setPos] = React.useState({ x: 70, y: 300 });   // mascot center in px
  const posRef = React.useRef({ x: 70, y: 300 });
  const [dragging, setDragging] = React.useState(false);
  const stageRef = React.useRef(null);
  const itemEls = React.useRef({});
  const itemsRef = React.useRef([]);
  const wonRef = React.useRef(false);

  React.useEffect(() => { gotRef.current = got; }, [got]);
  React.useEffect(() => { const t = setTimeout(() => speak(game.say, { rate: .92 }), 400); return () => clearTimeout(t); }, []);

  const collect = (k) => {
    setGot(prev => {
      if (prev.includes(k)) return prev;
      const ng = [...prev, k]; gotRef.current = ng;
      speak(String(ng.length), { rate: .95, pitch: 1.2 });
      if (ng.length >= n && !wonRef.current) { wonRef.current = true; setTimeout(onWin, 700); }
      return ng;
    });
  };

  // set up slow drifting items + animation loop
  React.useEffect(() => {
    const stage = stageRef.current;
    if (!stage) return;
    const tick = () => {
      const W = stage.clientWidth, H = stage.clientHeight;     // unscaled CSS px
      if (!W) return;
      if (itemsRef.current.length === 0) {
        itemsRef.current = initPos.map((p, k) => {
          const ang = Math.random() * Math.PI * 2;
          const sp = 0.9 + Math.random() * 1.0;                // slow drift per tick (~16ms)
          return { k, x: (p.left / 100) * W, y: (p.top / 100) * H, vx: Math.cos(ang) * sp, vy: Math.sin(ang) * sp };
        });
        posRef.current = { x: 70, y: H - 60 }; setPos({ x: 70, y: H - 60 });
      }
      const m = posRef.current;
      itemsRef.current.forEach(it => {
        if (gotRef.current.includes(it.k)) return;
        it.x += it.vx; it.y += it.vy;
        if (it.x < 26) { it.x = 26; it.vx = Math.abs(it.vx); }
        if (it.x > W - 26) { it.x = W - 26; it.vx = -Math.abs(it.vx); }
        if (it.y < 26) { it.y = 26; it.vy = Math.abs(it.vy); }
        if (it.y > H - 26) { it.y = H - 26; it.vy = -Math.abs(it.vy); }
        const el = itemEls.current[it.k];
        if (el) { el.style.left = it.x + 'px'; el.style.top = it.y + 'px'; el.style.visibility = 'visible'; }
        if (Math.hypot(it.x - m.x, it.y - m.y) < 58) collect(it.k);
      });
    };
    const id = setInterval(tick, 16);
    return () => clearInterval(id);
  }, []);

  const onDown = (e) => { e.preventDefault(); setDragging(true); };
  React.useEffect(() => {
    if (!dragging) return;
    const move = (e) => {
      const p = e.touches ? e.touches[0] : e;
      const stage = stageRef.current; if (!stage) return;
      const rect = stage.getBoundingClientRect();
      const sx = rect.width / stage.clientWidth || 1, sy = rect.height / stage.clientHeight || 1;
      const x = Math.max(30, Math.min(stage.clientWidth - 30, (p.clientX - rect.left) / sx));
      const y = Math.max(30, Math.min(stage.clientHeight - 30, (p.clientY - rect.top) / sy));
      posRef.current = { x, y }; setPos({ x, y });
    };
    const up = () => setDragging(false);
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
    return () => { window.removeEventListener('pointermove', move); window.removeEventListener('pointerup', up); };
  }, [dragging]);

  return (
    <div className="mini">
      <div className="mini__hint">{game.say}</div>
      <div className="mini__stage" ref={stageRef} style={{ background: `linear-gradient(180deg, ${color}1f, ${color}33)`, touchAction: 'none' }}>
        {initPos.map((p, k) => (
          <span key={k} ref={el => itemEls.current[k] = el}
            className={'collectible' + (got.includes(k) ? ' gone' : '')}>
            {game.item}</span>
        ))}
        <div className={'mini__who mini__who--drag' + (dragging ? ' grabbing' : '')}
          style={{ borderColor: color, left: pos.x + 'px', top: pos.y + 'px' }}
          onPointerDown={onDown}>{game.who}</div>
        <div className="mini__count" style={{ background: color }}>{game.item} {got.length}/{n}</div>
        {got.length === 0 && <div className="mini__dragtip">👆 Drag {game.who} to catch the {game.item}!</div>}
      </div>
    </div>
  );
}

/* ---------- ORDER: tap from smallest to biggest ---------- */
function OrderMini({ game, color, onWin }) {
  const sorted = React.useMemo(() => [...game.items].sort((a, b) => a.s - b.s), []);
  const shuffled = React.useMemo(() => _cShuffle(game.items), []);
  const [next, setNext] = React.useState(0);
  const [wrong, setWrong] = React.useState(null);
  React.useEffect(() => { const t = setTimeout(() => speak(game.say, { rate: .92 }), 400); return () => clearTimeout(t); }, []);
  const tap = (it) => {
    if (it.s === sorted[next].s) {
      const nn = next + 1; setNext(nn);
      speak(String(nn), { rate: .95, pitch: 1.2 });
      if (nn >= sorted.length) setTimeout(onWin, 700);
    } else { setWrong(it.e); speak('Try again!', { rate: .95 }); setTimeout(() => setWrong(null), 450); }
  };
  return (
    <div className="mini">
      <div className="mini__hint">{game.say}</div>
      <div className="mini__order">
        {shuffled.map((it, i) => {
          const done = sorted.findIndex(s => s.s === it.s) < next;
          const rank = sorted.findIndex(s => s.s === it.s) + 1;
          return (
            <button key={i} className={'order-item' + (done ? ' done' : '') + (wrong === it.e ? ' wrong' : '')}
              style={{ '--c1': color, fontSize: (34 + it.s * 16) + 'px' }} onClick={() => tap(it)} disabled={done}>
              {it.e}
              {done && <span className="order-rank" style={{ background: color }}>{rank}</span>}
            </button>
          );
        })}
      </div>
    </div>
  );
}

/* ---------- BUILD: tap pieces bottom→top to stack ---------- */
function BuildMini({ game, color, onWin }) {
  const order = game.pieces;                  // correct bottom→top
  const tray = React.useMemo(() => _cShuffle(game.pieces.map((e, i) => ({ e, i }))), []);
  const [placed, setPlaced] = React.useState(0);
  const [wrong, setWrong] = React.useState(null);
  React.useEffect(() => { const t = setTimeout(() => speak(game.say, { rate: .92 }), 400); return () => clearTimeout(t); }, []);
  const tap = (piece) => {
    if (piece.i === placed) {
      const np = placed + 1; setPlaced(np);
      speak(np >= order.length ? 'You built it!' : 'Nice!', { rate: .95 });
      if (np >= order.length) setTimeout(onWin, 800);
    } else { setWrong(piece.i); speak('Not that one!', { rate: .95 }); setTimeout(() => setWrong(null), 450); }
  };
  return (
    <div className="mini">
      <div className="mini__hint">{game.say}</div>
      <div className="build-stage">
        {order.slice(0, placed).map((e, i) => (
          <div key={i} className="build-block placed" style={{ animationDelay: '0s' }}>{e}</div>
        )).reverse()}
        {placed === 0 && <div className="build-ground">⬇️ start at the bottom</div>}
      </div>
      <div className="build-tray">
        {tray.map((p, k) => (
          <button key={k} className={'build-piece' + (p.i < placed ? ' used' : '') + (wrong === p.i ? ' wrong' : '')}
            style={{ '--c1': color }} onClick={() => tap(p)} disabled={p.i < placed}>{p.e}</button>
        ))}
      </div>
    </div>
  );
}

/* ---------- DECORATE: tap the glowing spots ---------- */
function DecorateMini({ game, color, onWin }) {
  const spots = React.useMemo(() =>
    Array.from({ length: game.n }, (_, k) => ({
      k, left: 18 + Math.random() * 64, top: 18 + Math.random() * 58,
    })), []);
  const [done, setDone] = React.useState([]);
  React.useEffect(() => { const t = setTimeout(() => speak(game.say, { rate: .92 }), 400); return () => clearTimeout(t); }, []);
  const tap = (k) => {
    setDone(prev => {
      if (prev.includes(k)) return prev;
      const nd = [...prev, k];
      speak(String(nd.length), { rate: .95, pitch: 1.2 });
      if (nd.length >= game.n) setTimeout(onWin, 700);
      return nd;
    });
  };
  return (
    <div className="mini">
      <div className="mini__hint">{game.say}</div>
      <div className="decorate-stage" style={{ background: `radial-gradient(circle at 50% 45%, ${color}22, ${color}44)` }}>
        <div className="decorate-base">{game.base}</div>
        {spots.map(s => (
          <button key={s.k} className={'decorate-spot' + (done.includes(s.k) ? ' filled' : '')}
            style={{ left: s.left + '%', top: s.top + '%' }} onClick={() => tap(s.k)}>
            {done.includes(s.k) ? game.spot : '✨'}
          </button>
        ))}
        <div className="mini__count" style={{ background: color }}>{game.spot} {done.length}/{game.n}</div>
      </div>
    </div>
  );
}

/* ---------- FIND: tap the hidden targets in a scene ---------- */
function FindMini({ game, color, onWin }) {
  const SCENE = 20;
  const layout = React.useMemo(() => {
    const targets = new Set();
    while (targets.size < game.n) targets.add(Math.floor(Math.random() * SCENE));
    return Array.from({ length: SCENE }, (_, k) => targets.has(k)
      ? { e: game.target, isT: true, k }
      : { e: game.deco[Math.floor(Math.random() * game.deco.length)], isT: false, k });
  }, []);
  const [found, setFound] = React.useState([]);
  React.useEffect(() => { const t = setTimeout(() => speak(game.say, { rate: .92 }), 400); return () => clearTimeout(t); }, []);
  const tap = (it) => {
    if (!it.isT) { speak('Keep looking!', { rate: .95 }); return; }
    setFound(prev => {
      if (prev.includes(it.k)) return prev;
      const nf = [...prev, it.k];
      speak(String(nf.length), { rate: .95, pitch: 1.2 });
      if (nf.length >= game.n) setTimeout(onWin, 700);
      return nf;
    });
  };
  return (
    <div className="mini">
      <div className="mini__hint">{game.say}</div>
      <div className="find-mini" style={{ background: `linear-gradient(180deg, ${color}1f, ${color}33)` }}>
        {layout.map(it => (
          <button key={it.k} className={'find-mini__i' + (found.includes(it.k) ? ' found' : '')}
            onClick={() => tap(it)}>{it.e}</button>
        ))}
        <div className="mini__count" style={{ background: color }}>{game.target} {found.length}/{game.n}</div>
      </div>
    </div>
  );
}

const MINI_ENGINES = { collect: CollectMini, order: OrderMini, build: BuildMini, decorate: DecorateMini, find: FindMini };
Object.assign(window, { CollectMini, OrderMini, BuildMini, DecorateMini, FindMini, MINI_ENGINES });
