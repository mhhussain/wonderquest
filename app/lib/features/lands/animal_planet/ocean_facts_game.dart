import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/animals_content.dart';
import '../../../core/audio/tts_service.dart';
import '../../../domain/reward.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/reward_modal.dart';

/// Ocean Facts activity: tap 8 sea creatures to learn amazing facts.
///
/// Picks 8 from the 10-entry [kOceanFacts] pool each session. Tapping a card
/// speaks its fact and highlights it. When all 8 are found the player can
/// claim a reward.
class OceanFactsScreen extends ConsumerStatefulWidget {
  const OceanFactsScreen({super.key, this.random});

  /// Injected [Random] for deterministic tests.
  @visibleForTesting
  final Random? random;

  @override
  ConsumerState<OceanFactsScreen> createState() => _OceanFactsScreenState();
}

class _OceanFactsScreenState extends ConsumerState<OceanFactsScreen> {
  late final List<OceanFact> _cards;
  final Set<String> _found = {};
  OceanFact? _current;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    final rng = widget.random ?? Random();
    final shuffled = List<OceanFact>.from(kOceanFacts)..shuffle(rng);
    _cards = shuffled.take(8).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ref.read(ttsServiceProvider).speak(
            'Tap a sea creature to learn an amazing fact!',
            rate: 0.92,
          ),
        );
      }
    });
  }

  bool get _allFound => _found.length == _cards.length;

  void _onTap(OceanFact fact) {
    setState(() {
      _current = fact;
      _found.add(fact.n);
    });
    unawaited(
      ref.read(ttsServiceProvider).speak('${fact.n}. ${fact.f}', rate: 0.92),
    );
  }

  Future<void> _claimReward() async {
    if (_claiming) return;
    _claiming = true;
    await showRewardModal(
      context,
      ref,
      const Reward(
        stars: 3,
        xp: 26,
        egg: true,
        sticker: '🐙',
        progressKey: 'animal',
        progressTo: 70,
      ),
      onPlayAgain: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WqColors.sky.withValues(alpha: 0.08),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Ocean Facts 🫧', style: WqTheme.headingStyle(22)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '🐚 ${_found.length}/${_cards.length}',
                style: WqTheme.headingStyle(16)
                    .copyWith(color: WqColors.softInk),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Fact display panel ─────────────────────────────────────────
            _FactPanel(fact: _current),
            const SizedBox(height: 14),

            // ── Creature grid ──────────────────────────────────────────────
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: _cards.map((fact) {
                  final seen = _found.contains(fact.n);
                  return _CreatureCard(
                    key: Key('ocean-card-${fact.n}'),
                    fact: fact,
                    seen: seen,
                    onTap: () => _onTap(fact),
                  );
                }).toList(),
              ),
            ),

            // ── Completion button ──────────────────────────────────────────
            if (_allFound) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  key: const Key('ocean-claim-reward'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WqColors.sky,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
// Fact panel
// ---------------------------------------------------------------------------

class _FactPanel extends StatelessWidget {
  const _FactPanel({required this.fact});

  final OceanFact? fact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WqColors.sky.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WqColors.sky, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: fact == null
            ? Text(
                '👆 Tap a sea creature below to hear something amazing!',
                textAlign: TextAlign.center,
                style: WqTheme.headingStyle(15)
                    .copyWith(color: WqColors.softInk),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fact!.e,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fact!.n,
                          style: const TextStyle(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: WqColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fact!.f,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            color: WqColors.softInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Creature card
// ---------------------------------------------------------------------------

class _CreatureCard extends StatelessWidget {
  const _CreatureCard({
    super.key,
    required this.fact,
    required this.seen,
    required this.onTap,
  });

  final OceanFact fact;
  final bool seen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: seen
              ? WqColors.sky.withValues(alpha: 0.25)
              : WqColors.backgroundAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: seen ? WqColors.sky : WqColors.lines,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(fact.e, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 4),
            Text(
              fact.n,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: seen ? WqColors.sky : WqColors.softInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
