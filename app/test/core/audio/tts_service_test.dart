import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/audio/tts_service.dart';
import 'package:wonder_quest/core/persistence/save_file.dart';
import 'package:wonder_quest/core/save_controller.dart';

/// Fake implementation of TtsBackend for testing.
class FakeTtsBackend implements TtsBackend {
  final List<(String method, dynamic args)> calls = [];

  // Simulate voice database
  List<Map<String, String>>? voiceOverride;

  @override
  Future<dynamic> getVoices() async {
    calls.add(('getVoices', null));
    return voiceOverride ?? <Map<String, String>>[
      {'locale': 'en-US', 'name': 'English'},
      {'locale': 'ar-SA', 'name': 'Arabic Saudi'},
    ];
  }

  @override
  Future<void> setLanguage(String locale) async {
    calls.add(('setLanguage', locale));
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    calls.add(('setSpeechRate', rate));
  }

  @override
  Future<void> setPitch(double pitch) async {
    calls.add(('setPitch', pitch));
  }

  @override
  Future<dynamic> speak(String text) async {
    calls.add(('speak', text));
    return 1; // Mock success
  }

  @override
  Future<void> stop() async {
    calls.add(('stop', null));
  }

  /// Clear call history
  void resetCalls() {
    calls.clear();
  }
}

