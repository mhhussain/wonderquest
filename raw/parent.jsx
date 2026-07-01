/* ============================================================
   PARENT DASHBOARD
   ============================================================ */

function ParentDashboard({ state, onExit }) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
  const mastered = state.lettersMastered;
  const learning = state.lettersLearning;
  const weekTotal = state.week.reduce((a, b) => a + b, 0);
  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  const maxDay = Math.max(...state.week, 1);

  const skills = [
    { lbl: 'Letter ID', pct: Math.round(mastered.length / 26 * 100), color: 'var(--orange)' },
    { lbl: 'Letter Sounds', pct: 38, color: 'var(--coral)' },
    { lbl: 'Numbers 1–20', pct: Math.round(state.numbersMastered.length / 20 * 100), color: 'var(--teal)' },
    { lbl: 'Counting', pct: 55, color: 'var(--sky)' },
    { lbl: 'Tracing', pct: 62, color: 'var(--green)' },
    { lbl: 'Animals & World', pct: 44, color: 'var(--grape)' },
  ];

  return (
    <div className="app">
      <div className="parent">
        <div className="parent__head">
          <button className="back-btn" onClick={onExit}>⟵ Back to app</button>
          <h1>👪 Grown-Up Dashboard</h1>
          <div className="hud__spacer" />
          <div className="act__sub">Hassan • Age 5 • Prepping for GSRP (Aug)</div>
        </div>

        <div className="parent__grid">
          {/* top stats */}
          <div className="pcard span-3">
            <h3>⏱️ Today</h3>
            <div className="stat-big">{state.minutesToday}<span style={{ fontSize: 20 }}> min</span></div>
            <div className="stat-sub">Goal: 20 min • short & focused</div>
          </div>
          <div className="pcard span-3">
            <h3>🔥 Streak</h3>
            <div className="stat-big">{state.streak}<span style={{ fontSize: 20 }}> days</span></div>
            <div className="stat-sub">Best: 5 days</div>
          </div>
          <div className="pcard span-3">
            <h3>🔤 Letters</h3>
            <div className="stat-big">{mastered.length}<span style={{ fontSize: 20 }}>/26</span></div>
            <div className="stat-sub">{learning.length} more in progress</div>
          </div>
          <div className="pcard span-3">
            <h3>🔢 Numbers</h3>
            <div className="stat-big">{state.numbersMastered.length}<span style={{ fontSize: 20 }}>/20</span></div>
            <div className="stat-sub">Counts to {state.numbersMastered.length} reliably</div>
          </div>

          {/* Alphabet mastery */}
          <div className="pcard span-7">
            <h3>Letter recognition — uppercase & lowercase</h3>
            <div className="alpha-grid">
              {alphabet.map(l => {
                const m = mastered.includes(l), g = learning.includes(l);
                return <div key={l} className={'alpha' + (m ? ' mastered' : g ? ' learning' : '')}>{l}</div>;
              })}
            </div>
            <div style={{ display: 'flex', gap: 16, marginTop: 14, fontSize: 13, fontWeight: 800, color: 'var(--ink-soft)' }}>
              <span><i style={{ display: 'inline-block', width: 12, height: 12, borderRadius: 4, background: 'var(--green)', marginRight: 6 }} />Mastered</span>
              <span><i style={{ display: 'inline-block', width: 12, height: 12, borderRadius: 4, background: 'var(--yellow)', marginRight: 6 }} />Learning</span>
              <span><i style={{ display: 'inline-block', width: 12, height: 12, borderRadius: 4, background: '#EFE8DD', marginRight: 6 }} />Not started</span>
            </div>
          </div>

          {/* This week */}
          <div className="pcard span-5">
            <h3>This week — {weekTotal} min total</h3>
            <div className="week">
              {state.week.map((m, k) => (
                <div key={k} className="day">
                  <i style={{ height: `${Math.max(6, m / maxDay * 100)}%`, background: k === 6 ? 'var(--orange)' : 'var(--teal)' }} />
                  <b>{days[k]}</b>
                </div>
              ))}
            </div>
            <div className="stat-sub" style={{ marginTop: 8 }}>Consistent mornings work best for Hassan's focus.</div>
          </div>

          {/* Skill progress bars */}
          <div className="pcard span-7">
            <h3>Skill progress</h3>
            {skills.map(s => (
              <div className="bar-row" key={s.lbl}>
                <span className="lbl">{s.lbl}</span>
                <span className="bar-track"><i style={{ width: s.pct + '%', background: s.color }} /></span>
                <span className="pct">{s.pct}%</span>
              </div>
            ))}
          </div>

          {/* Needs practice + wins */}
          <div className="pcard span-5">
            <h3>Coach notes</h3>
            <div className="flag">⚠️ Practice lowercase <b style={{ margin: '0 4px' }}>b / d</b> — often mixed up</div>
            <div className="flag">⚠️ Letter sounds for <b style={{ margin: '0 4px' }}>g, j, q</b></div>
            <div className="flag" style={{ background: '#EAF7DC' }}>✅ Counting to 8 — solid!</div>
            <div className="flag" style={{ background: '#EAF7DC' }}>✅ Loves Animal Homes — great for vocabulary</div>
            <div className="stat-sub" style={{ marginTop: 6 }}>Tip: keep sessions to ~15 min, then switch lands to hold attention.</div>
          </div>

          {/* GSRP readiness */}
          <div className="pcard span-12" style={{ display: 'flex', alignItems: 'center', gap: 26 }}>
            <div className="ring" style={{ '--p': 58 }}><span>58%</span></div>
            <div>
              <h3 style={{ margin: '0 0 4px' }}>GSRP Readiness</h3>
              <div className="stat-sub" style={{ fontSize: 16 }}>
                Hassan is <b style={{ color: 'var(--green-d)' }}>ahead of pace</b> for an incoming GSRP student.
                Keep building letter sounds and lowercase recognition to reach the summer goal.
              </div>
            </div>
            <div className="hud__spacer" />
            <button className="btn btn--green">📄 Email weekly report</button>
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { ParentDashboard });
