import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'core/save_controller.dart';
import 'core/persistence/save_file.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  final dir = await getApplicationDocumentsDirectory();
  runApp(ProviderScope(
    overrides: [
      saveStoreProvider.overrideWithValue(SaveFileStore(dir)),
    ],
    child: const WonderQuestApp(),
  ));
}
