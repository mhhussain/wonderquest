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
  /// [SaveFileStore]. Required because [PlayMinuteTicker] (added in Task 13)
  /// reads [saveControllerProvider] from the widget tree.
  Widget buildApp() => ProviderScope(
        overrides: [
          saveStoreProvider.overrideWithValue(SaveFileStore(tempDir)),
        ],
        child: const WonderQuestApp(),
      );

  testWidgets('app boots and shows Wonder Quest title', (tester) async {
    await tester.pumpWidget(buildApp());
    expect(find.text('Wonder Quest'), findsOneWidget);
  });

  testWidgets('placeholder home shows TTS spike debug button', (tester) async {
    await tester.pumpWidget(buildApp());
    expect(find.text('Arabic TTS Spike (Task 3)'), findsOneWidget);
  });
}
