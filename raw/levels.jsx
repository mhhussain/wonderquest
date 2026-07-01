/* ============================================================
   LEVELS UI — "Pick a Game" select (10 games) + wrapper
   ============================================================ */

function LevelSelect({ title, emoji, color, games, perGame, done, onPick, onExit }) {
  const doneCount = done.filter(Boolean).length;
  React.useEffect(() => { speak(`${title}. Pick a game!`, { rate: .95 }); }, []);
  return (
    <div className="act sky-bg">
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Games</button>
        <div>
          <div className="act__title">{emoji} {title}</div>
          <div className="act__sub">Pick a game — each one has {perGame} questions</div>
        </div>
        <div className="hud__spacer" />
        <div className="act__sub" style={{ marginRight: 4 }}>{doneCount} / {games} done</div>
      </div>

      <div className="act__body" style={{ justifyContent: 'center' }}>
        <div className="level-grid" style={{ gridTemplateColumns: `repeat(${Math.min(games, 5)}, 1fr)`, maxWidth: Math.min(games, 5) * 168 }}>
          {Array.from({ length: games }).map((_, g) => {
            const isDone = !!done[g];
            return (
              <button key={g} className={'level-tile' + (isDone ? ' done' : '')}
                style={{ background: color }}
                onClick={() => { speak(`Game ${g + 1}`, { rate: .95 }); onPick(g); }}>
                <span className="level-tile__lbl">Game {g + 1}</span>
                {isDone && <span className="level-tile__star">⭐</span>}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// Wraps a quiz game: shows the 10-game picker, then plays the chosen game
// with a pre-dealt deck of `perGame` questions.
function GameLevels({ typeId, title, emoji, color, pool, keyOf, perGame = 15, games = 10, render, onComplete, onExit }) {
  const plan = React.useMemo(() => dealGames(pool, games, perGame, keyOf), []);
  const [active, setActive] = React.useState(null);
  const [done, setDone] = React.useState(() => getLevels()[typeId] || []);

  if (active == null) {
    return <LevelSelect title={title} emoji={emoji} color={color} games={games} perGame={perGame}
      done={done} onPick={setActive} onExit={onExit} />;
  }
  const complete = (reward) => {
    markLevel(typeId, active);
    setDone(getLevels()[typeId] || []);
    onComplete({ ...reward, message: `Game ${active + 1} complete! ${reward.message || ''}`.trim() });
  };
  return render(plan[active], active, complete, () => setActive(null));
}

Object.assign(window, { LevelSelect, GameLevels });
