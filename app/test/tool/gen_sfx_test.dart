import 'package:flutter_test/flutter_test.dart';
import '../../tool/gen_sfx.dart' as sfx;

void main() {
  group('buildWav', () {
    test('output starts with RIFF bytes', () {
      final wav = sfx.buildWav([0.5, -0.5, 0.0]);
      // WAV file must start with "RIFF" ASCII
      expect(wav[0], 0x52, reason: 'byte 0 must be R');
      expect(wav[1], 0x49, reason: 'byte 1 must be I');
      expect(wav[2], 0x46, reason: 'byte 2 must be F');
      expect(wav[3], 0x46, reason: 'byte 3 must be F');
    });

    test('data-chunk length field matches samples.length * 2', () {
      final samples = List<double>.filled(100, 0.5);
      final wav = sfx.buildWav(samples);
      // Bytes 40-43 (little-endian uint32) = SubChunk2Size = numSamples * 2
      final dataSize = wav[40] | (wav[41] << 8) | (wav[42] << 16) | (wav[43] << 24);
      expect(dataSize, samples.length * 2);
    });

    test('total wav length is 44 + samples.length * 2', () {
      final samples = List<double>.filled(50, 0.0);
      final wav = sfx.buildWav(samples);
      expect(wav.length, 44 + samples.length * 2);
    });
  });

  group('sine', () {
    test('generates 22050 samples for 1 second at 22050 Hz', () {
      final samples = sfx.sine(440, 1.0);
      expect(samples.length, 22050);
    });

    test('all samples are in range [-1.0, 1.0]', () {
      final samples = sfx.sine(440, 0.5);
      for (final s in samples) {
        expect(s, inInclusiveRange(-1.0, 1.0));
      }
    });
  });
}
