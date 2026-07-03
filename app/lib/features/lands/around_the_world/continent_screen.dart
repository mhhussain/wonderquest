import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/world_content.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/save_controller.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';

/// Continent page — themed colors, rotating world-fact ribbon, 6-animal grid.
///
/// Shows the continent's animals (tap → fact spoken), a fact ribbon that
/// rotates every 6 seconds, and buttons for Find mission + Discovery Cards.
///
/// [visitContinent] is called on first arrival.
class ContinentScreen extends ConsumerStatefulWidget {
  const ContinentScreen({
    super.key,
    required this.continent,
    required this.onMission,
    required this.onCards,
    required this.onBack,
    this.firstVisit = false,
  });

  final Continent continent;
  final VoidCallback onMission;
  final VoidCallback onCards;
  final VoidCallback onBack;
  final bool firstVisit;

  @override
  ConsumerState<ContinentScreen> createState() => _ContinentScreenState();
}

class _ContinentScreenState extends ConsumerState<ContinentScreen> {
  final Set<String> _seenAnimals = {};
  String? _currentAnimalName;
  String? _currentAnimalFact;
  String? _currentAnimalEmoji;
  int _factIndex = 0;
  Timer? _factTimer;

  List<String> get _facts {
    // Pull 3 facts for this continent from kWorldFacts
    final id = widget.continent.id;
    final kOrder = [
      'africa',
      'asia',
      'australia',
      'antarctica',
      'namerica',
      'samerica',
      'europe',
    ];
    final idx = kOrder.indexOf(id);
    if (idx < 0) return kWorldFacts.take(3).toList();
    final start = idx * 3;
    return kWorldFacts.skip(start).take(3).toList();
  }

  @override
  void initState() {
    super.initState();

    // Greet & optionally mark first visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = widget.continent;
      ref
          .read(ttsServiceProvider)
          .speak('${c.theme}! Tap the animals to learn about them.');

      if (widget.firstVisit) {
        ref.read(saveControllerProvider.notifier).visitContinent(c.id);
      }
    });

    // Start auto-rotating fact ribbon every 6 s
    _factTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) {
        setState(() => _factIndex = (_factIndex + 1) % _facts.length);
      }
    });
  }

  @override
  void dispose() {
    _factTimer?.cancel();
    super.dispose();
  }

  void _tapAnimal(Map<String, String> animal) {
    final name = animal['name']!;
    final fact = animal['fact']!;
    final emoji = animal['emoji']!;
    setState(() {
      _currentAnimalName = name;
      _currentAnimalFact = fact;
      _currentAnimalEmoji = emoji;
      _seenAnimals.add(name);
    });
    ref.read(ttsServiceProvider).speak('$name. $fact');
  }

  void _nextFact() {
    final next = (_factIndex + 1) % _facts.length;
    setState(() => _factIndex = next);
    ref.read(ttsServiceProvider).speak(_facts[next]);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.continent;
    final animals = c.animals
        .map((a) => {'emoji': a.emoji, 'name': a.name, 'fact': a.fact})
        .toList();

    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        leading: IconButton(
          key: const Key('continent-back'),
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: widget.onBack,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(c.name, style: WqTheme.headingStyle(22)),
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
                '🦁 ${_seenAnimals.length}/${animals.length}',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Continent theme subtitle
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  c.theme,
                  style:
                      WqTheme.headingStyle(16).copyWith(color: c.color),
                  textAlign: TextAlign.center,
                ),
              ),

              // Fun fact ribbon
              _FactRibbon(
                fact: _facts[_factIndex],
                color: c.color,
                onTap: _nextFact,
              ),
              const SizedBox(height: 16),

              // Animal grid (2 rows × 3 cols)
              _AnimalGrid(
                animals: animals,
                seenAnimals: _seenAnimals,
                continentColor: c.color,
                onTap: _tapAnimal,
              ),
              const SizedBox(height: 12),

              // Current animal fact bubble
              _AnimalFactBubble(
                emoji: _currentAnimalEmoji,
                name: _currentAnimalName,
                fact: _currentAnimalFact,
                color: c.color,
              ),
              const SizedBox(height: 20),

              // Action buttons
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  key: Key('find-mission-btn-${c.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.color,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: widget.onMission,
                  child: Text(
                    '🔍 Find the ${c.mission.count} ${c.mission.n}!',
                    style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 64,
                child: OutlinedButton(
                  key: Key('discovery-cards-btn-${c.id}'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.color, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: widget.onCards,
                  child: Text(
                    '🃏 Discovery Cards',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: c.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fact ribbon
// ---------------------------------------------------------------------------

class _FactRibbon extends StatelessWidget {
  const _FactRibbon({
    required this.fact,
    required this.color,
    required this.onTap,
  });

  final String fact;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        key: ValueKey(fact),
        duration: const Duration(milliseconds: 400),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fact,
                style: WqTheme.headingStyle(14).copyWith(
                  color: WqColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Text('🔊', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animal grid
// ---------------------------------------------------------------------------

class _AnimalGrid extends StatelessWidget {
  const _AnimalGrid({
    required this.animals,
    required this.seenAnimals,
    required this.continentColor,
    required this.onTap,
  });

  final List<Map<String, String>> animals;
  final Set<String> seenAnimals;
  final Color continentColor;
  final ValueChanged<Map<String, String>> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: animals
          .map(
            (a) => _AnimalCard(
              animal: a,
              seen: seenAnimals.contains(a['name']),
              color: continentColor,
              onTap: () => onTap(a),
            ),
          )
          .toList(),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({
    required this.animal,
    required this.seen,
    required this.color,
    required this.onTap,
  });

  final Map<String, String> animal;
  final bool seen;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: seen ? color.withValues(alpha: 0.18) : WqColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seen ? color : WqColors.lines,
            width: seen ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              animal['emoji']!,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              animal['name']!,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: WqColors.ink,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animal fact bubble
// ---------------------------------------------------------------------------

class _AnimalFactBubble extends StatelessWidget {
  const _AnimalFactBubble({
    required this.emoji,
    required this.name,
    required this.fact,
    required this.color,
  });

  final String? emoji;
  final String? name;
  final String? fact;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasContent = name != null && fact != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasContent ? color.withValues(alpha: 0.1) : WqColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasContent ? color.withValues(alpha: 0.3) : WqColors.lines,
        ),
      ),
      child: hasContent
          ? Row(
              children: [
                Text(emoji!, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name!,
                        style: WqTheme.headingStyle(14).copyWith(color: color),
                      ),
                      Text(
                        fact!,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: WqColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Text(
              '👆 Tap an animal to hear a fun fact!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: WqColors.softInk,
              ),
              textAlign: TextAlign.center,
            ),
    );
  }
}
