import 'dart:io';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';

/// Handles atomic save file storage with corruption quarantine.
class SaveFileStore {
  static const _filename = 'wonderquest_save.json';
  static const _tmpSuffix = '.tmp';
  static const _corruptSuffix = '.corrupt.json';

  final Directory _dir;

  SaveFileStore(this._dir);

  /// Get the path to the save file.
  String get _savePath => '${_dir.path}/$_filename';

  /// Get the path to the temporary file.
  String get _tmpPath => '$_savePath$_tmpSuffix';

  /// Get the path to the corrupt file.
  String get _corruptPath => '${_dir.path}/${_filename.replaceAll('.json', '')}'
      '$_corruptSuffix';

  /// Load save data from file. Returns initial SaveData if file missing or corrupt.
  Future<SaveData> load() async {
    final file = File(_savePath);

    // File doesn't exist - return new initial save
    if (!file.existsSync()) {
      final newProfileId = const Uuid().v4();
      return SaveData.initial(profileId: newProfileId);
    }

    // Try to read and parse
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Apply migration if needed
      final migratedJson = _migrate(json);

      return SaveData.fromJson(migratedJson);
    } catch (e) {
      // Corruption detected - quarantine the file and return initial
      final corruptFile = File(_corruptPath);
      await file.rename(corruptFile.path);

      final newProfileId = const Uuid().v4();
      return SaveData.initial(profileId: newProfileId);
    }
  }

  /// Save data to file atomically. Writes to .tmp first, then renames.
  Future<void> save(SaveData data) async {
    final json = data.toJson();
    final content = jsonEncode(json);

    final tmpFile = File(_tmpPath);
    final saveFile = File(_savePath);

    // Write to temporary file
    await tmpFile.writeAsString(content);

    // Rename temporary file to real file (atomic on APFS)
    await tmpFile.rename(saveFile.path);
  }

  /// Migration hook for future schema versions. Currently returns map unchanged.
  Map<String, dynamic> _migrate(Map<String, dynamic> json) {
    // TODO: Handle schemaVersion > 1 migrations here
    return json;
  }
}
