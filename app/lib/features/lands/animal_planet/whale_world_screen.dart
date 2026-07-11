import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/animals_content.dart';
import '../../../core/audio/sfx_service.dart';
import '../../../core/audio/tts_service.dart';
import '../../../domain/reward.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/reward_modal.dart';

// ---------------------------------------------------------------------------
// Whale call SFX helper
// ---------------------------------------------------------------------------

/// Playback rate pitching the 80 Hz whale-call asset to [whale]'s base
/// frequency, so every whale has a distinct voice (Blue 54 Hz → 0.675,
/// Beluga 150 Hz → 1.875, …). Clamped to the platform-safe 0.5–2.0 range.
double whaleCallRate(Whale whale) => SfxService.whaleCallRate(whale.baseFreq);

/// Fraction of maximum dive depth (2000 m) for [whale].
///
/// Clamped to [0.0, 1.0]. Used for the dive-depth meter height.
double diveFraction(Whale whale, {int maxDepth = 2000}) =>
    (whale.diveM / maxDepth).clamp(0.0, 1.0);

// ---------------------------------------------------------------------------
// WhaleWorldScreen
// ---------------------------------------------------------------------------

/// Whale World gallery: 6 whale types with facts, dive-depth meter, and call.
///
/// Each whale can be selected from the left-hand list. The right-hand detail
/// panel shows the emoji/name, fact, two action buttons ("Hear its call" and
/// "Read fact"), and a vertical dive-depth meter. When all 6 whales have been
/// heard (or read), a completion reward is available.
class WhaleWorldScreen extends ConsumerStatefulWidget {
  const WhaleWorldScreen({super.key});

  @override
  ConsumerState<WhaleWorldScreen> createState() => _WhaleWorldScreenState();
}

class _WhaleWorldScreenState extends ConsumerState<WhaleWorldScreen> {
  int _selIndex = 0;
  final Set<int> _heard = {};
  bool _claiming = false;

  Whale get _sel => kWhales[_selIndex];

  bool get _allHeard => _heard.length == kWhales.length;

  @override
  void initState() {
    super.initState();
    // Mark the first whale as visited and speak its name.
    _heard.add(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ref
              .read(ttsServiceProvider)
              .speak(
                'Welcome to Whale World! Tap a whale to meet it.',
                rate: 0.92,
              ),
        );
      }
    });
  }

  void _selectWhale(int index) {
    setState(() {
      _selIndex = index;
      _heard.add(index);
    });
    unawaited(
      ref.read(ttsServiceProvider).speak(_sel.n, rate: 0.9),
    );
  }

  Future<void> _hearCall() async {
    final whale = _sel;
    unawaited(
      ref
          .read(ttsServiceProvider)
          .speak('${whale.n} says…', rate: 0.9),
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    unawaited(ref.read(sfxServiceProvider).playWhaleCall(whale.baseFreq));
  }

  void _readFact() {
    final whale = _sel;
    unawaited(
      ref.read(ttsServiceProvider).speak('${whale.n}. ${whale.f}', rate: 0.9),
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
        xp: 28,
        egg: true,
        sticker: '🐋',
        progressKey: 'animal',
        progressTo: 75,
      ),
      onPlayAgain: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
    if (mounted) Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // deep sea background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '🐋 Whale World',
          style: WqTheme.headingStyle(22).copyWith(color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: WqColors.sky.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🐋 ${_heard.length}/${kWhales.length}',
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Whale list (left) ──────────────────────────────────
                  SizedBox(
                    width: 220,
                    child: ListView.separated(
                      itemCount: kWhales.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final w = kWhales[i];
                        final isSel = i == _selIndex;
                        return GestureDetector(
                          key: Key('whale-pick-$i'),
                          onTap: () => _selectWhale(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? w.color
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSel
                                    ? w.color
                                    : Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(w.e,
                                    style: const TextStyle(fontSize: 26)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    w.n,
                                    style: TextStyle(
                                      fontFamily: 'Baloo2',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isSel
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ── Whale detail (right) ───────────────────────────────
                  Expanded(
                    child: _WhaleDetail(
                      whale: _sel,
                      onHearCall: _hearCall,
                      onReadFact: _readFact,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Completion button ──────────────────────────────────────────
          if (_allHeard)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                height: 64,
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('whale-claim-reward'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WqColors.sky,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _claimReward,
                  child: const Text(
                    'I met all the whales! ⭐',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Whale detail panel
// ---------------------------------------------------------------------------

class _WhaleDetail extends StatelessWidget {
  const _WhaleDetail({
    required this.whale,
    required this.onHearCall,
    required this.onReadFact,
  });

  final Whale whale;
  final VoidCallback onHearCall;
  final VoidCallback onReadFact;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: emoji + name ──────────────────────────────────────
          Row(
            children: [
              Text(whale.e, style: const TextStyle(fontSize: 64)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  whale.n,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Fact ─────────────────────────────────────────────────────
          Text(
            whale.f,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // ── Action buttons ────────────────────────────────────────────
          Row(
            children: [
              ElevatedButton.icon(
                key: Key('hear-call-${whale.n.replaceAll(' ', '-')}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: whale.color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(64, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onHearCall,
                icon: const Text('🔊', style: TextStyle(fontSize: 18)),
                label: const Text(
                  'Hear its call',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                key: Key('read-fact-${whale.n.replaceAll(' ', '-')}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white30),
                  minimumSize: const Size(64, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onReadFact,
                icon: const Text('📖', style: TextStyle(fontSize: 18)),
                label: const Text(
                  'Read fact',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Dive depth meter ──────────────────────────────────────────
          _DiveMeter(whale: whale),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dive depth meter
// ---------------------------------------------------------------------------

/// Vertical bar representing [whale.diveM] as a fraction of 2000 m.
///
/// The fill height is `diveM / 2000 * totalHeight` — proportional to depth.
/// Use the key `dive-fill-<whale-name-hyphenated>` to find the fill bar in
/// widget tests.
class _DiveMeter extends StatelessWidget {
  const _DiveMeter({required this.whale});

  final Whale whale;

  @override
  Widget build(BuildContext context) {
    final fraction = diveFraction(whale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🌊 How deep does it dive?',
          style: TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Vertical meter bar
            Container(
              key: Key('dive-meter-${whale.n.replaceAll(' ', '-')}'),
              width: 48,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: fraction,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    key: Key(
                      'dive-fill-${whale.n.replaceAll(' ', '-')}',
                    ),
                    decoration: BoxDecoration(
                      color: whale.color,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          whale.e,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${whale.diveM} m deep',
                  style: TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: whale.color,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '🪨 sea floor',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
