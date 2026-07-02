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
  });
}
