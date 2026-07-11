import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/domain/trace_scorer.dart';

void main() {
  // 10-point horizontal guide at y=0, x=0, 10, 20, … 90.
  // With tolerance=4 each stroke point hits exactly one guide point
  // (next neighbor is 10 px away, well beyond tolerance).
  List<Offset> hLine() =>
      List<Offset>.generate(10, (i) => Offset(i * 10.0, 0));

  group('TraceScorer', () {
    test('full stroke along guide line → coverage 1.0 and done', () {
      final scorer = TraceScorer(guidePoints: hLine(), tolerance: 4);
      for (final pt in hLine()) {
        scorer.addStrokePoint(pt);
      }
      expect(scorer.coverage, closeTo(1.0, 1e-9));
      expect(scorer.done, isTrue);
    });

    test('stroke along half of guide line → coverage 0.5, not done', () {
      final scorer = TraceScorer(guidePoints: hLine(), tolerance: 4);
      // Cover only the first 5 points (indices 0–4).
      for (var i = 0; i < 5; i++) {
        scorer.addStrokePoint(Offset(i * 10.0, 0));
      }
      expect(scorer.coverage, closeTo(0.5, 1e-9));
      expect(scorer.done, isFalse);
    });

    test('far-away stroke → 0.0 coverage, not done', () {
      final scorer = TraceScorer(guidePoints: hLine(), tolerance: 4);
      scorer.addStrokePoint(const Offset(1000, 1000));
      expect(scorer.coverage, closeTo(0.0, 1e-9));
      expect(scorer.done, isFalse);
    });

    test('threshold boundary: 0.80 not done, 0.90 done', () {
      // 8 / 10 = 0.80 — just below the 0.85 threshold.
      final scorer8 = TraceScorer(guidePoints: hLine(), tolerance: 4);
      for (var i = 0; i < 8; i++) {
        scorer8.addStrokePoint(Offset(i * 10.0, 0));
      }
      expect(scorer8.coverage, closeTo(0.80, 1e-9));
      expect(scorer8.done, isFalse,
          reason: '0.80 is below the 0.85 done threshold');

      // 9 / 10 = 0.90 — above the threshold.
      final scorer9 = TraceScorer(guidePoints: hLine(), tolerance: 4);
      for (var i = 0; i < 9; i++) {
        scorer9.addStrokePoint(Offset(i * 10.0, 0));
      }
      expect(scorer9.coverage, closeTo(0.90, 1e-9));
      expect(scorer9.done, isTrue,
          reason: '0.90 is above the 0.85 done threshold');
    });
  });
}
