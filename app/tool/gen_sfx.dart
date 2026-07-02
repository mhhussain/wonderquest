// ignore_for_file: avoid_print
// dev-time script: generates the 6 bundled SFX WAV files.
//
// Run from the `app/` directory:
//   dart run tool/gen_sfx.dart
//
// Outputs: assets/sfx/{pop,ding,wrong,fanfare,whale_low,whale_high}.wav
// Format: 16-bit PCM mono 22 050 Hz (standard uncompressed WAV).
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Sample rate used for all generated audio.
const int kSampleRate = 22050;

/// Maximum amplitude for 16-bit PCM (2^15 − 1).
const int kMaxAmplitude = 32767;

// ──────────────────────────────────────────────────────────────────────────────
// Synth helpers
// ──────────────────────────────────────────────────────────────────────────────

/// Generate a pure sine wave at [freq] Hz lasting [seconds] seconds.
///
/// Returns samples normalised to [-1.0, 1.0].
List<double> sine(double freq, double seconds) {
  final count = (kSampleRate * seconds).round();
  return List<double>.generate(count, (i) {
    return sin(2 * pi * freq * i / kSampleRate);
  });
}

/// Apply an attack/release amplitude envelope to [samples].
///
/// [attackFrac] and [releaseFrac] are fractions of the total duration.
/// Returns a new list; [samples] is not modified.
List<double> envelope(
  List<double> samples, {
  double attackFrac = 0.1,
  double releaseFrac = 0.2,
}) {
  final n = samples.length;
  if (n == 0) return [];
  final attackEnd = (n * attackFrac).round();
  final releaseStart = n - (n * releaseFrac).round();
  return List<double>.generate(n, (i) {
    double gain;
    if (attackEnd > 0 && i < attackEnd) {
      gain = i / attackEnd;
    } else if (releaseStart < n && i >= releaseStart) {
      gain = (n - i) / (n - releaseStart);
    } else {
      gain = 1.0;
    }
    return samples[i] * gain;
  });
}

/// Generate samples with LFO vibrato.
///
/// [base]     – base frequency in Hz
/// [lfoHz]    – LFO rate in Hz
/// [depth]    – vibrato depth in semitones
/// [seconds]  – duration in seconds
///
/// Uses a phase-accumulator so the instantaneous frequency is accurate at each
/// sample. Returns samples in [-1.0, 1.0].
List<double> vibrato(
  double base,
  double lfoHz,
  double depth,
  double seconds,
) {
  final count = (kSampleRate * seconds).round();
  var phase = 0.0;
  return List<double>.generate(count, (i) {
    final lfo = sin(2 * pi * lfoHz * i / kSampleRate);
    // Semitone scaling: freq = base * 2^(lfo*depth/12)
    final freq = base * pow(2.0, lfo * depth / 12.0);
    phase += 2 * pi * freq / kSampleRate;
    return sin(phase);
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// WAV builder
// ──────────────────────────────────────────────────────────────────────────────

/// Encode [samples] (in range [-1.0, 1.0]) as a 16-bit PCM mono 22 050 Hz WAV.
///
/// Returns the raw bytes ready to write to a `.wav` file.
Uint8List buildWav(List<double> samples) {
  final dataBytes = samples.length * 2; // 16-bit = 2 bytes per sample
  final header = ByteData(44);

  // RIFF chunk
  _writeAscii(header, 0, 'RIFF');
  header.setUint32(4, 36 + dataBytes, Endian.little); // ChunkSize
  _writeAscii(header, 8, 'WAVE');

  // fmt sub-chunk
  _writeAscii(header, 12, 'fmt ');
  header.setUint32(16, 16, Endian.little); // Subchunk1Size (PCM)
  header.setUint16(20, 1, Endian.little); // AudioFormat = PCM
  header.setUint16(22, 1, Endian.little); // NumChannels = 1 (mono)
  header.setUint32(24, kSampleRate, Endian.little); // SampleRate
  header.setUint32(28, kSampleRate * 2, Endian.little); // ByteRate
  header.setUint16(32, 2, Endian.little); // BlockAlign
  header.setUint16(34, 16, Endian.little); // BitsPerSample

  // data sub-chunk
  _writeAscii(header, 36, 'data');
  header.setUint32(40, dataBytes, Endian.little); // Subchunk2Size

  // Interleave header + sample data into a single buffer
  final pcm = ByteData(dataBytes);
  for (var i = 0; i < samples.length; i++) {
    final s = samples[i].clamp(-1.0, 1.0);
    final word = (s * kMaxAmplitude).round().clamp(-32768, 32767);
    pcm.setInt16(i * 2, word, Endian.little);
  }

  final out = Uint8List(44 + dataBytes);
  out.setAll(0, header.buffer.asUint8List());
  out.setAll(44, pcm.buffer.asUint8List());
  return out;
}

void _writeAscii(ByteData bd, int offset, String s) {
  for (var i = 0; i < s.length; i++) {
    bd.setUint8(offset + i, s.codeUnitAt(i));
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// main — generate all 6 SFX files
// ──────────────────────────────────────────────────────────────────────────────

void main() {
  final outDir = Directory('assets/sfx');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  void write(String name, List<double> samples) {
    final bytes = buildWav(samples);
    final path = '${outDir.path}/$name.wav';
    File(path).writeAsBytesSync(bytes);
    print('  $path  (${bytes.length} bytes)');
  }

  print('Generating SFX WAVs → ${outDir.path}/');

  // ── pop: 600 → 900 Hz linear chirp, 0.1 s ────────────────────────────────
  {
    const dur = 0.1;
    const f0 = 600.0, f1 = 900.0;
    final n = (kSampleRate * dur).round();
    // Phase = integral of 2π·freq dt  → 2π·(f0·t + (f1−f0)/(2T)·t²)
    final samples = List<double>.generate(n, (i) {
      final t = i / kSampleRate;
      return sin(2 * pi * (f0 * t + (f1 - f0) / (2 * dur) * t * t));
    });
    write('pop', envelope(samples, attackFrac: 0.05, releaseFrac: 0.3));
  }

  // ── ding: 880 Hz pure tone, 0.25 s ───────────────────────────────────────
  write('ding', envelope(sine(880, 0.25), attackFrac: 0.05, releaseFrac: 0.4));

  // ── wrong: 220 Hz pure tone, 0.2 s ───────────────────────────────────────
  write('wrong', envelope(sine(220, 0.2), attackFrac: 0.05, releaseFrac: 0.3));

  // ── fanfare: 523 / 659 / 784 Hz arpeggio, 0.6 s (3 × 0.2 s) ─────────────
  {
    final seg1 = envelope(sine(523, 0.2), attackFrac: 0.05, releaseFrac: 0.3);
    final seg2 = envelope(sine(659, 0.2), attackFrac: 0.05, releaseFrac: 0.3);
    final seg3 = envelope(sine(784, 0.2), attackFrac: 0.05, releaseFrac: 0.3);
    write('fanfare', [...seg1, ...seg2, ...seg3]);
  }

  // ── whale_low: 80 Hz base, 4 Hz LFO, 2 semitones depth, 2 s ─────────────
  write(
    'whale_low',
    envelope(vibrato(80, 4, 2.0, 2.0), attackFrac: 0.1, releaseFrac: 0.2),
  );

  // ── whale_high: 500 Hz base, 6 Hz LFO, 2 semitones depth, 1.5 s ─────────
  write(
    'whale_high',
    envelope(vibrato(500, 6, 2.0, 1.5), attackFrac: 0.1, releaseFrac: 0.2),
  );

  print('Done — 6 files generated.');
}
