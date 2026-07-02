import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/trace_scorer.dart';
import '../theme/wq_colors.dart';

/// Tracing canvas used by Letter Adventure (Latin) and Hoorof (Arabic).
///
/// Renders a light-coloured guide [glyph], captures finger / Apple Pencil
/// strokes via [GestureDetector], and fires [onCovered] exactly once when
/// stroke coverage crosses the 85 % threshold.
///
/// Guide points are extracted asynchronously by rasterising the glyph with
/// [TextPainter] (font size 420, [WqColors.lines] colour) into a
/// [ui.PictureRecorder], converting to a [ui.Image], and sampling a 24×24
/// grid over the bounding box. Grid cells whose pixel alpha > 0 become guide
/// points (scaled to widget-coordinate space so that [TraceScorer.tolerance]
/// is expressed in the same units as the stroke positions).
///
/// Pointer kind is **not** filtered — both finger and Apple Pencil events
/// arrive as [GestureDetector] callbacks with no extra code required.
class TraceCanvas extends StatefulWidget {
  const TraceCanvas({
    super.key,
    required this.glyph,
    this.fontFamily = 'Baloo2',
    required this.onCovered,
    @visibleForTesting this.debugGuidePoints,
  });

  /// The character or string to trace (e.g. `'B'`, `'ب'`).
  final String glyph;

  /// Font family registered in pubspec.yaml (default: Baloo2 for Latin).
  /// Pass `'NotoNaskhArabic'` for Hoorof Arabic glyphs.
  final String fontFamily;

  /// Called exactly once when stroke coverage reaches ≥ 85 %.
  final VoidCallback onCovered;

  /// Pre-computed guide points that bypass raster extraction.
  ///
  /// Provided only in tests (via `@visibleForTesting`).  The scorer is
  /// initialised immediately in `initState` without running the async
  /// rasterisation pipeline, making the gesture→coverage→[onCovered] path
  /// independently verifiable without depending on font rendering.
  @visibleForTesting
  final List<Offset>? debugGuidePoints;

  // ---------------------------------------------------------------------------
  // Extraction helpers (exposed for unit-testing the raster-sampling logic).
  // ---------------------------------------------------------------------------

  /// Samples a [gridDim]×[gridDim] grid over the glyph bounding box
  /// ([glyphW]×[glyphH]) within a [rasterSize]×[rasterSize] raster encoded
  /// as premultiplied RGBA ([byteData]).  Returns the widget-space [Offset]
  /// of every grid cell whose pixel alpha > 0, using [scale] = widgetW /
  /// rasterSize.
  ///
  /// This is the pure sampling step inside [_TraceCanvasState._extractGuidePoints];
  /// separating it allows unit tests to verify the logic with synthetic byteData
  /// without requiring real font rendering.
  @visibleForTesting
  static List<Offset> sampleGridFromRaster({
    required ByteData byteData,
    required int rasterSize,
    required int gridDim,
    required double glyphW,
    required double glyphH,
    required double scale,
  }) {
    final guidePoints = <Offset>[];
    for (var row = 0; row < gridDim; row++) {
      for (var col = 0; col < gridDim; col++) {
        final cx = col * glyphW / gridDim + glyphW / (2.0 * gridDim);
        final cy = row * glyphH / gridDim + glyphH / (2.0 * gridDim);
        final px = cx.toInt().clamp(0, rasterSize - 1);
        final py = cy.toInt().clamp(0, rasterSize - 1);
        final byteIndex = (py * rasterSize + px) * 4;
        final alpha = byteData.getUint8(byteIndex + 3);
        if (alpha > 0) {
          guidePoints.add(Offset(cx * scale, cy * scale));
        }
      }
    }
    return guidePoints;
  }

  @override
  State<TraceCanvas> createState() => _TraceCanvasState();
}

