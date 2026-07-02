import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/widgets/trace_canvas.dart';

void main() {
  group('TraceCanvas', () {
    testWidgets(
      'smoke — CustomPaint is in the tree after async guide extraction',
      (tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            MaterialApp(
              home: SizedBox(
                width: 400,
                height: 400,
                child: TraceCanvas(glyph: 'B', onCovered: () {}),
              ),
            ),
          );

          // First pump: LayoutBuilder runs, post-frame callback is registered.
          await tester.pump();

          // Second pump: post-frame callback fires, _extractGuidePoints starts.
          await tester.pump();

          // Allow picture.toImage() and toByteData() to complete inside runAsync.
          await Future<void>.delayed(const Duration(milliseconds: 200));

          // Rebuild after setState from extraction.
          await tester.pump();
        });

        // The stroke-paint CustomPaint is always present, regardless of
        // whether guide extraction produced any points.
        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      },
    );
  });
}
