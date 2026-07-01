/* ============================================================
   DISCOVERY CARDS — deck grid + flip card + play flow
   ============================================================ */

/* ---------- Deck of collectible cards for a continent ---------- */
function DiscoveryDeck({ continent, world, onPlay, onBack }) {
  const c = continent;
  const cards = CARD_SETS[c.id] || [];
  const collected = world.discovery || {};
  const got = cards.filter((_, i) => collected[c.id + '-' + i]).length;
  React.useEffect(() => { speak('Discovery Cards! Tap a card to learn and play.', { rate: .92 }); }, []);
  return (
    <div className="act" style={{ background: `linear-gradient(180deg, ${c.color2}2e, ${c.color}1f)` }}>
      <div className="act__bar">
        <button className="back-btn" onClick={onBack}>⟵ {c.name}</button>
        <div>
          <div className="act__title">🃏 {c.name} Discovery Cards</div>
          <div className="act__sub">Collect them all — tap to learn & play!</div>
        </div>
        <div className="hud__spacer" />
        <div className="find-count" style={{ background: c.color }}>🃏 {got}/{cards.length}</div>
      </div>
      <div className="act__body" style={{ justifyContent: 'center' }}>
        <div className="deck">
          {cards.map((card, i) => {
            const id = c.id + '-' + i;
            const have = !!collected[id];
            return (
              <button key={id} className={'deck-card' + (have ? ' have' : '')}
                style={{ '--c1': c.color, '--c2': c.color2 }}
                onClick={() => { speak(card.title, { rate: .92 }); onPlay({ ...card, id, cont: c.id }); }}>
                <span className="deck-card__shine" />
                <span className="deck-card__e">{card.e}</span>
                <span className="deck-card__t">{card.title}</span>
                {have ? <span className="deck-card__badge">{card.sticker}</span>
                      : <span className="deck-card__new">NEW</span>}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

/* ---------- A single card: flip → fact → play ---------- */
function DiscoveryCard({ card, color, color2, already, onWin, onExit }) {
  const [stage, setStage] = React.useState('front'); // front | back | play | done
  React.useEffect(() => { const t = setTimeout(() => speak(card.title + '. Tap the card!', { rate: .92 }), 350); return () => clearTimeout(t); }, []);

  const flip = () => { setStage('back'); speak(card.fact, { rate: .9 }); };
  const Engine = MINI_ENGINES[card.game.type];

  const win = () => { setStage('done'); speak('You did it! Card collected!', { rate: .95 }); setTimeout(() => onWin(), 1500); };

  return (
    <div className="act" style={{ background: `linear-gradient(180deg, ${color2}33, ${color}22)` }}>
      <div className="act__bar">
        <button className="back-btn" onClick={onExit}>⟵ Cards</button>
        <div>
          <div className="act__title">{card.e} {card.title}</div>
          <div className="act__sub">{stage === 'play' ? 'Play the game!' : 'Discovery Card'}</div>
        </div>
      </div>

      <div className="act__body" style={{ justifyContent: 'center' }}>
        {(stage === 'front' || stage === 'back') && (
          <div className={'disco-card' + (stage === 'back' ? ' flipped' : '')} onClick={stage === 'front' ? flip : undefined}>
            <div className="disco-card__inner">
              <div className="disco-card__face disco-card__front" style={{ '--c1': color, '--c2': color2 }}>
                <span className="disco-card__shine" />
                <div className="disco-card__e">{card.e}</div>
                <div className="disco-card__t">{card.title}</div>
                <div className="disco-card__tap">👆 Tap to flip</div>
              </div>
              <div className="disco-card__face disco-card__back" style={{ '--c1': color }}>
                <div className="disco-card__factico">💡</div>
                <div className="disco-card__fact">{card.fact}</div>
                <button className="btn btn--lg" style={{ background: color, boxShadow: '0 5px 0 ' + color2 }}
                  onClick={(e) => { e.stopPropagation(); setStage('play'); }}>
                  <span>▶ Play the game!</span>
                </button>
                <button className="say" style={{ marginTop: 4 }} onClick={(e) => { e.stopPropagation(); speak(card.fact, { rate: .9 }); }}>🔊</button>
              </div>
            </div>
          </div>
        )}

        {stage === 'play' && Engine && <Engine game={card.game} color={color} onWin={win} />}

        {stage === 'done' && (
          <div className="disco-win">
            <div className="starburst"><span>🌟</span><span>{card.sticker}</span><span>🌟</span></div>
            <h2>Card Collected!</h2>
            <p>You earned the {card.title} card and a {card.sticker} sticker!</p>
          </div>
        )}
      </div>
    </div>
  );
}

Object.assign(window, { DiscoveryDeck, DiscoveryCard });
