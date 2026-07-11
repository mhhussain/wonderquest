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
    } on FormatException {
      // Invalid JSON format - data corruption
      await _quarantine(file);

      final newProfileId = const Uuid().v4();
      return SaveData.initial(profileId: newProfileId);
    } on TypeError {
      // Wrong JSON shape (e.g., list instead of map) - data corruption
      await _quarantine(file);

      final newProfileId = const Uuid().v4();
      return SaveData.initial(profileId: newProfileId);
    }
    // FileSystemException from readAsString will propagate
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

  /// Quarantine a corrupted save file by renaming it to .corrupt.json.
  Future<void> _quarantine(File file) async {
    final corruptFile = File(_corruptPath);
    await file.rename(corruptFile.path);
  }
}
