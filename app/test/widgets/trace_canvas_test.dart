import 'dart:typed_data';

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

    // -------------------------------------------------------------------------
    // sampleGridFromRaster — pure raster-sampling logic
    // -------------------------------------------------------------------------
    //
    // Tests the extraction algorithm with synthetic (no-font) byteData so that
    // coordinate-alignment correctness is verifiable without real rendering.

    test(
      'sampleGridFromRaster: all-opaque raster → all 24×24 cells extracted '
      'and all points inside the expected widget rect',
      () {
        // Build a 420×420 all-opaque byteData (rawRgba: 4 bytes per pixel).
        const rasterSize = 420;
        const gridDim = 24;
        const widgetW = 400.0;
        final data = Uint8List(rasterSize * rasterSize * 4);
        // Set the alpha byte (offset +3) to 255 for every pixel.
        for (var i = 3; i < data.length; i += 4) {
          data[i] = 255;
        }
        final byteData = data.buffer.asByteData();

        const scale = widgetW / rasterSize; // 400 / 420

        final points = TraceCanvas.sampleGridFromRaster(
          byteData: byteData,
          rasterSize: rasterSize,
          gridDim: gridDim,
          glyphW: rasterSize.toDouble(),
          glyphH: rasterSize.toDouble(),
          scale: scale,
        );

        // Every one of the 24×24 cells must be present (solid raster).
        expect(points.length, equals(gridDim * gridDim),
            reason: 'all ${gridDim * gridDim} grid cells should yield a guide point');

        // All points must be inside the widget-space glyph rect
        // [0, widgetW] × [0, widgetH] — the same area the guide painter draws.
        const widgetH = widgetW; // square widget
        for (final p in points) {
          expect(p.dx, greaterThan(0),
              reason: 'guide point x must be > 0 (not at left edge)');
          expect(p.dx, lessThan(widgetW),
              reason: 'guide point x must be < widgetW');
          expect(p.dy, greaterThan(0),
              reason: 'guide point y must be > 0 (not at top edge)');
          expect(p.dy, lessThan(widgetH),
              reason: 'guide point y must be < widgetH');
        }
      },
    );

    test(
      'sampleGridFromRaster: narrow bounding box → guide points cluster '
      'inside the bounding box, not spread across the full raster',
      () {
        // Simulate a narrow glyph: only the left 100 px × 200 px are opaque.
        const rasterSize = 420;
        const gridDim = 24;
        const widgetW = 400.0;
        final data = Uint8List(rasterSize * rasterSize * 4);
        for (var row = 0; row < 200; row++) {
          for (var col = 0; col < 100; col++) {
            data[(row * rasterSize + col) * 4 + 3] = 255;
          }
        }
        final byteData = data.buffer.asByteData();
        const scale = widgetW / rasterSize;

        final points = TraceCanvas.sampleGridFromRaster(
          byteData: byteData,
          rasterSize: rasterSize,
          gridDim: gridDim,
          glyphW: 100.0, // bounding-box width, not full raster
          glyphH: 200.0,
          scale: scale,
        );

        expect(points, isNotEmpty);
        // All points must be within [0, 100*scale] × [0, 200*scale].
        for (final p in points) {
          expect(p.dx, lessThanOrEqualTo(100 * scale + 1e-9));
          expect(p.dy, lessThanOrEqualTo(200 * scale + 1e-9));
        }
      },
    );

    // -------------------------------------------------------------------------
    // Widget-level gesture pipeline
    // -------------------------------------------------------------------------
    //
    // Uses debugGuidePoints to inject a pre-computed scorer grid, bypassing
    // raster extraction (which depends on real font rendering unavailable in
    // flutter_test).  This lets us verify the gesture → coverage → onCovered
    // pipeline reliably.

    testWidgets(
      'debugGuidePoints minimal: single guide point hit → onCovered fires',
      (tester) async {
        // Simplest possible gesture-pipeline verification:
        // one guide point at centre, one pan across it.
        var covered = false;
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 400,
              height: 400,
              child: TraceCanvas(
                glyph: 'A',
                onCovered: () => covered = true,
                debugGuidePoints: const [Offset(200, 200)],
              ),
            ),
          ),
        );
        await tester.pump();

        final topLeft = tester.getTopLeft(find.byType(TraceCanvas));
        // Pan from (190, 200) → (210, 200) in global coords.
        // The 20 px move exceeds kTouchSlop (18), triggers onPanStart at
        // (190, 200) local, which is within tolerance 28 of guide (200, 200).
        final gesture = await tester.startGesture(
          Offset(topLeft.dx + 190, topLeft.dy + 200),
        );
        await tester.pump();
        await gesture.moveTo(
          Offset(topLeft.dx + 210, topLeft.dy + 200),
        );
        await tester.pump();
        await gesture.up();
        await tester.pump();

        expect(covered, isTrue,
            reason: 'single guide point at (200,200) should be hit by pan '
                'starting at (190,200)');
      },
    );

    testWidgets(
      'debugGuidePoints: partial drag stays below 85 %; full sweep fires onCovered',
      (tester) async {
        // Build a 24×24 grid of guide points covering the 400×400 widget.
        // Spacing: 400/24 ≈ 16.7 px; first centre at 400/48 ≈ 8.3 px.
        const widgetSide = 400.0;
        const gridDim = 24;
        final guidePoints = <Offset>[
          for (var row = 0; row < gridDim; row++)
            for (var col = 0; col < gridDim; col++)
              Offset(
                col * widgetSide / gridDim + widgetSide / (2 * gridDim),
                row * widgetSide / gridDim + widgetSide / (2 * gridDim),
              ),
        ];
        // 576 guide points; with tolerance=28 px and guide-point spacing≈16.7 px
        // each horizontal sweep with ≥10 intermediate move events covers all
        // columns (step width 40 px < 2×tolerance 56 px).

        var covered = false;

        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: widgetSide,
              height: widgetSide,
              child: TraceCanvas(
                glyph: 'A',
                onCovered: () => covered = true,
                debugGuidePoints: guidePoints,
              ),
            ),
          ),
        );
        await tester.pump();

        // Use the known widget dimensions rather than tester.getSize because
        // tester.getSize(find.byType(TraceCanvas)) walks up to the nearest
        // RenderBox ancestor and can return the full test-screen size.
        final topLeft = tester.getTopLeft(find.byType(TraceCanvas));

        // Helper: simulate a dense horizontal sweep using TestGesture so that
        // intermediate move events are fired every ~40 px (< 2×tolerance=56 px),
        // ensuring all guide-point columns along the row are covered.
        Future<void> sweepRow(double globalY) async {
          const steps = 10;
          final x0 = topLeft.dx + 1.0;
          final x1 = topLeft.dx + widgetSide - 1.0;
          final gesture = await tester.startGesture(Offset(x0, globalY));
          await tester.pump();
          for (var step = 1; step <= steps; step++) {
            await gesture.moveTo(
              Offset(x0 + (x1 - x0) * step / steps, globalY),
            );
            await tester.pump();
          }
          await gesture.up();
          await tester.pump();
        }

        // 9 sweeps evenly spaced across the 400 px widget height.
        // Step spacing ≈ 400/9 = 44.4 px; each sweep covers ±28 px → rows
        // within 28 px of the sweep y are all marked covered within that sweep.
        const totalSweeps = 9;
        const partialSweeps = 3; // top ~33 % → ~8 of 24 rows → ~33 % coverage

        final ys = List<double>.generate(
          totalSweeps,
          (i) => topLeft.dy + widgetSide * (2 * i + 1) / (totalSweeps * 2),
        );

            // Minimal sanity: one guide point at widget centre → any drag near
        // it fires onCovered.  Tests that scorer is initialised and gesture
        // pipeline works before exercising the full-grid case below.

        // ── Partial (top third): must NOT reach 85 % ─────────────────────
        for (var i = 0; i < partialSweeps; i++) {
          await sweepRow(ys[i]);
        }
        expect(covered, isFalse,
            reason: 'top-third drag must not reach the 85 % threshold');

        // ── Remaining sweeps: drives coverage to 100 % → fires onCovered ─────
        for (var i = partialSweeps; i < totalSweeps; i++) {
          await sweepRow(ys[i]);
          // ignore: avoid_print
          print('After sweep $i (y=${ys[i].toStringAsFixed(1)}): covered=$covered');
          if (covered) break;
        }
        expect(covered, isTrue,
            reason: 'full-area sweep must cross the 85 % threshold and fire '
                'onCovered exactly once');
      },
    );
  });
}
