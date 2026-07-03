import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/world_content.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/save_controller.dart';
import '../../../domain/reward.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/flip_card.dart';
import '../../../widgets/reward_modal.dart';
import 'mini_games.dart';

// ---------------------------------------------------------------------------
// Discovery Deck screen
// ---------------------------------------------------------------------------

/// Grid of 3 discovery cards for a continent; each card can be flipped.
class DiscoveryDeckScreen extends ConsumerStatefulWidget {
  const DiscoveryDeckScreen({
    super.key,
    required this.continent,
    required this.cards,
    required this.onBack,
  });

  final Continent continent;
  final List<DiscoveryCard> cards;
  final VoidCallback onBack;

  @override
  ConsumerState<DiscoveryDeckScreen> createState() =>
      _DiscoveryDeckScreenState();
}

class _DiscoveryDeckScreenState extends ConsumerState<DiscoveryDeckScreen> {
  DiscoveryCard? _activeCard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(ttsServiceProvider)
          .speak('Discovery Cards! Tap a card to learn and play.');
    });
  }

  void _openCard(DiscoveryCard card) {
    setState(() => _activeCard = card);
    ref.read(ttsServiceProvider).speak('${card.title}. Tap the card!');
  }

  void _closeCard() {
    setState(() => _activeCard = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.continent;
    final discovery =
        ref.watch(saveControllerProvider).value?.world.discovery ?? {};
    final gotCount =
        widget.cards.where((card) => discovery[card.id] == true).length;

    if (_activeCard != null) {
      return _CardPlayScreen(
        card: _activeCard!,
        continent: c,
        onExit: _closeCard,
        onWin: () async {
          await _onCardWin(_activeCard!);
        },
      );
    }

    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        leading: IconButton(
          key: const Key('discovery-deck-back'),
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: widget.onBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🃏 ${c.name} Discovery Cards',
              style: WqTheme.headingStyle(20),
            ),
            const Text(
              'Collect them all — tap to learn & play!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: WqColors.softInk,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: c.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '🃏 $gotCount/${widget.cards.length}',
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              c.color2.withValues(alpha: 0.18),
              c.color.withValues(alpha: 0.12),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: widget.cards.map((card) {
              final collected = discovery[card.id] == true;
              return _DeckCard(
                key: Key('deck-card-${card.id}'),
                card: card,
                collected: collected,
                color: c.color,
                color2: c.color2,
                onTap: () => _openCard(card),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _onCardWin(DiscoveryCard card) async {
    // Mark collected
    await ref
        .read(saveControllerProvider.notifier)
        .collectDiscoveryCard(card.id);

    if (!mounted) return;

    // Apply silent reward (own celebration handled in _CardPlayScreen)
    await showRewardModal(
      context,
      ref,
      Reward(
        stars: 2,
        xp: 18,
        sticker: card.sticker,
        silent: true,
        progressKey: 'world',
      ),
    );

    if (mounted) {
      // Return to deck view
      setState(() => _activeCard = null);
    }
  }
}

// ---------------------------------------------------------------------------
// Deck card tile
// ---------------------------------------------------------------------------

class _DeckCard extends StatelessWidget {
  const _DeckCard({
    super.key,
    required this.card,
    required this.collected,
    required this.color,
    required this.color2,
    required this.onTap,
  });

  final DiscoveryCard card;
  final bool collected;
  final Color color;
  final Color color2;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.9), color2],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: collected
                ? Border.all(color: WqColors.yellow, width: 3)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(card.e, style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text(
                  card.title,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (collected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: WqColors.yellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      card.sticker,
                      style: const TextStyle(fontSize: 18),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single card play flow: flip → fact → play → done
// ---------------------------------------------------------------------------

enum _CardStage { front, back, play, done }

class _CardPlayScreen extends ConsumerStatefulWidget {
  const _CardPlayScreen({
    required this.card,
    required this.continent,
    required this.onExit,
    required this.onWin,
  });

  final DiscoveryCard card;
  final Continent continent;
  final VoidCallback onExit;
  final VoidCallback onWin;

  @override
  ConsumerState<_CardPlayScreen> createState() => _CardPlayScreenState();
}

class _CardPlayScreenState extends ConsumerState<_CardPlayScreen> {
  _CardStage _stage = _CardStage.front;
  bool _winFired = false;

  void _onFlipped() {
    setState(() => _stage = _CardStage.back);
    ref.read(ttsServiceProvider).speak(widget.card.fact);
  }

  void _startPlay() {
    setState(() => _stage = _CardStage.play);
  }

  void _onWin() {
    if (_winFired) return;
    _winFired = true;
    ref.read(ttsServiceProvider).speak('You did it! Card collected!');
    setState(() => _stage = _CardStage.done);
    Future.delayed(const Duration(milliseconds: 1500), widget.onWin);
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final c = widget.continent;

    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        leading: IconButton(
          key: const Key('card-play-back'),
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: widget.onExit,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(card.e, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              card.title,
              style: WqTheme.headingStyle(20),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                _stage == _CardStage.play ? 'Play the game!' : 'Discovery Card',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: WqColors.softInk,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              c.color2.withValues(alpha: 0.2),
              c.color.withValues(alpha: 0.12),
            ],
          ),
        ),
        child: _buildBody(card, c),
      ),
    );
  }

  Widget _buildBody(DiscoveryCard card, Continent c) {
    switch (_stage) {
      case _CardStage.front:
      case _CardStage.back:
        return Center(
          child: SizedBox(
            width: 320,
            height: 460,
            child: FlipCard(
              key: Key('discovery-flip-${card.id}'),
              onFlipped: _onFlipped,
              front: _CardFace(
                card: card,
                color: c.color,
                color2: c.color2,
                showTapHint: true,
              ),
              back: _CardBack(
                card: card,
                color: c.color,
                color2: c.color2,
                onPlay: _startPlay,
              ),
            ),
          ),
        );

      case _CardStage.play:
        return MiniGameWidget(
          key: Key('mini-game-${card.id}'),
          game: card.game,
          color: c.color,
          color2: c.color2,
          onWin: _onWin,
        );

      case _CardStage.done:
        return _WinCelebration(card: card, color: c.color);
    }
  }
}

// ---------------------------------------------------------------------------
// Card face widgets
// ---------------------------------------------------------------------------

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    required this.color,
    required this.color2,
    this.showTapHint = false,
  });

  final DiscoveryCard card;
  final Color color;
  final Color color2;
  final bool showTapHint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color2],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(card.e, style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            Text(
              card.title,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            if (showTapHint) ...[
              const SizedBox(height: 24),
              const Text(
                '👆 Tap to flip',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardBack extends ConsumerWidget {
  const _CardBack({
    required this.card,
    required this.color,
    required this.color2,
    required this.onPlay,
  });

  final DiscoveryCard card;
  final Color color;
  final Color color2;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WqColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💡', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text(
              card.fact,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                color: WqColors.ink,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                key: Key('card-play-btn-${card.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onPlay,
                child: const Text(
                  '▶ Play the game!',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () =>
                  ref.read(ttsServiceProvider).speak(card.fact),
              icon: const Text('🔊', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Hear again',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: WqColors.softInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Win celebration
// ---------------------------------------------------------------------------

class _WinCelebration extends StatelessWidget {
  const _WinCelebration({required this.card, required this.color});

  final DiscoveryCard card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌟', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Text(card.sticker, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 12),
              const Text('🌟', style: TextStyle(fontSize: 40)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Card Collected!',
            style: TextStyle(
              fontFamily: 'Baloo2',
              fontWeight: FontWeight.w700,
              fontSize: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You earned the ${card.title} card\nand a ${card.sticker} sticker!',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              color: WqColors.ink,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
