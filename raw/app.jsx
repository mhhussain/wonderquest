/* ============================================================
   APP ROOT — routing, reward flow, scaling
   ============================================================ */

function App() {
  const [state, update] = useGame();
  const [screen, setScreen] = React.useState('home');   // home | letter | number | animal | parent
  const [reward, setReward] = React.useState(null);
  const [showColl, setShowColl] = React.useState(false);
  const [replayKey, setReplayKey] = React.useState(0);

  const open = (id) => { setScreen(id); };
  const home = () => setScreen('home');

  const complete = (result) => {
    update(s => applyReward(s, result));
    if (!result.silent) setReward(result);
  };
  const closeReward = () => { setReward(null); home(); };
  const again = () => { setReward(null); setReplayKey(k => k + 1); };

  const onAnimal = (name) => update(s => ({ animalsFound: [...new Set([...s.animalsFound, name])] }));

  let body;
  if (screen === 'home')
    body = <Home state={state} update={update} onOpen={open}
      onCollections={() => setShowColl(true)} onParent={() => setScreen('parent')} />;
  else if (screen === 'parent')
    body = <ParentDashboard state={state} onExit={home} />;
  else {
    // activity screens share the HUD on top
    const inner =
      screen === 'letter' ? <LetterAdventure key={replayKey} onComplete={complete} onExit={home} /> :
      screen === 'number' ? <NumberKingdom key={replayKey} onComplete={complete} onExit={home} /> :
      screen === 'math' ? <MathLab key={replayKey} onComplete={complete} onExit={home} /> :
      screen === 'world' ? <AroundWorld key={replayKey} onComplete={complete} onExit={home} onAnimal={onAnimal} /> :
      screen === 'find' ? <SpotMe key={replayKey} onComplete={complete} onExit={home} /> :
      screen === 'hoorof' ? <Hoorof key={replayKey} onComplete={complete} onExit={home} /> :
      screen === 'animal' ? <AnimalPlanet key={replayKey} onComplete={complete} onExit={home} onAnimal={onAnimal} /> : null;
    body = (
      <div className="app sky-bg">
        <Hud state={state} update={update}
          onCollections={() => setShowColl(true)} onParent={() => setScreen('parent')} />
        {inner}
      </div>
    );
  }

  return (
    <>
      {body}
      {reward && <RewardModal result={reward} onClose={closeReward} onAgain={again} />}
      {showColl && <Collections state={state} onClose={() => setShowColl(false)} />}
    </>
  );
}

/* ---------- Scale the fixed 1194×834 iPad to fit any viewport ---------- */
function fitStage() {
  const scaler = document.getElementById('scaler');
  if (!scaler) return;
  const pad = 28;
  const sw = (window.innerWidth - pad) / 1230;
  const sh = (window.innerHeight - pad) / 870;
  const s = Math.min(sw, sh);
  scaler.style.transform = `scale(${s})`;
}
window.addEventListener('resize', fitStage);
window.addEventListener('load', fitStage);
fitStage();

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
