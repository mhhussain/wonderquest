import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/lands.dart';
import '../../core/art.dart';
import '../../core/save_controller.dart';
import '../../theme/wq_colors.dart';
import '../../theme/wq_theme.dart';
import '../../widgets/hud.dart';
import '../../widgets/wq_button.dart';

/// Home screen — the Expedition Map.
///
/// Displays [Hud] on top, a 4-column scrollable grid of the 13 [Land] cards,
/// a Rexy mascot tip bubble, and a "My Stuff" button that opens the
/// [_CollectionsModal].
///
/// Tapping a playable card navigates to its [Land.builder] route (or a
/// placeholder while Tasks 27–33 are not yet shipped).  Tapping a locked card
/// is a no-op.
class ExpeditionMapScreen extends ConsumerWidget {
  const ExpeditionMapScreen({super.key});

  // ── Rexy encouragement tips (cycle by streak) ─────────────────────────────

  static const _tips = [
    "Let's learn lowercase letters today! Tap Letter Adventure.",
    'I found a dino egg! Finish an adventure to hatch it!',
    'Ready to explore? Pick any land on the map!',
  ];

  // ── Placeholder used until individual land tasks ship builders ─────────────

  static Widget _placeholderBuilder(BuildContext context) {
    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Art.glyph(Art.mascot, size: 72),
            const SizedBox(height: 16),
            Text(
              'Coming in a later task',
              style: WqTheme.headingStyle(28),
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigation helpers ─────────────────────────────────────────────────────

  void _openLand(BuildContext context, Land land) {
    final builder = land.builder ?? _placeholderBuilder;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: builder),
    );
  }

  void _openCollections(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _CollectionsModal(),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveControllerProvider).value;
    final progress = save?.progress ?? const <String, int>{};
    final streak = save?.streak ?? 0;
    final tip = _tips[streak % _tips.length];

    return Scaffold(
      backgroundColor: WqColors.background,
      body: Column(
        children: [
          // ── HUD ─────────────────────────────────────────────────────────────
          Hud(onParentTap: () {}),

          // ── Land grid ───────────────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              key: const Key('land-grid'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemCount: kLands.length,
              itemBuilder: (context, index) {
                final land = kLands[index];
                final landProgress = land.progressKey != null
                    ? (progress[land.progressKey] ?? 0)
                    : 0;
                return _LandCard(
                  key: Key('land-card-${land.id}'),
                  land: land,
                  progress: landProgress,
                  onTap: land.playable
                      ? () => _openLand(context, land)
                      : null,
                );
              },
            ),
          ),

          // ── Bottom bar: Rexy tip + My Stuff button ──────────────────────────
          _BottomBar(
            tip: tip,
            onMyStuff: () => _openCollections(context),
          ),
        ],
      ),
    );
  }
}

// ── Land card ──────────────────────────────────────────────────────────────────

/// Single tile in the Expedition Map grid.
///
/// Playable: shows emoji, title, sub tagline, "▶ Play" pill, and a progress
/// bar. Locked: same content but with a "🔒 Soon" pill, a semi-transparent
/// overlay, and a central lock glyph. Hit target is the entire card (≥ 64 px).
class _LandCard extends StatelessWidget {
  const _LandCard({
    super.key,
    required this.land,
    required this.progress,
    this.onTap,
  });

  final Land land;

  /// Value in `[0, 100]` from [SaveData.progress].
  final int progress;

  /// `null` when the land is locked (card tap is a no-op).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: land.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // ── Card body ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pill (▶ Play / 🔒 Soon)
                    _Pill(
                      label: land.playable ? ' Play' : ' Soon',
                      emojiKey: land.playable ? 'play' : 'lock',
                      playable: land.playable,
                    ),
                    const SizedBox(height: 6),
                    // Emoji
                    Art.glyph(land.emojiKey, size: 38),
                    const SizedBox(height: 2),
                    // Title
                    Text(
                      land.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    // Sub tagline
                    Text(
                      land.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    // Progress bar (playable lands only)
                    if (land.playable) ...[
                      const SizedBox(height: 4),
                      _ProgressBar(fraction: progress / 100.0),
                    ],
                  ],
                ),
              ),

              // ── Locked overlay ────────────────────────────────────────────
              if (!land.playable)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Art.glyph('lock', size: 40),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "▶ Play" or "🔒 Soon" pill badge in the card corner.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.emojiKey,
    required this.playable,
  });

  final String label;
  final String emojiKey;
  final bool playable;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: playable
            ? Colors.white.withValues(alpha: 0.30)
            : Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Art.emoji(emojiKey),
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: playable ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin horizontal progress bar (fills fraction of card width).
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction});

  /// Value in `[0.0, 1.0]`.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: fraction.clamp(0.0, 1.0),
          backgroundColor: Colors.white.withValues(alpha: 0.35),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 6,
        ),
      ),
    );
  }
}