class _TraceCanvasState extends State<TraceCanvas>
    with SingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Scorer (null until guide points are extracted).
  // ---------------------------------------------------------------------------

  TraceScorer? _scorer;
  bool _extractionStarted = false;
  Size? _layoutSize;

  // ---------------------------------------------------------------------------
  // Stroke paint layer.
  // ---------------------------------------------------------------------------

  /// All completed strokes, each as a list of local widget-space offsets.
  final List<List<Offset>> _strokes = [];

  /// The stroke currently being drawn.
  final List<Offset> _activeStroke = [];

  // ---------------------------------------------------------------------------
  // Completion state.
  // ---------------------------------------------------------------------------

  bool _done = false;
  bool _sparkleVisible = false;
  List<_SparkleParticle> _particles = const [];

  late final AnimationController _sparkleCtrl;
  late final Animation<double> _sparkleFade;

  // ---------------------------------------------------------------------------
  // Lifecycle.
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sparkleFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _sparkleCtrl, curve: Curves.easeOut),
    );

    // Bypass async raster extraction when the caller provides points directly
    // (e.g., in widget tests via [TraceCanvas.debugGuidePoints]).
    final pts = widget.debugGuidePoints;
    if (pts != null && pts.isNotEmpty) {
      _scorer = TraceScorer(guidePoints: pts);
      _extractionStarted = true;
    }
  }

  @override
  void dispose() {
    _sparkleCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Guide-point extraction (async, done once after first layout).
  // ---------------------------------------------------------------------------

  /// Rasterise the glyph at 420×420, sample a 24×24 grid, and build a
  /// [TraceScorer] whose guide points are in widget-coordinate space.
  Future<void> _extractGuidePoints(Size widgetSize) async {
    const rasterSize = 420;
    const fontSize = 420.0;
    const gridDim = 24;

    final tp = TextPainter(
      text: TextSpan(
        text: widget.glyph,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: widget.fontFamily,
          color: WqColors.lines,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    tp.paint(canvas, Offset.zero);
    final picture = recorder.endRecording();
    final image = await picture.toImage(rasterSize, rasterSize);
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    image.dispose();
    picture.dispose();

    if (byteData == null || !mounted) return;

    // Uniform scale matches the guide CustomPainter which does
    // canvas.scale(widgetW / 420) — both use the same transform so guide
    // points and visible pixels share one coordinate space (Finding 1 / 2).
    final scale = widgetSize.width / rasterSize;

    // Sample the 24×24 grid over the glyph's bounding box, not the full
    // 420×420 raster.  Wide or short glyphs (e.g. Arabic) get a dense grid
    // rather than sparse points clustered in one corner (Finding 3).
    final glyphW = tp.width.clamp(0.0, rasterSize.toDouble());
    final glyphH = tp.height.clamp(0.0, rasterSize.toDouble());

    if (glyphW <= 0 || glyphH <= 0) return;

    final guidePoints = TraceCanvas.sampleGridFromRaster(
      byteData: byteData,
      rasterSize: rasterSize,
      gridDim: gridDim,
      glyphW: glyphW,
      glyphH: glyphH,
      scale: scale,
    );

    // Skip creating a scorer when the glyph rendered no visible pixels
    // (e.g. font not loaded in tests). onCovered will never fire in that case.
    if (guidePoints.isEmpty || !mounted) return;

    setState(() {
      _scorer = TraceScorer(guidePoints: guidePoints);
    });
  }

  // ---------------------------------------------------------------------------
  // Gesture handling.
  // ---------------------------------------------------------------------------

  void _onPanStart(DragStartDetails d) {
    _activeStroke
      ..clear()
      ..add(d.localPosition);
    _scorer?.addStrokePoint(d.localPosition);
    _checkDone();
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _activeStroke.add(d.localPosition);
    _scorer?.addStrokePoint(d.localPosition);
    _checkDone();
    setState(() {});
  }

  void _onPanEnd(DragEndDetails d) {
    _strokes.add(List<Offset>.of(_activeStroke));
    _activeStroke.clear();
    setState(() {});
  }

  void _checkDone() {
    if (_done) return;
    if (_scorer?.done ?? false) {
      _done = true;
      _triggerSparkle();
      widget.onCovered();
    }
  }

  // ---------------------------------------------------------------------------
  // Sparkle.
  // ---------------------------------------------------------------------------

  void _triggerSparkle() {
    final rng = math.Random();
    const icons = ['✨', '⭐', '🌟', '💫', '🎉'];
    _particles = List<_SparkleParticle>.generate(10, (i) {
      final angle = math.pi * 2.0 * i / 10 + rng.nextDouble() * 0.4;
      final dist = 90.0 + rng.nextDouble() * 70.0;
      return _SparkleParticle(
        icon: icons[i % icons.length],
        dx: math.cos(angle) * dist,
        dy: math.sin(angle) * dist,
      );
    });

    setState(() => _sparkleVisible = true);
    _sparkleCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _sparkleVisible = false);
    });
  }

  // ---------------------------------------------------------------------------
  // Build.
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 420,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 420,
        );

        // Trigger guide-point extraction once, after the first layout pass.
        if (!_extractionStarted) {
          _extractionStarted = true;
          _layoutSize = size;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _layoutSize != null) {
              _extractGuidePoints(_layoutSize!);
            }
          });
        }

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: SizedBox.fromSize(
            size: size,
            child: Stack(
              children: [
                // ── Guide glyph (lightly tinted, non-interactive) ──────────
                Positioned.fill(child: _GlyphGuide(
                  glyph: widget.glyph,
                  fontFamily: widget.fontFamily,
                )),

                // ── Child's ink strokes ────────────────────────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StrokePainter(
                      strokes: _strokes,
                      activeStroke: _activeStroke,
                    ),
                  ),
                ),

                // ── Sparkle overlay (fires once when done) ─────────────────
                if (_sparkleVisible)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _sparkleFade,
                        builder: (_, child) => Opacity(
                          opacity: _sparkleFade.value,
                          child: child,
                        ),
                        child: _SparkleOverlay(particles: _particles),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Guide glyph widget
