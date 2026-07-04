import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/arabic_letters.dart';
import '../../../core/audio/tts_service.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';

// ---------------------------------------------------------------------------
// Pure helper functions (exported for tests)
// ---------------------------------------------------------------------------

/// The 8 game-type IDs used to track Arabic letter interactions.
const kHrfGameIds = [
  'hrf-learn',
  'hrf-trace',
  'hrf-hear',
  'hrf-memory',
  'hrf-find',
  'hrf-build',
  'hrf-pop',
  'hrf-safari',
];

/// Computes the `arabic` progress-to value (0–100) from the save levels map.
///
/// A letter counts toward progress when it has been interacted with in ≥ 3
/// distinct Hoorof game types.
///
/// Formula: `n / 28 × 100` rounded to the nearest integer, clamped to 0–100.
int arabicProgressTo(Map<String, List<bool>> levels) {
  var n = 0;
  for (var i = 0; i < kArabicLetters.length; i++) {
    var count = 0;
    for (final id in kHrfGameIds) {
      final lst = levels[id];
      if (lst != null && i < lst.length && lst[i]) count++;
    }
    if (count >= 3) n++;
  }
  return (n * 100 / kArabicLetters.length).round().clamp(0, 100);
}

/// Returns the confusable family members for glyph [g], excluding [g] itself.
///
/// Uses [kArabicConfusableFamilies] as the source. If [g] has no family, falls
/// back to all other letters.
List<String> hrfFamily(String g) {
  for (final fam in kArabicConfusableFamilies) {
    if (fam.contains(g)) {
      return fam.where((x) => x != g).toList();
    }
  }
  return kArabicLetters.map((l) => l.g).where((x) => x != g).toList();
}

/// Human-readable label for a dots code (e.g. `'2a'` → `'2 dots above'`).
String dotLabel(String d) {
  return switch (d) {
    '1a' => '1 dot above',
    '2a' => '2 dots above',
    '3a' => '3 dots above',
    '1b' => '1 dot below',
    '2b' => '2 dots below',
    '0' => 'no dots',
    _ => d,
  };
}

// ---------------------------------------------------------------------------
// ClusterPicker — shared by Learn and Trace games
// ---------------------------------------------------------------------------

/// Shows a 3×3 grid of cluster tiles; the user picks a letter group.
///
/// Speaks the title on mount. Arabic glyph text uses [NotoNaskhArabic] font
/// and RTL text direction; all labels/titles are English (LTR).
class ClusterPicker extends ConsumerWidget {
  const ClusterPicker({
    super.key,
    required this.title,
    required this.emoji,
    required this.color,
    required this.onPick,
    required this.onExit,
  });

  final String title;
  final String emoji;
  final Color color;

  /// Called with the letter list for the chosen cluster.
  final void Function(List<String> letters) onPick;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: onExit,
        ),
        title: Text(
          '$emoji $title',
          style: WqTheme.headingStyle(20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pick a letter group',
                style: WqTheme.body.copyWith(
                  fontSize: 16,
                  color: WqColors.softInk,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.6,
          children: List.generate(kArabicClusters.length, (idx) {
            final cluster = kArabicClusters[idx];
            return GestureDetector(
              onTap: () {
                ref
                    .read(ttsServiceProvider)
                    .speak(title, rate: 0.85)
                    .ignore();
                onPick(cluster);
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x20000000),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cluster.join('  '),
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Group ${idx + 1}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Arabic text style helper
// ---------------------------------------------------------------------------

/// Large Arabic glyph text style using [NotoNaskhArabic] font.
TextStyle arabicGlyphStyle(double size, {Color color = WqColors.ink}) =>
    TextStyle(
      fontFamily: 'NotoNaskhArabic',
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w700,
    );
