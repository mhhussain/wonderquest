import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/spot_scenes_content.dart';
import '../../../core/audio/sfx_service.dart';
import '../../../domain/reward.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/reward_modal.dart';
import 'spot_me_screen.dart';

// ---------------------------------------------------------------------------
// Domain types
// ---------------------------------------------------------------------------

/// A single sock item in the Match-the-Socks grid.
@immutable
class SockItem {
  const SockItem({
    required this.pairId,
    required this.color,
    required this.pattern,
    required this.slotIndex,
  });

  /// Socks with the same [pairId] are a matching pair.
  final int pairId;
  final Color color;

  /// One of: 'solid', 'stripe', 'dots', 'zig'.
  final String pattern;

  /// Position in the shuffled display grid.
  final int slotIndex;
}

/// Returns `true` when [a] and [b] satisfy the [level]'s matching criterion.
///
/// - `'color'`  : same color (pattern is irrelevant).
/// - `'pattern'`: same pattern (color is irrelevant).
/// - `'both'`   : same color AND same pattern.
bool socksMatch(SockItem a, SockItem b, SockLevel level) {
  switch (level.by) {
    case 'color':
      return a.color == b.color;
    case 'pattern':
      return a.pattern == b.pattern;
    case 'both':
      return a.color == b.color && a.pattern == b.pattern;
    default:
      return false;
  }
}

/// Generates [level.pairs] pairs of socks suitable for the given level.
///
/// - Level 0 (`color`)  : all socks share a single pattern; pairs differ by color.
/// - Level 1 (`pattern`): all socks share a single color; pairs differ by pattern.
/// - Level 2 (`both`)   : each pair is unique in both color and pattern.
///
/// Items are shuffled so the grid order is random.
List<SockItem> generateSocks(SockLevel level, Random random) {
  // Clamp to the number of distinguishable visual variants for this level.
  // Pattern level has kSockPatterns.length (4) distinct values; requesting 5
  // pairs would wrap around and produce duplicate patterns, soft-locking play.
  final n = level.by == 'pattern'
      ? min(level.pairs, kSockPatterns.length)
      : level.pairs;

  final colors = List<Color>.from(kSockColors)..shuffle(random);
  final patterns = List<String>.from(kSockPatterns)..shuffle(random);

  final items = <SockItem>[];

  for (var i = 0; i < n; i++) {
    final Color c;
    final String p;

    switch (level.by) {
      case 'color':
        c = colors[i % colors.length];
        p = 'solid'; // same pattern for all → match purely on color
        break;
      case 'pattern':
        c = kSockColors[0]; // same color for all → match purely on pattern
        p = patterns[i % patterns.length];
        break;
      case 'both':
      default:
        c = colors[i % colors.length];
        p = patterns[i % patterns.length];
        break;
    }

    items
      ..add(SockItem(pairId: i, color: c, pattern: p, slotIndex: 0))
      ..add(SockItem(pairId: i, color: c, pattern: p, slotIndex: 0));
  }

  items.shuffle(random);

  // Assign slot indices after shuffle.
  return [
    for (var idx = 0; idx < items.length; idx++)
      SockItem(
        pairId: items[idx].pairId,
        color: items[idx].color,
        pattern: items[idx].pattern,
        slotIndex: idx,
      ),
  ];
}

// ---------------------------------------------------------------------------
// SocksScreen
// ---------------------------------------------------------------------------

/// Match-the-Socks game: three progressive levels (color → pattern → both).
///
/// Each level shows a shuffled grid of socks.  The player taps two socks; if
/// they form a matching pair (determined by [socksMatch] for the active
/// [SockLevel]) they're marked found.  When all pairs are found the next
/// level begins.  After level 3 the reward modal is shown.
class SocksScreen extends ConsumerStatefulWidget {
  const SocksScreen({super.key});

  @override
  ConsumerState<SocksScreen> createState() => _SocksScreenState();
}

