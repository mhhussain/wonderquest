import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';
import 'package:wonder_quest/theme/wq_colors.dart';
import 'package:wonder_quest/widgets/canvas_scaler.dart';

void main() {
  // ── CanvasScaler ───────────────────────────────────────────────────────────

  group('CanvasScaler', () {
    testWidgets(
        'inner canvas is exactly 1194×834 at a 2000×1000 logical surface',
        (tester) async {
      tester.view.physicalSize = const Size(2000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: CanvasScaler(child: SizedBox.expand())),
      );

      // The fixed-size SizedBox inside CanvasScaler reports exactly 1194×834.
      final canvasFinder = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 1194 && w.height == 834,
      );
      expect(canvasFinder, findsOneWidget);
      final renderBox = tester.renderObject<RenderBox>(canvasFinder);
      expect(renderBox.size, const Size(1194, 834));

      // Letterbox background is filled with WqColors.ink.
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == WqColors.ink,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'inner canvas is exactly 1194×834 at a 1194×900 surface (extra height)',
        (tester) async {
      // This surface is taller than the 16:11 canvas ratio — there should be
      // letterboxing top+bottom but the inner canvas still measures 1194×834.
      tester.view.physicalSize = const Size(1194, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: CanvasScaler(child: SizedBox.expand())),
      );

      final canvasFinder = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 1194 && w.height == 834,
      );
      expect(canvasFinder, findsOneWidget);
      final renderBox = tester.renderObject<RenderBox>(canvasFinder);
      expect(renderBox.size, const Size(1194, 834));
    });
  });

  // ── PlayMinuteTicker ───────────────────────────────────────────────────────

  group('PlayMinuteTicker', () {
    late Directory tempDir;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('play_minute_ticker_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    testWidgets(
        'minutesToday increments once for each elapsed minute',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            saveStoreProvider.overrideWithValue(SaveFileStore(tempDir)),
          ],
          child: const MaterialApp(
            home: PlayMinuteTicker(child: SizedBox.shrink()),
          ),
        ),
      );

      // Let SaveController.build() (async file load) complete.
      await tester.pump();

      // Advance 2 minutes — periodic timer fires at t=1 min and t=2 min.
      await tester.pump(const Duration(minutes: 2));

      // Drain the async chain inside SaveController._update().
      await tester.pump();
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PlayMinuteTicker)),
      );
      final data = container.read(saveControllerProvider).requireValue;
      expect(data.minutesToday, 2);
    });
  });
}
