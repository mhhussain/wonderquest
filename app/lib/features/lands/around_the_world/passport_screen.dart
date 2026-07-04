import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/world_content.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/save_controller.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';

/// Explorer Passport overlay — 7 stamp slots, discovery points, wonder cards.
class PassportScreen extends ConsumerStatefulWidget {
  const PassportScreen({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends ConsumerState<PassportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(ttsServiceProvider).speak('Here is your explorer passport!');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final saveAsync = ref.watch(saveControllerProvider);
    final world = saveAsync.value?.world;
    final visited = world?.visited ?? {};
    final discovery = world?.discovery ?? {};

    // Wonder cards: continent IDs collected at mission completion.
    final wonderCards = world?.cards ?? <String>[];

    // Tally collected stamps
    final stampCount = visited.length;

    // Discovery points: 25 per stamp
    final discoveryPoints = stampCount * 25;

    // All discovery cards collected count
    final cardsCollected =
        discovery.values.where((v) => v == true).length;

    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: widget.onClose,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent close on inner tap
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 700,
                maxHeight: 720,
              ),
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: WqColors.card,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x44000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                      child: Row(
                        children: [
                          const Text('🛂',
                              style: TextStyle(fontSize: 34)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Explorer Passport',
                                style: WqTheme.headingStyle(22),
                              ),
                              const Text(
                                'Hassan • World Explorer',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  color: WqColors.softInk,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: WqColors.yellow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '🌟 $discoveryPoints pts',
                              style: const TextStyle(
                                fontFamily: 'Baloo2',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: WqColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            key: const Key('passport-close'),
                            icon: const Icon(Icons.close, color: WqColors.ink),
                            onPressed: widget.onClose,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: WqColors.lines),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Stamps section
                            Text(
                              '📍 Continent Stamps',
                              style: WqTheme.headingStyle(16),
                            ),
                            const SizedBox(height: 12),
                            _StampsGrid(visited: visited),
                            const SizedBox(height: 20),

                            // Discovery cards section
                            Row(
                              children: [
                                Text(
                                  '🃏 World Wonder Cards',
                                  style: WqTheme.headingStyle(16),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '— $cardsCollected/21 Discovery Cards',
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: WqColors.softInk,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _WonderCardsGrid(
                              wonders: kWorldWonders,
                              wonderCards: wonderCards,
                              ref: ref,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stamps grid
// ---------------------------------------------------------------------------

class _StampsGrid extends StatelessWidget {
  const _StampsGrid({required this.visited});

  final Map<String, bool> visited;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: kContinents.map((c) {
        final got = visited[c.id] == true;
        return SizedBox(
          width: 84,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: Key('stamp-${c.id}'),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: got
                      ? c.color.withValues(alpha: 0.15)
                      : WqColors.backgroundAlt,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: got ? c.color : WqColors.lines,
                    width: got ? 3 : 1.5,
                  ),
                  boxShadow: got
                      ? [
                          BoxShadow(
                            color: c.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    got ? c.badge : '❔',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                c.name,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: got ? FontWeight.w700 : FontWeight.w400,
                  color: got ? WqColors.ink : WqColors.softInk,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (got)
                const Text(
                  '✓',
                  style: TextStyle(
                    fontSize: 12,
                    color: WqColors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Wonder cards grid
// ---------------------------------------------------------------------------

class _WonderCardsGrid extends StatelessWidget {
  const _WonderCardsGrid({
    required this.wonders,
    required this.wonderCards,
    required this.ref,
  });

  final List<WorldWonder> wonders;

  /// Continent IDs whose wonder card has been collected (from world.cards).
  final List<String> wonderCards;

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: wonders.map((w) {
        // Key by continent id (match by continent emoji, not badge).
        final continentId = kContinents
            .firstWhere(
              (c) => c.emoji == w.e,
              orElse: () => kContinents.first,
            )
            .id;
        final got = wonderCards.contains(continentId);
        return GestureDetector(
          onTap: got ? () => ref.read(ttsServiceProvider).speak(w.t) : null,
          child: SizedBox(
            width: 80,
            child: Column(
              children: [
                Container(
                  key: Key('wonder-${w.e}'),
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: got
                        ? WqColors.yellow.withValues(alpha: 0.15)
                        : WqColors.backgroundAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: got ? WqColors.yellow : WqColors.lines,
                      width: got ? 2.5 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      got ? w.e : '🔒',
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  got ? w.t : 'Keep exploring!',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    color: got ? WqColors.ink : WqColors.softInk,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
