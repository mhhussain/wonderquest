import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/audio/tts_service.dart';

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

      test('stop does not call tts', () async {
        fakeTts.resetCalls();
        await ttsService.stop();

        expect(fakeTts.calls, isEmpty);
      });
    });
  });
}
