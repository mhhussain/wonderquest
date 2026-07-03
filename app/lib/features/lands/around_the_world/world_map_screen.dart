import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/world_content.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/save_controller.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';

// ---------------------------------------------------------------------------
// Continent path data (from raw/world.jsx CONTINENT_PATHS)
// Each path is defined in a 1000×560 coordinate space.
// ---------------------------------------------------------------------------

const _kViewW = 1000.0;
const _kViewH = 560.0;

const _continentPaths = <String, String>{
  'namerica':
      'M92,92 C120,60 205,54 244,82 C284,72 305,104 286,132 C302,152 272,168 256,162 '
          'C242,184 226,166 221,192 C216,218 201,244 188,222 C182,201 191,181 172,179 '
          'C150,202 118,186 130,150 C99,150 80,118 92,92 Z',
  'samerica':
      'M252,292 C302,286 328,318 313,352 C322,388 296,422 281,458 C273,478 257,472 258,450 '
          'C244,421 234,386 240,351 C228,326 231,302 252,292 Z',
  'europe':
      'M462,92 C502,78 545,86 538,112 C552,128 527,143 511,137 C501,158 477,152 475,131 '
          'C454,129 449,102 462,92 Z',
  'africa':
      'M502,196 C562,180 614,202 602,248 C618,289 587,333 561,373 C549,399 519,394 514,362 '
          'C493,342 484,301 496,270 C474,256 470,217 502,196 Z',
  'asia':
      'M582,100 C654,68 786,68 858,100 C900,121 889,162 857,177 C878,203 826,218 805,197 '
          'C784,223 742,212 732,186 C690,202 638,186 640,160 C598,166 560,135 582,100 Z',
  'australia':
      'M784,360 C846,344 898,366 887,402 C892,433 850,453 814,447 C778,458 757,427 768,401 '
          'C757,379 763,365 784,360 Z',
  'antarctica':
      'M150,502 C352,486 652,486 862,506 C884,522 852,542 700,540 C450,547 250,542 146,533 '
          'C120,521 130,506 150,502 Z',
};

// Label positions for emoji+name labels (from raw/world.jsx CONTINENT_LABELS)
const _continentLabels = <String, Offset>{
  'namerica': Offset(182, 150),
  'samerica': Offset(279, 378),
  'europe': Offset(500, 116),
  'africa': Offset(546, 292),
  'asia': Offset(722, 150),
  'australia': Offset(824, 406),
  'antarctica': Offset(502, 516),
};

// ---------------------------------------------------------------------------
// SVG-path parser (minimal subset: M, L, C, Z absolute commands)
// ---------------------------------------------------------------------------

/// Parses an SVG-subset path string into a Flutter [Path].
///
/// Supports absolute: M, L, C, Z commands (the only ones used in continent data).
Path _parseSvgPath(String d) {
  final path = Path();
  final tokens = d.trim().split(RegExp(r'[ ,]+'));
  int i = 0;

  double x = 0, y = 0;

  while (i < tokens.length) {
    final cmd = tokens[i];
    switch (cmd) {
      case 'M':
        x = double.parse(tokens[++i]);
        y = double.parse(tokens[++i]);
        path.moveTo(x, y);
      case 'C':
        while (i + 6 < tokens.length &&
            double.tryParse(tokens[i + 1]) != null) {
          final x1 = double.parse(tokens[++i]);
          final y1 = double.parse(tokens[++i]);
          final x2 = double.parse(tokens[++i]);
          final y2 = double.parse(tokens[++i]);
          x = double.parse(tokens[++i]);
          y = double.parse(tokens[++i]);
          path.cubicTo(x1, y1, x2, y2, x, y);
        }
      case 'L':
        x = double.parse(tokens[++i]);
        y = double.parse(tokens[++i]);
        path.lineTo(x, y);
      case 'Z':
        path.close();
      default:
        // Unknown token — try to parse as implicit coordinate continuation.
        break;
    }
    i++;
  }
  return path;
}

// ---------------------------------------------------------------------------
// Map painter
// ---------------------------------------------------------------------------

class _WorldMapPainter extends CustomPainter {
  _WorldMapPainter({
    required this.continents,
    required this.visited,
    required this.scale,
    this.hoveredId,
  });

  final List<Continent> continents;
  final Map<String, bool> visited;
  final double scale;
  final String? hoveredId;

  @override
  void paint(Canvas canvas, Size size) {
    // Ocean gradient background
    final oceanPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.2),
        radius: 0.75,
        colors: [Color(0xFFBFE8F7), Color(0xFF8FCDEA)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(24),
      ),
      oceanPaint,
    );

    // Latitude/longitude lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.5 * scale
      ..style = PaintingStyle.stroke;
    final latY1 = 187 * size.height / _kViewH;
    final latY2 = 373 * size.height / _kViewH;
    final lonX1 = 333 * size.width / _kViewW;
    final lonX2 = 667 * size.width / _kViewW;
    canvas.drawLine(Offset(0, latY1), Offset(size.width, latY1), linePaint);
    canvas.drawLine(Offset(0, latY2), Offset(size.width, latY2), linePaint);
    canvas.drawLine(Offset(lonX1, 0), Offset(lonX1, size.height), linePaint);
    canvas.drawLine(Offset(lonX2, 0), Offset(lonX2, size.height), linePaint);

    // Continent shapes
    final sx = size.width / _kViewW;
    final sy = size.height / _kViewH;

    for (final c in continents) {
      final svgPath = _continentPaths[c.id];
      if (svgPath == null) continue;

      final rawPath = _parseSvgPath(svgPath);
      final matrix = Matrix4.diagonal3Values(sx, sy, 1.0);
      final scaledPath = rawPath.transform(matrix.storage);

      final isHovered = hoveredId == c.id;
      final fillColor = isHovered ? c.color.withValues(alpha: 0.9) : c.color;

      // Drop shadow
      final shadowPaint = Paint()
        ..color = const Color(0x521C5A78)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(scaledPath.shift(const Offset(0, 3)), shadowPaint);

      // Fill
      canvas.drawPath(scaledPath, Paint()..color = fillColor);

      // Stroke
      canvas.drawPath(
        scaledPath,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2.5 * scale
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_WorldMapPainter old) =>
      old.visited != visited ||
      old.hoveredId != hoveredId ||
      old.scale != scale;
}

