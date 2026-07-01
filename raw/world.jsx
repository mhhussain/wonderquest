/* ============================================================
   AROUND THE WORLD — travel adventure module
   States: map → flying → continent ; Passport overlay
   ============================================================ */

function _wShuffle(a){const x=[...a];for(let i=x.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[x[i],x[j]]=[x[j],x[i]];}return x;}

/* ---------- persistent world progress ---------- */
function loadWorld(){ try { return JSON.parse(localStorage.getItem('dinodig_world')||'{}'); } catch(e){ return {}; } }
function saveWorld(w){ try { localStorage.setItem('dinodig_world', JSON.stringify(w)); } catch(e){} }

/* ============================================================
   WORLD MAP — tappable continents
   ============================================================ */
/* simplified, stylized continent silhouettes on a 1000×560 ocean */
const CONTINENT_PATHS = {
  namerica:  'M92,92 C120,60 205,54 244,82 C284,72 305,104 286,132 C302,152 272,168 256,162 C242,184 226,166 221,192 C216,218 201,244 188,222 C182,201 191,181 172,179 C150,202 118,186 130,150 C99,150 80,118 92,92 Z',
  samerica:  'M252,292 C302,286 328,318 313,352 C322,388 296,422 281,458 C273,478 257,472 258,450 C244,421 234,386 240,351 C228,326 231,302 252,292 Z',
  europe:    'M462,92 C502,78 545,86 538,112 C552,128 527,143 511,137 C501,158 477,152 475,131 C454,129 449,102 462,92 Z',
  africa:    'M502,196 C562,180 614,202 602,248 C618,289 587,333 561,373 C549,399 519,394 514,362 C493,342 484,301 496,270 C474,256 470,217 502,196 Z',
  asia:      'M582,100 C654,68 786,68 858,100 C900,121 889,162 857,177 C878,203 826,218 805,197 C784,223 742,212 732,186 C690,202 638,186 640,160 C598,166 560,135 582,100 Z',
  australia: 'M784,360 C846,344 898,366 887,402 C892,433 850,453 814,447 C778,458 757,427 768,401 C757,379 763,365 784,360 Z',
  antarctica:'M150,502 C352,486 652,486 862,506 C884,522 852,542 700,540 C450,547 250,542 146,533 C120,521 130,506 150,502 Z',
};
const CONTINENT_LABELS = {
  namerica:{x:182,y:150}, samerica:{x:279,y:378}, europe:{x:500,y:116},
  africa:{x:546,y:292}, asia:{x:722,y:150}, australia:{x:824,y:406}, antarctica:{x:502,y:516},
};

function WorldMap({ world, onPick, onPassport, onExit }) {
  React.useEffect(() => { speak('Where in the world should we explore today?', { rate: .95 }); }, []);
  const stamps = Object.keys(world.visited || {}).length;
  return (
    <div className="act world-sky">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Map</button>
        <div>
          <div className="act__title">🌍 Around the World</div>
          <div className="act__sub">Tap a place to fly there with Pip the parrot!</div>
        </div>
        <div className="hud__spacer" />
        <button className="passport-btn" onClick={onPassport}>
          <span style={{ fontSize: 22 }}>🛂</span>
          <span>Passport</span>
          <span className="passport-btn__count">{stamps}/7</span>
        </button>
      </div>

      <div className="act__body" style={{ justifyContent: 'center', paddingTop: 0 }}>
        <svg className="worldmap" viewBox="0 0 1000 560" preserveAspectRatio="xMidYMid meet">
          <defs>
            <radialGradient id="ocean" cx="50%" cy="40%" r="75%">
              <stop offset="0%" stopColor="#BFE8F7" />
              <stop offset="100%" stopColor="#8FCDEA" />
            </radialGradient>
            <filter id="landshadow" x="-20%" y="-20%" width="140%" height="140%">
              <feDropShadow dx="0" dy="5" stdDeviation="5" floodColor="#1c5a78" floodOpacity="0.32" />
            </filter>
          </defs>
          <rect x="0" y="0" width="1000" height="560" rx="34" fill="url(#ocean)" />
          {/* faint latitude/longitude lines */}
          <g stroke="#ffffff" strokeOpacity="0.22" strokeWidth="2">
            <line x1="0" y1="187" x2="1000" y2="187" /><line x1="0" y1="373" x2="1000" y2="373" />
            <line x1="333" y1="0" x2="333" y2="560" /><line x1="667" y1="0" x2="667" y2="560" />
          </g>
          {WORLD.map(c => {
            const visited = world.visited && world.visited[c.id];
            const L = CONTINENT_LABELS[c.id];
            return (
              <g key={c.id} className={'land' + (visited ? ' land--visited' : '')}
                onClick={() => { speak('Fly to ' + c.name, { rate: .95 }); onPick(c); }}>
                <path d={CONTINENT_PATHS[c.id]} fill={c.color} stroke="#fff" strokeWidth="3.5"
                  strokeLinejoin="round" filter="url(#landshadow)" />
                <text x={L.x} y={L.y - 6} textAnchor="middle" className="land__icon">{c.emoji}</text>
                <text x={L.x} y={L.y + 26} textAnchor="middle" className="land__label">{c.name}</text>
                {visited && <text x={L.x} y={L.y - 40} textAnchor="middle" className="land__check">{c.badge}</text>}
              </g>
            );
          })}
        </svg>
        <div className="world-legend">🧭 {stamps === 0 ? 'Tap any land to start your first adventure!' : `You've explored ${stamps} of 7 places. Keep going, Explorer!`}</div>
      </div>
    </div>
  );
}

