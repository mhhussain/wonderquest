import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/app.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('app_widget_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Builds [WonderQuestApp] inside a [ProviderScope] that supplies a temp-dir
  /// [SaveFileStore]. Required because [PlayMinuteTicker] reads
  /// [saveControllerProvider] from the widget tree.
  Widget buildApp() => ProviderScope(
        overrides: [
          saveStoreProvider.overrideWithValue(SaveFileStore(tempDir)),
        ],
        child: const WonderQuestApp(),
      );

  testWidgets('app boots and renders the expedition map', (tester) async {
    await tester.pumpWidget(buildApp());
    // ExpeditionMapScreen is the new home: the My Stuff button is always visible
    // on the first synchronous frame even before save data loads.
    expect(find.byKey(const Key('my-stuff-btn')), findsOneWidget);
  });

  testWidgets('expedition map shows the first land card (Letter Adventure)',
      (tester) async {
    await tester.pumpWidget(buildApp());
    // The letter land card is always in the first visible row of the grid.
    expect(find.byKey(const Key('land-card-letter')), findsOneWidget);
  });
}