// ---------------------------------------------------------------------------
// WorldMapScreen
// ---------------------------------------------------------------------------

/// The interactive world map — 7 tappable continent blobs + passport button.
class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({
    super.key,
    required this.onContinentSelected,
    required this.onPassport,
  });

  final ValueChanged<Continent> onContinentSelected;
  final VoidCallback onPassport;

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  String? _hoveredId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(ttsServiceProvider)
          .speak('Where in the world should we explore today?');
    });
  }

  void _onTapContinent(Continent c, Size mapSize) {
    ref.read(ttsServiceProvider).speak('Fly to ${c.name}!');
    widget.onContinentSelected(c);
  }

  /// Returns the continent hit by [localPos] in [mapSize], or null.
  Continent? _hitTest(Offset localPos, Size mapSize) {
    final sx = mapSize.width / _kViewW;
    final sy = mapSize.height / _kViewH;
    for (final c in kContinents.reversed) {
      final svgPath = _continentPaths[c.id];
      if (svgPath == null) continue;
      final rawPath = _parseSvgPath(svgPath);
      final matrix = Matrix4.diagonal3Values(sx, sy, 1.0);
      final scaledPath = rawPath.transform(matrix.storage);
      // Expand hit area slightly (±10 px) to make small continents easier to tap
      if (scaledPath.contains(localPos)) return c;
      // Also check slightly offset positions for easier tapping
      for (final off in const [
        Offset(-10, 0),
        Offset(10, 0),
        Offset(0, -10),
        Offset(0, 10),
      ]) {
        if (scaledPath.contains(localPos + off)) return c;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final saveAsync = ref.watch(saveControllerProvider);
    final visited = saveAsync.value?.world.visited ?? {};
    final stamps = visited.length;

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
          '🌍 Around the World',
          style: WqTheme.headingStyle(22),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              key: const Key('passport-btn'),
              style: TextButton.styleFrom(
                backgroundColor: WqColors.sky.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: widget.onPassport,
              icon: const Text('🛂', style: TextStyle(fontSize: 22)),
              label: Text(
                'Passport  $stamps/7',
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: WqColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              'Tap a place to fly there with Pip the parrot!',
              style:
                  WqTheme.headingStyle(16).copyWith(color: WqColors.softInk),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mapSize = Size(constraints.maxWidth,
                      constraints.maxHeight.clamp(0.0, 500.0));
                  return GestureDetector(
                    onTapUp: (details) {
                      final c = _hitTest(details.localPosition, mapSize);
                      if (c != null) _onTapContinent(c, mapSize);
                    },
                    onPanUpdate: (details) {
                      final c =
                          _hitTest(details.localPosition, mapSize);
                      if (c?.id != _hoveredId) {
                        setState(() => _hoveredId = c?.id);
                      }
                    },
                    onPanEnd: (_) => setState(() => _hoveredId = null),
                    child: Stack(
                      children: [
                        // The painted map
                        CustomPaint(
                          size: mapSize,
                          painter: _WorldMapPainter(
                            continents: kContinents,
                            visited: visited,
                            scale: mapSize.width / _kViewW,
                            hoveredId: _hoveredId,
                          ),
                        ),
                        // Overlay: emoji + name labels + badges
                        ..._buildLabels(mapSize, visited),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Legend bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(
              stamps == 0
                  ? '🧭 Tap any land to start your first adventure!'
                  : "🧭 You've explored $stamps of 7 places. Keep going, Explorer!",
              style:
                  WqTheme.headingStyle(15).copyWith(color: WqColors.softInk),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLabels(Size mapSize, Map<String, bool> visited) {
    final sx = mapSize.width / _kViewW;
    final sy = mapSize.height / _kViewH;
    return kContinents.map((c) {
      final labelPos = _continentLabels[c.id];
      if (labelPos == null) return const SizedBox.shrink();
      final lx = labelPos.dx * sx;
      final ly = labelPos.dy * sy;
      final isVisited = visited[c.id] == true;

      return Positioned(
        left: lx - 40,
        top: ly - 40,
        width: 80,
        child: GestureDetector(
          key: Key('continent-label-${c.id}'),
          behavior: HitTestBehavior.translucent,
          onTap: () => _onTapContinent(c, mapSize),
          child: SizedBox(
            height: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isVisited)
                  Text(
                    c.badge,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    c.emoji,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                Text(
                  c.name,
                  style: const TextStyle(
                    fontFamily: 'Baloo2',
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 1),
                          blurRadius: 2),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