/* ============================================================
   TRAVEL — airport → takeoff → flight → arrive
   ============================================================ */
function Travel({ continent, onArrive }) {
  const [phase, setPhase] = React.useState('board'); // board → fly → land
  React.useEffect(() => {
    speak(`Buckle up! Let's fly to ${continent.name}!`, { rate: .95 });
    const t1 = setTimeout(() => setPhase('fly'), 1700);
    const t2 = setTimeout(() => { setPhase('land'); speak(`We have arrived in ${continent.name}!`, { rate: .95 }); }, 4600);
    const t3 = setTimeout(() => onArrive(), 6200);
    return () => { clearTimeout(t1); clearTimeout(t2); clearTimeout(t3); };
  }, []);

  return (
    <div className={'travel travel--' + phase}>
      <div className="travel__sky">
        {Array.from({ length: 7 }).map((_, k) => <span key={k} className="cloud" style={{ '--i': k }}>☁️</span>)}
        <div className="travel__sea">🌊🌊🌊🌊🌊🌊🌊🌊</div>
      </div>
      <div className="travel__plane">✈️</div>
      <div className="travel__banner">
        {phase === 'board' && <><b>✈️ Boarding…</b><span>Next stop: {continent.name}</span></>}
        {phase === 'fly' && <><b>Flying over the ocean! 🌊</b><span>Look at the clouds go by…</span></>}
        {phase === 'land' && <><b>{continent.emoji} Welcome to {continent.name}!</b><span>{continent.blurb}</span></>}
      </div>
      <div className="travel__dest" style={{ '--c1': continent.color, '--c2': continent.color2 }}>
        <span>{continent.emoji}</span>
      </div>
    </div>
  );
}

/* ============================================================
   HIDDEN DISCOVERY — find N animals in a busy scene
   ============================================================ */
function Discovery({ continent, onDone, onBack }) {
  const target = continent.mission;
  const SCENE = 26;
  const layout = React.useMemo(() => {
    const targets = new Set();
    while (targets.size < target.count) targets.add(Math.floor(Math.random() * SCENE));
    // filler emojis from this continent's animals (minus the target) + scenery
    const others = continent.animals.map(a => a.e).filter(e => e !== target.find);
    const scenery = ['🌳','🌴','🪨','🌾','🌸','⛰️','🌵','🍃','🪵','🌿'];
    const pool = [...others, ...scenery];
    return Array.from({ length: SCENE }, (_, k) =>
      targets.has(k) ? target.find : pool[Math.floor(Math.random() * pool.length)]
    ).map((e, k) => ({ e, k, isTarget: e === target.find,
      rot: Math.random() * 30 - 15, sz: 0.85 + Math.random() * 0.5 }));
  }, []);
  const [found, setFound] = React.useState([]);
  const realTargets = layout.filter(t => t.isTarget).length;

  React.useEffect(() => { const t = setTimeout(() => speak(`Find ${target.count} ${target.n}!`, { rate: .9 }), 700); return () => clearTimeout(t); }, []);

  const tap = (item) => {
    if (!item.isTarget) { speak('Keep looking!', { rate: .95 }); return; }
    setFound(prev => {
      if (prev.includes(item.k)) return prev;
      const nf = [...prev, item.k];
      speak(String(nf.length), { rate: .95, pitch: 1.2 });
      if (nf.length >= Math.min(target.count, realTargets)) setTimeout(() => onDone(), 800);
      return nf;
    });
  };

  return (
    <div className="act" style={{ background: 'linear-gradient(180deg,' + continent.color2 + '33,' + continent.color + '22)' }}>
      <div className="act__bar">
        <button className="back-btn" onClick={onBack}>⟵ Back</button>
        <div>
          <div className="act__title">🔍 Hidden Discovery</div>
          <div className="act__sub">Find all the {target.find} {target.n}!</div>
        </div>
        <div className="hud__spacer" />
        <div className="find-count">{found.length} / {Math.min(target.count, realTargets)} {target.find}</div>
      </div>
      <div className="act__body" style={{ justifyContent: 'center' }}>
        <div className="find-scene">
          {layout.map(item => (
            <button key={item.k}
              className={'find-item' + (found.includes(item.k) ? ' found' : '')}
              style={{ transform: `rotate(${item.rot}deg) scale(${item.sz})` }}
              onClick={() => tap(item)}>
              {item.e}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { WorldMap, Travel, Discovery, loadWorld, saveWorld, _wShuffle });
