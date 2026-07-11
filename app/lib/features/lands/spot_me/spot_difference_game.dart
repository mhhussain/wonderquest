import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/spot_scenes_content.dart';
import '../../../core/audio/sfx_service.dart';
import '../../../domain/reward.dart';
import '../../../domain/spot_scene_engine.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/reward_modal.dart';
import 'spot_me_screen.dart';
import '../../../core/progress_keys.dart';

// ---------------------------------------------------------------------------
// Difference generator
// ---------------------------------------------------------------------------

/// Result of [generateDiff]: two scenes (A and B) where exactly one item in B
/// has a different [PlacedItem.char] compared to A.
class DiffResult {
  const DiffResult({
    required this.sceneA,
    required this.sceneB,
    required this.changedId,
  });

  /// The reference scene (shown read-only on the left).
  final List<PlacedItem> sceneA;

  /// The modified scene (shown on the right, player finds the difference).
  final List<PlacedItem> sceneB;

  /// [PlacedItem.id] of the item whose char was changed in [sceneB].
  final int changedId;
}

/// Generates a [DiffResult] from [base] by replacing one item's char with
/// [swapChar].
///
/// Guarantees exactly ONE item differs between [sceneA] and [sceneB].
DiffResult generateDiff({
  required List<PlacedItem> base,
  required String swapChar,
  required Random random,
}) {
  assert(base.isNotEmpty, 'base must be non-empty');

  final idx = random.nextInt(base.length);
  final original = base[idx];

  // Build scene B: same items, one char replaced.
  final sceneB = [
    for (var i = 0; i < base.length; i++)
      if (i == idx)
        PlacedItem(
          char: swapChar,
          pos: original.pos,
          size: original.size,
          isTarget: true, // the differing item is the find target
          id: original.id,
        )
      else
        base[i],
  ];

  return DiffResult(sceneA: base, sceneB: sceneB, changedId: original.id);
}

// ---------------------------------------------------------------------------
// Round spec
// ---------------------------------------------------------------------------

class _DiffRound {
  const _DiffRound({
    required this.sceneKey,
    required this.extraItems,
  });

  /// Key into [kSceneMap].
  final String sceneKey;

  /// Additional emoji that can be swapped in as the "changed" item.
  final List<String> extraItems;
}

const _kDiffRounds = [
  _DiffRound(
    sceneKey: 'beach',
    extraItems: ['🐠', '⛵', '🐬'],
  ),
  _DiffRound(
    sceneKey: 'playground',
    extraItems: ['🐦', '🪁', '🐕'],
  ),
  _DiffRound(
    sceneKey: 'museum',
    extraItems: ['🦖', '🦴', '🥚'],
  ),
];

// ---------------------------------------------------------------------------
// SpotDifferenceScreen
// ---------------------------------------------------------------------------

/// Spot the Difference: two side-by-side scenes; one item in panel B has a
/// different emoji — the player taps it.
///
/// Runs through [_kDiffRounds] in sequence.  On the last round, the reward
/// modal is shown and the screen pops.
class SpotDifferenceScreen extends ConsumerStatefulWidget {
  const SpotDifferenceScreen({super.key});

  @override
  ConsumerState<SpotDifferenceScreen> createState() =>
      _SpotDifferenceScreenState();
}

class _SpotDifferenceScreenState extends ConsumerState<SpotDifferenceScreen> {
  int _roundIndex = 0;
  DiffResult? _diff;
  bool _found = false;

  @override
  void initState() {
    super.initState();
    // Items are placed after the first layout.
  }

  void _buildDiff(Size canvas) {
    final round = _kDiffRounds[_roundIndex];
    final scene = kSceneMap[round.sceneKey]!;
    final rng = Random();

    // Build a base scene using the ambient deco as both goals and decoys.
    final goals = [
      SpotGoal(char: scene.deco[0], count: 3, label: 'objects'),
    ];
    final decoys = scene.deco.skip(1).toList();

    final base = SpotSceneLayout.place(
      goals: goals,
      decoys: decoys,
      decoyCount: 18,
      canvas: canvas,
      random: rng,
    );

    // Use a random extra item as the swap character.
    final swapChar =
        round.extraItems[rng.nextInt(round.extraItems.length)];

    setState(() {
      _diff = generateDiff(base: base, swapChar: swapChar, random: rng);
      _found = false;
    });
  }

