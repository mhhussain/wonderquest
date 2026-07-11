import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/animals_content.dart';
import '../../../core/audio/sfx_service.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/save_controller.dart';
import '../../../domain/reward.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/flip_card.dart';
import '../../../widgets/reward_modal.dart';
import '../../../core/progress_keys.dart';

/// Fun animal facts: a grid of flip cards that reveal facts on tap.
///
/// Flipping a card (front → back) speaks the fact and silently adds the animal
/// to [SaveData.animalsFound] exactly once via [Reward.animal]. When all 6
/// cards are flipped the player can claim a completion reward.
class FunFactsScreen extends ConsumerStatefulWidget {
  const FunFactsScreen({super.key, this.random});

  /// Injected [Random] for deterministic tests.
  @visibleForTesting
  final Random? random;

  @override
  ConsumerState<FunFactsScreen> createState() => _FunFactsScreenState();
}

class _FunFactsScreenState extends ConsumerState<FunFactsScreen> {
  late final List<Animal> _cards;

  /// Indices of cards that have been flipped at least once.
  final Set<int> _flipped = {};

  @override
  void initState() {
    super.initState();
    final rng = widget.random ?? Random();
    final shuffled = List<Animal>.from(kAnimals)..shuffle(rng);
    _cards = shuffled.take(6).toList();
  }

  bool get _allFlipped => _flipped.length == _cards.length;

  void _onFlipped(int index) {
    if (_flipped.contains(index)) return;
    setState(() => _flipped.add(index));

    final a = _cards[index];
    unawaited(
      ref
          .read(ttsServiceProvider)
          .speak('${a.name}. ${a.fact}', rate: 0.92),
    );
    // Silent reward: adds to collection book without showing modal.
    unawaited(
      ref
          .read(saveControllerProvider.notifier)
          .apply(Reward(animal: a.name, silent: true)),
    );
  }

  Future<void> _claimReward() async {
    unawaited(ref.read(sfxServiceProvider).play(Sfx.fanfare));
    await showRewardModal(
      context,
      ref,
      const Reward(
        stars: 3,
        xp: 24,
        egg: true,
        progressKey: ProgressKeys.animal,
        progressTo: 60,
      ),
      onPlayAgain: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _showCollectionBook() {
    final saveAsync = ref.read(saveControllerProvider);
    final found = saveAsync.value?.animalsFound ?? const <String>[];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WqColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Animal Collection Book 📚',
          style: TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: WqColors.ink,
          ),
        ),
        content: found.isEmpty
            ? const Text(
                'Flip some cards to discover animals!',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  color: WqColors.softInk,
                ),
              )
            : Wrap(
                spacing: 12,
                runSpacing: 8,
                children: found
                    .map(
                      (name) => Chip(
                        label: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        backgroundColor: WqColors.grape.withValues(alpha: 0.15),
                      ),
                    )
                    .toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Fun Animal Facts 💡', style: WqTheme.headingStyle(22)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(
                '${_flipped.length}/${_cards.length} found',
                style: WqTheme.headingStyle(15)
                    .copyWith(color: WqColors.softInk),
              ),
            ),
          ),
          IconButton(
            key: const Key('collection-book-btn'),
            icon: const Icon(Icons.auto_stories, color: WqColors.grape),
            tooltip: 'Collection Book',
            onPressed: _showCollectionBook,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.05,
                children: List.generate(_cards.length, (i) {
                  final a = _cards[i];
                  return FlipCard(
                    key: Key('flip-card-$i'),
                    onFlipped: () => _onFlipped(i),
                    front: _CardFace(
                      animal: a,
                      isBack: false,
                    ),
                    back: _CardFace(
                      animal: a,
                      isBack: true,
                    ),
                  );
                }),
              ),
            ),
            if (_allFlipped) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  key: const Key('facts-claim-reward'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WqColors.grape,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _claimReward,
                  child: const Text(
                    'I learned them all! ⭐',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card face widget (shared by front and back)
// ---------------------------------------------------------------------------

class _CardFace extends StatelessWidget {
  const _CardFace({required this.animal, required this.isBack});

  final Animal animal;
  final bool isBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isBack
            ? WqColors.grape.withValues(alpha: 0.12)
            : WqColors.backgroundAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBack ? WqColors.grape : WqColors.lines,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(animal.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 6),
            Text(
              animal.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isBack ? WqColors.grape : WqColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isBack ? animal.fact : '👆 Tap for a fun fact',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: isBack ? 12 : 13,
                color: WqColors.softInk,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
