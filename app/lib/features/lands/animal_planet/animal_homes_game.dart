import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/animals_content.dart';
import '../../../core/audio/sfx_service.dart';
import '../../../core/audio/tts_service.dart';
import '../../../domain/reward.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/reward_modal.dart';
import '../../../core/progress_keys.dart';

/// Habitat drag-and-drop game.
///
/// Picks 6 animals (1–2 per habitat) and renders them as draggable chips in a
/// tray. The player drags each chip to the matching habitat zone. Correct drops
/// speak the animal's fact; wrong drops play a wrong-sfx and say "Try another
/// home!" via TTS.
class AnimalHomesScreen extends ConsumerStatefulWidget {
  const AnimalHomesScreen({super.key, this.random});

  /// Injected [Random] for deterministic tests.
  @visibleForTesting
  final Random? random;

  @override
  ConsumerState<AnimalHomesScreen> createState() => _AnimalHomesScreenState();
}

class _AnimalHomesScreenState extends ConsumerState<AnimalHomesScreen> {
  late final List<Animal> _animals;

  /// animalName → habitatId (only contains correctly placed animals)
  final Map<String, String> _placed = {};

  bool _completing = false;

  /// Tracks which habitat zone is currently being hovered over during a drag.
  /// Used to distinguish wrong-zone drops from empty-space drops.
  late final ValueNotifier<String?> _hoveredZoneId =
      ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _animals = _pickAnimals(widget.random ?? Random());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ref
              .read(ttsServiceProvider)
              .speak('Drag each animal to its home!', rate: 0.92),
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Static helpers
  // ---------------------------------------------------------------------------

  /// Picks 6 animals: 1 from each habitat first, then a 2nd from each until
  /// the list reaches 6. Mirrors the prototype's selection logic.
  static List<Animal> _pickAnimals(Random rng) {
    final byHab = kHabitats.map((h) {
      final list = kAnimals.where((a) => a.habitat == h.id).toList()
        ..shuffle(rng);
      return list;
    }).toList();

    final pick = <Animal>[];
    for (final list in byHab) {
      if (list.isNotEmpty) pick.add(list[0]);
    }
    for (final list in byHab) {
      if (pick.length < 6 && list.length > 1) pick.add(list[1]);
    }
    pick.shuffle(rng);
    return pick;
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  Future<void> _onCorrectDrop(Animal animal) async {
    if (_placed.containsKey(animal.name)) return;
    setState(() => _placed[animal.name] = animal.habitat);
    unawaited(ref.read(sfxServiceProvider).play(Sfx.ding));
    unawaited(
      ref.read(ttsServiceProvider).speak(animal.fact, rate: 0.92),
    );

    if (_placed.length == _animals.length && !_completing) {
      _completing = true;
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      await showRewardModal(
        context,
        ref,
        const Reward(
          stars: 3,
          xp: 30,
          sticker: '🌍',
          progressKey: ProgressKeys.animal,
          progressTo: 70,
        ),
        onPlayAgain: () {
          if (mounted) Navigator.of(context).pop();
        },
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  /// Called when a draggable is released without being accepted.
  /// Only plays wrong-feedback if dropped over a different habitat zone;
  /// silent if dropped on empty space.
  void _onWrongDrop(Animal animal) {
    final hoveredZone = _hoveredZoneId.value;
    // Only play wrong feedback if dropped over a zone that's NOT the animal's home
    if (hoveredZone != null && hoveredZone != animal.habitat) {
      unawaited(ref.read(sfxServiceProvider).play(Sfx.wrong));
      unawaited(
        ref.read(ttsServiceProvider).speak('Try another home!', rate: 0.95),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
        title: Text('Animal Homes 🏡', style: WqTheme.headingStyle(22)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_placed.length}/${_animals.length} home',
                style:
                    WqTheme.headingStyle(16).copyWith(color: WqColors.softInk),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Habitat zones ─────────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: kHabitats.map((h) {
                  final here = _animals
                      .where((a) => _placed[a.name] == h.id)
                      .toList();
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: DragTarget<Animal>(
                        key: Key('zone-${h.id}'),
                        // Only accept animals that belong to this habitat.
                        onWillAcceptWithDetails: (d) {
                          // Track that we're hovering over this zone (tentatively)
                          _hoveredZoneId.value = h.id;
                          return d.data.habitat == h.id;
                        },
                        onAcceptWithDetails: (d) {
                          _hoveredZoneId.value = null;
                          unawaited(_onCorrectDrop(d.data));
                        },
                        builder: (ctx, candidateData, rejectedData) {
                          final isOver = candidateData.isNotEmpty;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isOver
                                  ? h.color.withValues(alpha: 0.65)
                                  : h.color.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isOver ? h.color : WqColors.lines,
                                width: isOver ? 3 : 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Placed animals
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      runAlignment: WrapAlignment.center,
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: here
                                          .map(
                                            (a) => Text(
                                              a.emoji,
                                              style: const TextStyle(
                                                  fontSize: 32),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                                // Habitat label
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    children: [
                                      Text(
                                        h.emoji,
                                        style:
                                            const TextStyle(fontSize: 28),
                                      ),
                                      Text(
                                        h.name,
                                        style: const TextStyle(
                                          fontFamily: 'Baloo2',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: WqColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Prompt ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Pick up an animal and drag it to where it lives!',
              textAlign: TextAlign.center,
              style: WqTheme.headingStyle(15).copyWith(
                color: WqColors.softInk,
              ),
            ),
          ),

          // ── Animal chip tray ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _animals.map((a) {
                if (_placed.containsKey(a.name)) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(width: 72, height: 72),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Draggable<Animal>(
                    data: a,
                    // Fire wrong-feedback only if dropped on a different habitat zone;
                    // empty-space drops return silently and let the Draggable animation
                    // restore the chip.
                    onDraggableCanceled: (velocity, offset) {
                      _onWrongDrop(a);
                      // Reset hovered zone after drop is processed
                      _hoveredZoneId.value = null;
                    },
                    feedback: Material(
                      color: Colors.transparent,
                      child: Text(
                        a.emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _Chip(animal: a),
                    ),
                    child: _Chip(key: Key('chip-${a.name}'), animal: a),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private chip widget
// ---------------------------------------------------------------------------

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: WqColors.backgroundAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WqColors.lines, width: 2),
      ),
      child: Center(
        child: Text(animal.emoji, style: const TextStyle(fontSize: 34)),
      ),
    );
  }
}