// ---------------------------------------------------------------------------

/// Renders the guide glyph via the SAME [TextPainter] transform used by
/// [_TraceCanvasState._extractGuidePoints]: a uniform scale of
/// `widgetWidth / 420` with the origin at (0, 0) and [TextDirection.ltr].
///
/// Keeping both paths identical by construction ensures that guide points
/// and visible pixels share one coordinate space (Findings 1 & 2).
class _GlyphGuide extends StatefulWidget {
  const _GlyphGuide({required this.glyph, required this.fontFamily});

  final String glyph;
  final String fontFamily;

  @override
  State<_GlyphGuide> createState() => _GlyphGuideState();
}

class _GlyphGuideState extends State<_GlyphGuide> {
  late TextPainter _tp;

  @override
  void initState() {
    super.initState();
    _tp = _buildTextPainter();
  }

  @override
  void didUpdateWidget(_GlyphGuide old) {
    super.didUpdateWidget(old);
    if (old.glyph != widget.glyph || old.fontFamily != widget.fontFamily) {
      _tp.dispose();
      _tp = _buildTextPainter();
    }
  }

  @override
  void dispose() {
    _tp.dispose();
    super.dispose();
  }

  TextPainter _buildTextPainter() => TextPainter(
        text: TextSpan(
          text: widget.glyph,
          style: TextStyle(
            fontSize: 420,
            fontFamily: widget.fontFamily,
            color: WqColors.lines,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GlyphGuidePainter(_tp));
  }
}

/// Paints the guide glyph with a uniform [canvas.scale] of [size.width / 420]
/// anchored at the origin — identical to the transform applied during raster
/// extraction — so guide points and visible pixels share a coordinate space.
class _GlyphGuidePainter extends CustomPainter {
  const _GlyphGuidePainter(this._tp);

  final TextPainter _tp;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 420);
    _tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphGuidePainter old) => old._tp != _tp;
}

// ---------------------------------------------------------------------------
// Stroke painter
// ---------------------------------------------------------------------------

class _StrokePainter extends CustomPainter {
  const _StrokePainter({
    required this.strokes,
    required this.activeStroke,
  });

  final List<List<Offset>> strokes;
  final List<Offset> activeStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = WqColors.teal.withValues(alpha: 0.92)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> pts) {
      if (pts.isEmpty) return;
      if (pts.length == 1) {
        // Single tap → filled dot.
        canvas.drawCircle(
          pts.first,
          9,
          Paint()
            ..color = WqColors.teal.withValues(alpha: 0.92)
            ..style = PaintingStyle.fill,
        );
        return;
      }
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final stroke in strokes) {
      drawStroke(stroke);
    }
    drawStroke(activeStroke);
  }

  @override
  bool shouldRepaint(_StrokePainter old) =>
      old.strokes.length != strokes.length ||
      old.activeStroke.length != activeStroke.length;
}

// ---------------------------------------------------------------------------
// Sparkle overlay
// ---------------------------------------------------------------------------

class _SparkleParticle {
  const _SparkleParticle({
    required this.icon,
    required this.dx,
    required this.dy,
  });

  final String icon;
  final double dx;
  final double dy;
}

class _SparkleOverlay extends StatelessWidget {
  const _SparkleOverlay({required this.particles});

  final List<_SparkleParticle> particles;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: particles
          .map(
            (p) => Transform.translate(
              offset: Offset(p.dx, p.dy),
              child: Text(p.icon, style: const TextStyle(fontSize: 28)),
            ),
          )
          .toList(),
    );
  }
}
