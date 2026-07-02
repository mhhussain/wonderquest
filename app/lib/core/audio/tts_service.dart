import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wonder_quest/core/save_controller.dart';

/// Abstract interface for text-to-speech backend.
/// Wrap FlutterTts behind this so tests can provide a fake.
abstract class TtsBackend {
  /// Get list of available voices.
  /// Returns a list of maps with 'locale' and 'name' keys.
  Future<dynamic> getVoices();

  /// Set the language/locale for speech.
  Future<void> setLanguage(String locale);

  /// Set the speech rate (typically 0.0 to 2.0).
  Future<void> setSpeechRate(double rate);

  /// Set the pitch (typically 0.5 to 2.0).
  Future<void> setPitch(double pitch);

  /// Speak the text.
  Future<dynamic> speak(String text);

  /// Stop speaking.
  Future<void> stop();
}

/// Concrete implementation of TtsBackend wrapping FlutterTts.
class FlutterTtsBackend implements TtsBackend {
  final FlutterTts _tts;

  FlutterTtsBackend(this._tts);

  @override
  Future<dynamic> getVoices() => _tts.getVoices;

  @override
  Future<void> setLanguage(String locale) => _tts.setLanguage(locale);

  @override
  Future<void> setSpeechRate(double rate) => _tts.setSpeechRate(rate);

  @override
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);

  @override
  Future<dynamic> speak(String text) => _tts.speak(text);

  @override
  Future<void> stop() => _tts.stop();
}

/// Text-to-speech service for Wonder Quest.
/// Respects the global soundOn toggle and provides convenience methods
/// for English phonics and Arabic letter speech.
class TtsService {
  final TtsBackend _tts;
  final bool Function() _soundOn;

  /// Cache of available voices (enumerated once for speakArabic).
  List<Map<String, String>>? _voiceCache;

  TtsService(
    this._tts, {
    required bool Function() soundOn,
  }) : _soundOn = soundOn;

  /// Speak text with optional rate and pitch customization.
  ///
  /// No-op if soundOn() returns false.
  /// Default rate: 0.45, default pitch: 1.1
  Future<void> speak(
    String text, {
    double rate = 0.45,
    double pitch = 1.1,
  }) async {
    if (!_soundOn()) return;

    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    await _tts.speak(text);
  }

  /// Speak a letter and word in phonics style: "B… buh… Bat!"
  ///
  /// No-op if soundOn() returns false.
  Future<void> sayPhonics(String letter, String word) async {
    if (!_soundOn()) return;

    // Construct phonics string: letter, letter sound, word
    // Example: "B… buh… Bat!"
    final text = '$letter… ${letter.toLowerCase()}uh… $word!';
    await speak(text);
  }

  /// Speak Arabic text using an ar-* voice if available.
  ///
  /// If no Arabic voice is found, speaks [fallbackTransliteration] in English instead.
  /// No-op if soundOn() returns false.
  /// Voices are enumerated and cached on first call.
  Future<void> speakArabic(String arabic, String fallbackTransliteration) async {
    if (!_soundOn()) return;

    // Enumerate and cache voices if not already done
    if (_voiceCache == null) {
      final voicesResult = await _tts.getVoices();
      if (voicesResult is List) {
        _voiceCache = voicesResult
            .whereType<Map>()
            .map((v) {
              final mapData = Map<String, dynamic>.from(v);
              return mapData.cast<String, String>();
            })
            .toList();
      } else {
        _voiceCache = [];
      }
    }

    // Find first ar-* voice
    final arVoice = _voiceCache!.firstWhere(
      (v) => (v['locale'] ?? '').toLowerCase().startsWith('ar'),
      orElse: () => {},
    );

    if (arVoice.isEmpty) {
      // No Arabic voice found, speak English fallback
      await _tts.setLanguage('en-US');
      await speak(fallbackTransliteration);
    } else {
      // Found Arabic voice, use it
      final locale = arVoice['locale']!;
      await _tts.setLanguage(locale);
      await speak(arabic);
    }
  }

  /// Stop speaking.
  Future<void> stop() async {
    if (!_soundOn()) return;
    await _tts.stop();
  }
}

/// Provider for TtsService.
/// Automatically wires up the real FlutterTts backend and reads soundOn from SaveController.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final saveController = ref.read(saveControllerProvider);

  // Get soundOn from the current save data
  bool getSoundOn() {
    if (saveController.hasValue) {
      return saveController.requireValue.soundOn;
    }
    // Default to true if save data not yet loaded
    return true;
  }

  final flutterTts = FlutterTts();
  final backend = FlutterTtsBackend(flutterTts);
  return TtsService(backend, soundOn: getSoundOn);
});
