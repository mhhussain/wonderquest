import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wonder_quest/core/save_controller.dart';

/// The set of sound effects bundled with Wonder Quest.
///
/// Each variant corresponds to a WAV file in `assets/sfx/`.
enum Sfx {
  pop,
  ding,
  wrong,
  fanfare,
  whaleCall,
}

extension _SfxAsset on Sfx {
  /// Asset path relative to the Flutter `assets/` root (i.e. what
  /// [AssetSource] expects).
  String get assetPath {
    switch (this) {
      case Sfx.pop:
        return 'sfx/pop.wav';
      case Sfx.ding:
        return 'sfx/ding.wav';
      case Sfx.wrong:
        return 'sfx/wrong.wav';
      case Sfx.fanfare:
        return 'sfx/fanfare.wav';
      case Sfx.whaleCall:
        return 'sfx/whale_call.wav';
    }
  }
}

/// Plays one-shot sound effects from bundled WAV assets.
///
/// All playback is gated on the global sound toggle (`soundOn`).
/// Create via [sfxServiceProvider] to get the properly wired instance.
class SfxService {
  final AudioPlayer _player;
  final bool Function() _soundOn;

  SfxService(this._player, {required bool Function() soundOn})
      : _soundOn = soundOn;

  /// Base frequency (Hz) the [Sfx.whaleCall] asset is synthesised at
  /// (see `tool/gen_sfx.dart`).
  static const double whaleCallBaseHz = 80;

  /// Play [sfx]. No-op when `soundOn` is false.
  Future<void> play(Sfx sfx) async {
    if (!_soundOn()) return;
    await _player.setPlaybackRate(1.0);
    await _player.play(AssetSource(sfx.assetPath));
  }

  /// Play the whale-call asset pitched to [baseFreqHz], giving each whale a
  /// distinct voice. The 80 Hz reference is resampled via playback rate,
  /// clamped to the platform-safe 0.5–2.0 range.
  Future<void> playWhaleCall(double baseFreqHz) async {
    if (!_soundOn()) return;
    await _player.setPlaybackRate(whaleCallRate(baseFreqHz));
    await _player.play(AssetSource(Sfx.whaleCall.assetPath));
  }

  /// Playback rate that pitches the 80 Hz whale-call asset to [baseFreqHz],
  /// clamped to 0.5–2.0.
  static double whaleCallRate(double baseFreqHz) =>
      (baseFreqHz / whaleCallBaseHz).clamp(0.5, 2.0);
}

/// Provider for [SfxService].
///
/// Wires up a real [AudioPlayer] and reads `soundOn` lazily from
/// [saveControllerProvider] so that the global sound toggle is respected
/// on every call (same pattern as [ttsServiceProvider]).
final sfxServiceProvider = Provider<SfxService>((ref) {
  bool getSoundOn() {
    final saveController = ref.read(saveControllerProvider);
    if (saveController.hasValue) {
      return saveController.requireValue.soundOn;
    }
    // Default to true while save data is loading.
    return true;
  }

  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return SfxService(player, soundOn: getSoundOn);
});