  Future<void> _onTapItem(PlacedItem item) async {
    if (_found) return;
    final sfx = ref.read(sfxServiceProvider);

    if (_diff == null) return;

    if (item.id == _diff!.changedId && item.isTarget) {
      // Correct tap!
      await sfx.play(Sfx.ding);
      setState(() {
        _found = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      await _advance();
    } else {
      // Wrong tap.
      await sfx.play(Sfx.wrong);
    }
  }

  Future<void> _advance() async {
    if (_roundIndex + 1 < _kDiffRounds.length) {
      setState(() {
        _roundIndex++;
        _diff = null;
        _found = false;
      });
      return;
    }

    // All rounds done.
    final count = ref
        .read(spotMeSessionCountProvider.notifier)
        .increment();
    final title = detectiveTitleForCount(count);

    if (!mounted) return;

    await showRewardModal(
      context,
      ref,
      Reward(
        stars: 3,
        xp: 30,
        egg: true,
        sticker: title ?? '🆚',
        progressKey: ProgressKeys.find,
        progressTo: 60,
      ),
      onPlayAgain: () {
        if (mounted) {
          setState(() {
            _roundIndex = 0;
            _diff = null;
            _found = false;
          });
        }
      },
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final round = _kDiffRounds[_roundIndex];
    final scene = kSceneMap[round.sceneKey]!;

    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '🆚 Spot the Difference '
          '(${_roundIndex + 1}/${_kDiffRounds.length})',
          style: WqTheme.headingStyle(20),
        ),
      ),
      body: Column(
        children: [
          // Instruction.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _found
                  ? 'Great eyes! You found it!'
                  : 'Tap the item in panel B that looks different!',
              textAlign: TextAlign.center,
              style: WqTheme.headingStyle(16)
                  .copyWith(color: WqColors.teal),
            ),
          ),

          // Side-by-side panels.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Panel A — reference (read-only).
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(
                          constraints.maxWidth.isFinite
                              ? constraints.maxWidth
                              : 400,
                          constraints.maxHeight.isFinite
                              ? constraints.maxHeight
                              : 600,
                        );

                        if (_diff == null) {
                          // Build the diff on first layout.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _diff == null) _buildDiff(size);
                          });
                          return _PanelPlaceholder(bg: scene.bg, label: 'A');
                        }

                        return _ScenePanel(
                          key: ValueKey('panel-a-$_roundIndex'),
                          label: 'A',
                          items: _diff!.sceneA,
                          bg: scene.bg,
                          interactive: false,
                          changedId: -1, // no highlighting in A
                          found: false,
                          onTap: (_) {},
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Panel B — modified (tappable).
                  Expanded(
                    child: _diff == null
                        ? _PanelPlaceholder(bg: scene.bg, label: 'B')
                        : _ScenePanel(
                            key: ValueKey('panel-b-$_roundIndex'),
                            label: 'B',
                            items: _diff!.sceneB,
                            bg: scene.bg,
                            interactive: !_found,
                            changedId: _diff!.changedId,
                            found: _found,
                            onTap: _onTapItem,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scene panel
// ---------------------------------------------------------------------------

/// A single panel in the Spot the Difference view.
///
/// [interactive] = false makes the panel read-only (panel A).  When [found]
/// is true, the changed item in panel B shows a highlight ring.
class _ScenePanel extends StatelessWidget {
  const _ScenePanel({
    super.key,
    required this.label,
    required this.items,
    required this.bg,
    required this.interactive,
    required this.changedId,
    required this.found,
    required this.onTap,
  });

  final String label;
  final List<PlacedItem> items;
  final Color bg;
  final bool interactive;
  final int changedId;
  final bool found;
  final void Function(PlacedItem) onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: interactive ? WqColors.teal : WqColors.lines,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Panel label.
            Positioned(
              top: 6,
              left: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: interactive ? WqColors.teal : WqColors.softInk,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Items.
            for (final item in items) _buildItem(item),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(PlacedItem item) {
    final isChanged = item.id == changedId && item.isTarget;
    final hitSize = item.size.clamp(64.0, double.infinity);

    Widget glyph = Text(
      item.char,
      style: TextStyle(fontSize: item.size * 0.8),
    );

    if (isChanged && found) {
      // Highlight ring on the found item.
      glyph = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          glyph,
          IgnorePointer(
            child: Container(
              width: item.size + 12,
              height: item.size + 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: WqColors.green, width: 3),
              ),
            ),
          ),
        ],
      );
    }

    return Positioned(
      left: item.pos.dx - hitSize / 2,
      top: item.pos.dy - hitSize / 2,
      child: GestureDetector(
        key: ValueKey('diff-item-${item.id}'),
        behavior: HitTestBehavior.opaque,
        onTapUp: interactive ? (_) => onTap(item) : null,
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(child: glyph),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder while the diff is being generated.
// ---------------------------------------------------------------------------

class _PanelPlaceholder extends StatelessWidget {
  const _PanelPlaceholder({required this.bg, required this.label});

  final Color bg;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WqColors.lines, width: 2),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: WqColors.softInk,
          ),
        ),
      ),
    );
  }
}
