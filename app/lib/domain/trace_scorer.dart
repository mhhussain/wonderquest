import 'dart:ui' show Offset;

/// Pure-Dart glyph-agnostic tracing scorer.
///
/// Given a list of [guidePoints] sampled from a glyph raster,
/// [addStrokePoint] marks every guide point within [tolerance] pixels
/// as covered. [coverage] returns the fraction covered (0..1); [done]
/// is true once coverage reaches 85%.
///
/// Works identically for Latin glyphs (Letter Adventure) and Arabic
/// glyphs (Hoorof) — the caller rasterises the glyph and supplies the
/// guide points.
class TraceScorer {
  TraceScorer({required List<Offset> guidePoints, this.tolerance = 28})
      : _guidePoints = List<Offset>.unmodifiable(guidePoints),
        _covered = List<bool>.filled(guidePoints.length, false);

  final List<Offset> _guidePoints;
  final List<bool> _covered;

  /// Radius (in pixels) within which a stroke point marks a guide point.
  final double tolerance;

  int _coveredCount = 0;
  int _strokeTotal = 0;
  int _strokeHits = 0;

  /// Mark every uncovered guide point within [tolerance] of [p] as covered,
  /// and record whether [p] landed on the glyph at all (for [accuracy]).
  void addStrokePoint(Offset p) {
    final t2 = tolerance * tolerance;
    var hit = false;
    for (var i = 0; i < _guidePoints.length; i++) {
      final dx = _guidePoints[i].dx - p.dx;
      final dy = _guidePoints[i].dy - p.dy;
      if (dx * dx + dy * dy <= t2) {
        hit = true;
        if (!_covered[i]) {
          _covered[i] = true;
          _coveredCount++;
        }
      }
    }
    _strokeTotal++;
    if (hit) _strokeHits++;
  }

  /// Fraction of guide points covered, in [0..1].
  ///
  /// Returns 1.0 if there are no guide points (degenerate case).
  double get coverage =>
      _guidePoints.isEmpty ? 1.0 : _coveredCount / _guidePoints.length;

  /// True when [coverage] >= 0.85.
  bool get done => coverage >= 0.85;

  /// Tracing accuracy in [0..1]: fraction of stroke points that landed
  /// within [tolerance] of the glyph (1.0 = no scribbling outside it).
  ///
  /// Returns 1.0 before any stroke point is added (degenerate case).
  double get accuracy => _strokeTotal == 0 ? 1.0 : _strokeHits / _strokeTotal;
}