class _SocksScreenState extends ConsumerState<SocksScreen> {
  int _levelIndex = 0;
  late List<SockItem> _socks;
  final Set<int> _foundPairs = {}; // set of pairIds that have been matched
  int? _selectedSlot; // currently highlighted sock slot index
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  SockLevel get _level => kSockLevels[_levelIndex];

  void _initLevel() {
    _socks = generateSocks(_level, Random());
    _foundPairs.clear();
    _selectedSlot = null;
  }

  Future<void> _onTap(SockItem sock) async {
    if (_animating) return;
    if (_foundPairs.contains(sock.pairId)) return; // already matched

    final sfx = ref.read(sfxServiceProvider);

    if (_selectedSlot == null) {
      // First tap: highlight this sock.
      setState(() => _selectedSlot = sock.slotIndex);
      return;
    }

    if (_selectedSlot == sock.slotIndex) {
      // Tapped the same sock → deselect.
      setState(() => _selectedSlot = null);
      return;
    }

    // Second tap: find the first sock and compare.
    final firstSock = _socks.firstWhere((s) => s.slotIndex == _selectedSlot);

    if (socksMatch(firstSock, sock, _level) &&
        firstSock.pairId != sock.pairId) {
      // This shouldn't normally happen (pairs are generated correctly) but
      // guard against content bugs — play wrong sound so child gets feedback.
      await sfx.play(Sfx.wrong);
      setState(() => _selectedSlot = null);
      return;
    }

    if (firstSock.pairId == sock.pairId && socksMatch(firstSock, sock, _level)) {
      // Match!
      _animating = true;
      await sfx.play(Sfx.ding);
      setState(() {
        _foundPairs.add(sock.pairId);
        _selectedSlot = null;
        _animating = false;
      });

      if (_foundPairs.length == _socks.length ~/ 2) {
        await _onLevelComplete();
      }
    } else {
      // Mismatch: show briefly then clear.
      _animating = true;
      await sfx.play(Sfx.wrong);
      setState(() => _animating = false);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _selectedSlot = null);
      _animating = false;
    }
  }

  Future<void> _onLevelComplete() async {
    if (_levelIndex + 1 < kSockLevels.length) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _levelIndex++;
        _initLevel();
      });
      return;
    }

    // All 3 levels done.
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
        xp: 28,
        egg: true,
        sticker: title ?? '🧦',
        progressKey: 'find',
        progressTo: 55,
      ),
      onPlayAgain: () {
        if (mounted) {
          setState(() {
            _levelIndex = 0;
            _initLevel();
          });
        }
      },
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    final total = _socks.length;
    final cols = total <= 8 ? 4 : total <= 10 ? 5 : 6;

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
          '🧦 Match the Socks — Level ${_levelIndex + 1}',
          style: WqTheme.headingStyle(20),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruction banner.
            DecoratedBox(
              decoration: BoxDecoration(
                color: WqColors.backgroundAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  level.say,
                  textAlign: TextAlign.center,
                  style: WqTheme.headingStyle(17)
                      .copyWith(color: WqColors.softInk),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Progress indicator.
            Text(
              '${_foundPairs.length} / ${_socks.length ~/ 2} pairs found',
              textAlign: TextAlign.center,
              style: WqTheme.headingStyle(15)
                  .copyWith(color: WqColors.teal),
            ),
            const SizedBox(height: 16),

            // Sock grid.
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemCount: total,
                itemBuilder: (context, idx) {
                  final sock = _socks[idx];
                  final isFound = _foundPairs.contains(sock.pairId);
                  final isSelected = _selectedSlot == sock.slotIndex;

                  return GestureDetector(
                    key: Key('sock-slot-${sock.slotIndex}'),
                    onTap: isFound ? null : () => _onTap(sock),
                    child: AnimatedOpacity(
                      opacity: isFound ? 0.35 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: _SockWidget(
                        color: sock.color,
                        pattern: sock.pattern,
                        isSelected: isSelected,
                        isFound: isFound,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sock rendering
// ---------------------------------------------------------------------------

/// Renders a single sock using [ClipPath] + [CustomPaint].
///
/// The foot points to the right; the cuff is at the top. Patterns are painted
/// over the filled body:
/// - `solid`  : plain fill.
/// - `stripe` : horizontal stripes.
/// - `dots`   : polka-dot circles.
/// - `zig`    : zigzag band across the cuff.
class _SockWidget extends StatelessWidget {
  const _SockWidget({
    required this.color,
    required this.pattern,
    required this.isSelected,
    required this.isFound,
  });

  final Color color;
  final String pattern;
  final bool isSelected;
  final bool isFound;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? WqColors.yellow : Colors.transparent,
          width: 4,
        ),
        boxShadow: isSelected
            ? [
                const BoxShadow(
                  color: Color(0x66FFC53D),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipPath(
        clipper: _SockClipper(),
        child: CustomPaint(
          painter: _SockPainter(color: color, pattern: pattern),
        ),
      ),
    );
  }
}

/// Clips the widget into a sock silhouette — a narrow leg (upper 65 %) that
/// joins a wider foot (lower 50 %).  The two rounded rectangles union via the
/// `PathFillType.nonZero` default fill type.
class _SockClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    // Leg: centred narrow rectangle occupying the upper 65 %.
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, 0, w * 0.6, h * 0.65),
        const Radius.circular(8),
      ),
    );
    // Foot: full-width rectangle occupying the lower 50 %.
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.5, w, h * 0.5),
        const Radius.circular(12),
      ),
    );
    return path;
  }

  @override
  bool shouldReclip(_SockClipper old) => false;
}

