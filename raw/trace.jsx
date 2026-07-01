/* ============================================================
   TRACE CANVAS + SPARKLE — reusable across letter/number games
   ============================================================ */

// Reusable tracing surface. `resetKey` clears the canvas when it changes
// (use it for both new rounds and a manual "start over" by bumping a counter).
function TraceCanvas({ width, height, resetKey, threshold = 16, onCovered,
                       brush = 30, color = 'rgba(43,179,198,0.92)', children }) {
  const ref = React.useRef(null);
  const drawing = React.useRef(false);
  const count = React.useRef(0);
  const fired = React.useRef(false);

  const clear = () => {
    const c = ref.current; if (!c) return;
    c.getContext('2d').clearRect(0, 0, c.width, c.height);
    count.current = 0; fired.current = false;
  };
  React.useEffect(() => { clear(); }, [resetKey]);

  const pos = (e) => {
    const c = ref.current, r = c.getBoundingClientRect();
    const p = e.touches ? e.touches[0] : e;
    return { x: (p.clientX - r.left) * (c.width / r.width), y: (p.clientY - r.top) * (c.height / r.height) };
  };
  const begin = (e) => {
    drawing.current = true;
    const ctx = ref.current.getContext('2d');
    ctx.lineCap = 'round'; ctx.lineJoin = 'round'; ctx.lineWidth = brush; ctx.strokeStyle = color;
    const { x, y } = pos(e); ctx.beginPath(); ctx.moveTo(x, y);
    // dot so a tap leaves a mark
    ctx.lineTo(x + 0.1, y + 0.1); ctx.stroke();
  };
  const move = (e) => {
    if (!drawing.current) return; e.preventDefault();
    const ctx = ref.current.getContext('2d');
    const { x, y } = pos(e); ctx.lineTo(x, y); ctx.stroke();
    count.current++;
    if (!fired.current && count.current >= threshold) { fired.current = true; onCovered && onCovered(); }
  };
  const end = () => { drawing.current = false; };

  return (
    <div className="trace-wrap" style={{ width, height }}>
      {children}
      <canvas ref={ref} width={width} height={height} className="trace-canvas"
        onPointerDown={begin} onPointerMove={move} onPointerUp={end} onPointerLeave={end} />
    </div>
  );
}

// A quick celebratory burst of sparkles, centered on its relative parent.
function Sparkle({ show }) {
  const pieces = React.useMemo(() => {
    const icons = ['✨','⭐','🌟','💫','🎉','✨'];
    return Array.from({ length: 10 }, (_, i) => {
      const ang = (Math.PI * 2 * i) / 10 + Math.random() * 0.4;
      const dist = 90 + Math.random() * 70;
      return { icon: icons[i % icons.length], tx: Math.cos(ang) * dist, ty: Math.sin(ang) * dist, d: Math.random() * 0.15 };
    });
  }, [show]);
  if (!show) return null;
  return (
    <div className="sparkle-burst">
      {pieces.map((p, i) => (
        <span key={i} style={{ '--tx': p.tx + 'px', '--ty': p.ty + 'px', animationDelay: p.d + 's' }}>{p.icon}</span>
      ))}
    </div>
  );
}

Object.assign(window, { TraceCanvas, Sparkle });