void main() {
  group('TtsService', () {
    late FakeTtsBackend fakeTts;
    late TtsService ttsService;

    setUp(() {
      fakeTts = FakeTtsBackend();
    });

    group('when soundOn is true', () {
      setUp(() {
        ttsService = TtsService(fakeTts, soundOn: () => true);
      });

      test('speak calls tts with default rate and pitch', () async {
        await ttsService.speak('Hello world');

        expect(fakeTts.calls.length, greaterThan(0));
        expect(
          fakeTts.calls,
          contains(('speak', 'Hello world')),
        );
      });

      test('speak calls setSpeechRate with custom rate', () async {
        await ttsService.speak('Hello', rate: 0.75);

        expect(
          fakeTts.calls,
          contains(('setSpeechRate', 0.75)),
        );
      });

      test('speak calls setPitch with custom pitch', () async {
        await ttsService.speak('Hello', pitch: 1.5);

        expect(
          fakeTts.calls,
          contains(('setPitch', 1.5)),
        );
      });

      test('sayPhonics speaks text containing both letter and word', () async {
        await ttsService.sayPhonics('B', 'Bat');

        // Should find a speak call with both 'B' and 'Bat' in the text
        final speakCalls = fakeTts.calls
            .where((call) => call.$1 == 'speak')
            .cast<(String, dynamic)>()
            .toList();

        expect(speakCalls, isNotEmpty);
        final spokenText = speakCalls.last.$2 as String;
        expect(spokenText.toUpperCase(), contains('B'));
        expect(spokenText, contains('Bat'));
      });

      test('speakArabic with ar voice speaks the Arabic text', () async {
        await ttsService.speakArabic('ب', 'Baa');

        // Should find setLanguage with ar locale and a speak call
        final setLanguageCalls = fakeTts.calls
            .where((call) => call.$1 == 'setLanguage')
            .cast<(String, dynamic)>()
            .toList();

        expect(setLanguageCalls, isNotEmpty);
        final locale = setLanguageCalls.first.$2 as String;
        expect(locale.toLowerCase(), startsWith('ar'));

        final speakCalls = fakeTts.calls
            .where((call) => call.$1 == 'speak')
            .cast<(String, dynamic)>()
            .toList();
        expect(speakCalls, isNotEmpty);
        expect(speakCalls.last.$2, 'ب');
      });

      test('speakArabic with no ar voice speaks fallback in English', () async {
        // Override voices to have no Arabic
        fakeTts.voiceOverride = [
          {'locale': 'en-US', 'name': 'English'},
          {'locale': 'es-ES', 'name': 'Spanish'},
        ];

        await ttsService.speakArabic('ب', 'Baa');

        // Should speak the fallback English text
        final speakCalls = fakeTts.calls
            .where((call) => call.$1 == 'speak')
            .cast<(String, dynamic)>()
            .toList();

        expect(speakCalls, isNotEmpty);
        expect(speakCalls.last.$2, 'Baa');
      });

      test('stop calls tts.stop()', () async {
        await ttsService.stop();

        expect(
          fakeTts.calls,
          contains(('stop', null)),
        );
      });
    });

    group('when soundOn is false', () {
      setUp(() {
        ttsService = TtsService(fakeTts, soundOn: () => false);
      });

      test('speak does not call tts', () async {
        fakeTts.resetCalls();
        await ttsService.speak('Hello world');

        expect(fakeTts.calls, isEmpty);
      });

      test('sayPhonics does not call tts', () async {
        fakeTts.resetCalls();
        await ttsService.sayPhonics('B', 'Bat');

        expect(fakeTts.calls, isEmpty);
      });

      test('speakArabic does not call tts', () async {
        fakeTts.resetCalls();
        await ttsService.speakArabic('ب', 'Baa');

        expect(fakeTts.calls, isEmpty);
      });

      test('stop calls tts.stop() unconditionally, even when soundOn is false',
          () async {
        fakeTts.resetCalls();
        await ttsService.stop();

        // stop() should call backend stop regardless of soundOn state
        // This allows stopping ongoing speech even if sound was toggled off.
        expect(
          fakeTts.calls,
          contains(('stop', null)),
        );
      });
    });

    group('ttsServiceProvider with soundOn state changes', () {
      late Directory tempDir;
      late SaveFileStore store;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('tts_service_provider_test_');
        store = SaveFileStore(tempDir);
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      /// Creates a ProviderContainer with saveStoreProvider overridden to use
      /// a temp dir, and ttsServiceProvider overridden to use a fake backend
      /// instead of the real FlutterTts.
      ProviderContainer makeContainer(FakeTtsBackend backend) {
        return ProviderContainer.test(
          overrides: [
            saveStoreProvider.overrideWithValue(store),
            // Override ttsServiceProvider to use fake backend instead of real FlutterTts
            ttsServiceProvider.overrideWith((ref) {
              bool getSoundOn() {
                final saveController = ref.read(saveControllerProvider);
                if (saveController.hasValue) {
                  return saveController.requireValue.soundOn;
                }
                return true;
              }
              return TtsService(backend, soundOn: getSoundOn);
            }),
          ],
        );
      }

      test(
          'flipping soundOn in save state changes speak gating on next call',
          () async {
        final backend = FakeTtsBackend();
        final container = makeContainer(backend);

        // Wait for SaveController to load
        await container.read(saveControllerProvider.future);

        // Initially soundOn is true (default), so speak should call tts
        backend.resetCalls();
        final service1 = container.read(ttsServiceProvider);
        await service1.speak('Hello');
        expect(
          backend.calls.where((c) => c.$1 == 'speak').length,
          greaterThan(0),
          reason: 'speak should call tts when soundOn is true',
        );

        // Toggle sound off
        await container
            .read(saveControllerProvider.notifier)
            .toggleSound();

        // On next call to the provider's soundOn callback, it should read
        // the updated soundOn=false state, so speak should not call tts
        backend.resetCalls();
        final service2 = container.read(ttsServiceProvider);
        await service2.speak('Hello again');
        expect(
          backend.calls.where((c) => c.$1 == 'speak').length,
          0,
          reason: 'speak should not call tts when soundOn is false',
        );

        // Toggle sound back on
        await container
            .read(saveControllerProvider.notifier)
            .toggleSound();

        // Now speak should call tts again
        backend.resetCalls();
        final service3 = container.read(ttsServiceProvider);
        await service3.speak('Hello once more');
        expect(
          backend.calls.where((c) => c.$1 == 'speak').length,
          greaterThan(0),
          reason: 'speak should call tts when soundOn is toggled back on',
        );
      });

      test(
          'stop() calls backend unconditionally even when soundOn is false via provider',
          () async {
        final backend = FakeTtsBackend();
        final container = makeContainer(backend);

        await container.read(saveControllerProvider.future);

        // Toggle sound off
        await container
            .read(saveControllerProvider.notifier)
            .toggleSound();

        // stop() should still call backend stop even though soundOn is false
        backend.resetCalls();
        final service = container.read(ttsServiceProvider);
        await service.stop();

        expect(
          backend.calls,
          contains(('stop', null)),
          reason: 'stop() should call backend unconditionally',
        );
      });
    });
  });
}