/// Paints the sock body color and the chosen [pattern].
class _SockPainter extends CustomPainter {
  const _SockPainter({required this.color, required this.pattern});

  final Color color;
  final String pattern;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final accent = Paint()
      ..color = color.computeLuminance() > 0.4
          ? color.withValues(alpha: 0.35)
          : Colors.white.withValues(alpha: 0.35);

    // Fill the whole bounding rect (the clip handles the shape).
    canvas.drawRect(Offset.zero & size, fill);

    switch (pattern) {
      case 'stripe':
        _paintStripes(canvas, size, accent);
        break;
      case 'dots':
        _paintDots(canvas, size, accent);
        break;
      case 'zig':
        _paintZig(canvas, size, accent);
        break;
      case 'solid':
      default:
        // Plain fill is all that's needed.
        break;
    }
  }

  void _paintStripes(Canvas canvas, Size size, Paint p) {
    const stripeHeight = 8.0;
    const gap = 10.0;
    var y = 4.0;
    while (y < size.height) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, stripeHeight),
        p,
      );
      y += stripeHeight + gap;
    }
  }

  void _paintDots(Canvas canvas, Size size, Paint p) {
    const r = 5.0;
    const spacing = 18.0;
    var row = 0;
    for (var y = spacing / 2; y < size.height; y += spacing, row++) {
      final xOffset = row.isOdd ? spacing / 2 : 0.0;
      for (var x = xOffset + r; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), r, p);
      }
    }
  }

  void _paintZig(Canvas canvas, Size size, Paint p) {
    const amplitude = 6.0;
    const wavelength = 16.0;
    const strokeW = 4.0;
    p = Paint()
      ..color = p.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;

    for (final yBase in [size.height * 0.15, size.height * 0.55]) {
      final path = Path();
      path.moveTo(0, yBase);
      var x = 0.0;
      var up = true;
      while (x < size.width) {
        final nx = x + wavelength / 2;
        final ny = up ? yBase - amplitude : yBase + amplitude;
        path.lineTo(nx, ny);
        x = nx;
        up = !up;
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_SockPainter old) =>
      old.color != color || old.pattern != pattern;
}
