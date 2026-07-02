import 'package:flutter/material.dart';

/// v1 renders emoji strings; v2 swaps to illustration assets by changing
/// ONLY this class (return an Image widget instead). Never bypass it.
class Art {
  // Mapping of semantic keys to emoji
  static const Map<String, String> _emojiMap = {
    'rexy': '🦖',
    'egg': '🥚',
    'star': '⭐',
    'streak': '🔥',
    'lock': '🔒',
    'parent': '👪',
    'sound-on': '🔊',
    'sound-off': '🔇',
    'map': '🗺',
    'play': '▶',
    // Land icons (one per expedition-map land)
    'land-letter': '🔤',
    'land-hoorof': '🐪',
    'land-number': '🔢',
    'land-math': '➕',
    'land-animal': '🦁',
    'land-world': '🌍',
    'land-find': '🔍',
    'land-dino': '🦕',
    'land-earth': '⛅',
    'land-maze': '🌀',
    'land-trace': '✏️',
    'land-pattern': '🔺',
    'land-reading': '📖',
    // Collections UI
    'bag': '🎒',
    'sparkle': '✨',
    // Dino roster (each hatchable dinosaur)
    'dino-bronto': '🦕',
    'dino-rexy-jr': '🦖',
    'dino-stego': '🦴',
    'dino-tricera': '🐲',
    'dino-ptera': '🐉',
    'dino-raptor': '🦎',
  };

  /// Mascot key for the Rexy dinosaur
  static const mascot = 'rexy';

  /// Returns the emoji string for a given key.
  /// Known keys map to their emoji values. Unknown keys that are already emoji
  /// are passed through as-is, allowing content pools to store emoji directly.
  static String emoji(String key) {
    // Check if it's a known semantic key
    if (_emojiMap.containsKey(key)) {
      return _emojiMap[key]!;
    }

    // Passthrough: if the key looks like it could be an emoji, return as-is
    // This allows emoji stored directly in content to be rendered
    return key;
  }

  /// Returns a Text widget displaying the emoji for the given key.
  /// v1 uses Text with emoji; v2 can swap to Image widgets by changing
  /// only the implementation of this method.
  static Widget glyph(String key, {double size = 48}) {
    final emojiString = emoji(key);
    return Text(
      emojiString,
      style: TextStyle(
        fontSize: size,
      ),
    );
  }
}