// ── Bottom bar ─────────────────────────────────────────────────────────────────

/// Fixed bottom strip with a Rexy tip bubble and the "My Stuff" button.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.tip, required this.onMyStuff});

  final String tip;
  final VoidCallback onMyStuff;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: WqColors.background,
        border: Border(top: BorderSide(color: WqColors.lines)),
      ),
      child: Row(
        children: [
          // Rexy mascot tip bubble
          Expanded(child: _RexyTip(tip: tip)),
          const SizedBox(width: 16),
          // My Stuff button (≥ 64 px hit target via WqButton)
          SizedBox(
            width: 200,
            child: WqButton(
              key: const Key('my-stuff-btn'),
              label: 'My Stuff',
              color: WqColors.grape,
              onTap: onMyStuff,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mascot speech-bubble displaying one of Rexy's encouragement tips.
class _RexyTip extends StatelessWidget {
  const _RexyTip({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Art.glyph(Art.mascot, size: 44),
        const SizedBox(width: 8),
        Flexible(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: WqColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WqColors.lines),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                tip,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: WqColors.ink,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Collections modal ──────────────────────────────────────────────────────────

/// "My Treasure Chest" tabbed modal (Dinos · Stickers · Animals).
///
/// Displayed via [showDialog] from [ExpeditionMapScreen._openCollections].
/// Uses [ConsumerStatefulWidget] to read/mutate the save file.
class _CollectionsModal extends ConsumerStatefulWidget {
  const _CollectionsModal() : super(key: const Key('collections-modal'));

  @override
  ConsumerState<_CollectionsModal> createState() => _CollectionsModalState();
}

class _CollectionsModalState extends ConsumerState<_CollectionsModal> {
  String _tab = 'dinos';
  bool _hatching = false;

  /// Name of the dino being cracked open (non-null during the animation phase).
  String? _hatchingDino;

  Future<void> _hatch() async {
    if (_hatching) return;
    final save = ref.read(saveControllerProvider).value;
    if (save == null || save.eggs <= 0) return;

    // Pick a random dino that hasn't been hatched yet.
    final hatched = save.hatched;
    final available = kDinos.where((d) => !hatched.contains(d.name)).toList();
    if (available.isEmpty) return;

    final pick = available[Random().nextInt(available.length)];

    // Start crack animation on the chosen slot.
    setState(() {
      _hatching = true;
      _hatchingDino = pick.name;
    });

    // Wait for the crack animation to finish (~600ms) before revealing dino.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    await ref.read(saveControllerProvider.notifier).hatchEgg(pick.name);
    if (mounted) {
      setState(() {
        _hatching = false;
        _hatchingDino = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final save = ref.watch(saveControllerProvider).value;
    final eggs = save?.eggs ?? 0;
    final hatched = save?.hatched ?? const <String>[];
    final stickers = save?.stickers ?? const <String>[];
    final animalsFound = save?.animalsFound ?? const <String>[];

    return Dialog(
      backgroundColor: WqColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: SizedBox(
        width: 640,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _ModalHeader(onClose: () => Navigator.of(context).pop()),

            // ── Tab row ──────────────────────────────────────────────────────
            _TabRow(
              selectedTab: _tab,
              onTabSelected: (t) => setState(() => _tab = t),
            ),

            // ── Tab content ──────────────────────────────────────────────────
            Expanded(
              child: _tab == 'dinos'
                  ? _DinosTab(
                      hatched: hatched,
                      eggs: eggs,
                      hatching: _hatching,
                      hatchingDino: _hatchingDino,
                      onHatch: _hatch,
                    )
                  : _tab == 'stickers'
                      ? _StickersTab(stickers: stickers)
                      : _AnimalsTab(animalsFound: animalsFound),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal title row with close button.
class _ModalHeader extends StatelessWidget {
  const _ModalHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      child: Row(
        children: [
          Text(
            'My Treasure Chest ${Art.emoji('bag')}',
            style: WqTheme.headingStyle(22),
          ),
          const Spacer(),
          GestureDetector(
            key: const Key('collections-close'),
            onTap: onClose,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Center(
                child: Text(
                  Art.emoji('close'),
                  style: const TextStyle(
                    fontSize: 20,
                    color: WqColors.softInk,
                    fontWeight: FontWeight.bold,
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

/// Horizontal row of tab selector buttons.
class _TabRow extends StatelessWidget {
  const _TabRow({
    required this.selectedTab,
    required this.onTabSelected,
  });

  final String selectedTab;
  final ValueChanged<String> onTabSelected;

  static const _tabs = [
    ('dinos', 'dino-bronto', 'Dinos'),
    ('stickers', 'sparkle', 'Stickers'),
    ('animals', 'land-animal', 'Animals'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: _tabs.map((t) {
          final (id, emoji, label) = t;
          final selected = selectedTab == id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              key: Key('tab-$id'),
              onTap: () => onTabSelected(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                constraints: const BoxConstraints(minHeight: 64),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? WqColors.orange : WqColors.backgroundAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? WqColors.orange : WqColors.lines,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Art.emoji(emoji),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: selected ? Colors.white : WqColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Dinos tab ──────────────────────────────────────────────────────────────────

class _DinosTab extends StatelessWidget {
  const _DinosTab({
    required this.hatched,
    required this.eggs,
    required this.hatching,
    required this.hatchingDino,
    required this.onHatch,
  });

  final List<String> hatched;
  final int eggs;
  final bool hatching;

  /// Name of the specific dino whose slot is currently playing the crack
  /// animation. Null when not hatching.
  final String? hatchingDino;

  final VoidCallback onHatch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Dino grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: kDinos.map((dino) {
                final isHatched = hatched.contains(dino.name);
                return _DinoSlot(
                  dino: dino,
                  isHatched: isHatched,
                  isHatching: hatchingDino == dino.name,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Hatch button (always visible; no-op + grayed when eggs == 0)
          Row(
            children: [
              Text(
                '${Art.emoji('egg')} $eggs ${eggs == 1 ? 'egg' : 'eggs'} to hatch',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  color: WqColors.softInk,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 240,
                child: WqButton(
                  key: const Key('hatch-btn'),
                  label: hatching ? 'Hatching...' : 'Hatch!',
                  color: eggs > 0 ? WqColors.orange : WqColors.softInk,
                  onTap: eggs > 0 ? onHatch : null,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One dino slot in the dino grid: hatched → emoji + name; unhatched → egg + ???
///
/// When [isHatching] is true (and not yet hatched), the egg plays a
/// shake/scale crack animation via [_CrackingEgg] before the dino reveals.
class _DinoSlot extends StatelessWidget {
  const _DinoSlot({
    required this.dino,
    required this.isHatched,
    this.isHatching = false,
  });

  final DinoDef dino;
  final bool isHatched;

  /// True while this specific slot's crack animation is running.
  final bool isHatching;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isHatched ? WqColors.backgroundAlt : WqColors.lines,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHatched ? WqColors.orange : WqColors.lines,
          width: isHatched ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: isHatched
                ? KeyedSubtree(
                    key: ValueKey('dino-${dino.name}'),
                    child: Art.glyph(dino.emojiKey, size: 40),
                  )
                : isHatching
                    ? const _CrackingEgg()
                    : KeyedSubtree(
                        key: const ValueKey('egg-still'),
                        child: Art.glyph('egg', size: 40),
                      ),
          ),
          const SizedBox(height: 4),
          Text(
            isHatched ? dino.name : '???',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isHatched ? WqColors.ink : WqColors.softInk,
            ),
          ),
        ],
      ),
    );
  }
}

/// Egg widget that plays a wiggle + scale-pop crack animation (~600ms).
///
/// Used by [_DinoSlot] while the hatch flow is in the pre-reveal phase.
/// Plain widget only — no packages required.
class _CrackingEgg extends StatelessWidget {
  const _CrackingEgg() : super(key: const ValueKey('egg-cracking'));

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, t, child) {
        // Wiggle: oscillates 5 times and decays toward the end.
        final angle = sin(t * pi * 5) * 0.18 * (1 - t);
        // Scale: rises to 1.3× at the midpoint then settles back to 1.0.
        final scale = 1.0 + 0.3 * sin(t * pi);
        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: angle,
            child: child!,
          ),
        );
      },
      child: Art.glyph('egg', size: 40),
    );
  }
}

// ── Stickers tab ───────────────────────────────────────────────────────────────

class _StickersTab extends StatelessWidget {
  const _StickersTab({required this.stickers});

  final List<String> stickers;

  @override
  Widget build(BuildContext context) {
    if (stickers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Art.glyph('sparkle', size: 56),
            const SizedBox(height: 12),
            Text(
              'Finish activities to earn stickers!',
              style: WqTheme.body.copyWith(color: WqColors.softInk),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: stickers.length,
        itemBuilder: (_, i) => Center(
          child: Text(stickers[i], style: const TextStyle(fontSize: 36)),
        ),
      ),
    );
  }
}

// ── Animals tab ────────────────────────────────────────────────────────────────

class _AnimalsTab extends StatelessWidget {
  const _AnimalsTab({required this.animalsFound});

  final List<String> animalsFound;

  @override
  Widget build(BuildContext context) {
    if (animalsFound.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Art.glyph('land-animal', size: 56),
            const SizedBox(height: 12),
            Text(
              'Discover animals in Animal Planet!',
              style: WqTheme.body.copyWith(color: WqColors.softInk),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: animalsFound.length,
        itemBuilder: (_, i) => DecoratedBox(
          decoration: BoxDecoration(
            color: WqColors.backgroundAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              animalsFound[i],
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: WqColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
