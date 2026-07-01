/// Debug-only spike screen for evaluating Arabic TTS quality on iPad.
///
/// This file is **throwaway** — it will be deleted before Wonder Quest v1
/// ships. It exists solely to answer the go/no-go question:
///   "Is device TTS good enough for Hoorof Arabic letter audio, or do we
///    need to bundle pre-recorded audio clips?"
///
/// How to use:
///   1. Launch on a real iPad (see wiki/requirements/arabic-tts-spike-result.md).
///   2. Enable airplane mode to test offline availability.
///   3. Tap "List ar-* Voices" and note which voices appear.
///   4. Tap the Speak buttons and judge quality / latency.
///   5. Record findings in the wiki result doc.
library;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../theme/wq_colors.dart';
import '../../theme/wq_theme.dart';

class TtsSpikeScreen extends StatefulWidget {
  const TtsSpikeScreen({super.key});

  @override
  State<TtsSpikeScreen> createState() => _TtsSpikeScreenState();
}

class _TtsSpikeScreenState extends State<TtsSpikeScreen> {
  final FlutterTts _tts = FlutterTts();
  final List<String> _log = [];
  bool _busy = false;

  // ── helpers ──────────────────────────────────────────────────────────────

  void _addLog(String message) {
    if (!mounted) return;
    setState(() => _log.insert(0, message));
  }

  /// Returns the first ar-* locale found in [getVoices], or null.
  Future<String?> _findArLocale() async {
    final voices = await _tts.getVoices as List<dynamic>?;
    if (voices == null || voices.isEmpty) return null;
    final arVoice = voices.whereType<Map>().firstWhere(
          (v) => (v['locale'] as String? ?? '').toLowerCase().startsWith('ar'),
          orElse: () => {},
        );
    return arVoice['locale'] as String?;
  }

  // ── button handlers ───────────────────────────────────────────────────────

  Future<void> _listVoices() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final voices = await _tts.getVoices as List<dynamic>?;
      if (voices == null || voices.isEmpty) {
        _addLog('[voices] getVoices returned empty.');
        return;
      }
      final arVoices = voices
          .whereType<Map>()
          .where(
            (v) => (v['locale'] as String? ?? '').toLowerCase().startsWith('ar'),
          )
          .toList();
      _addLog('[voices] Total: ${voices.length}  Arabic (ar-*): ${arVoices.length}');
      if (arVoices.isEmpty) {
        final sample = voices.take(5).map((v) => v.toString()).join('\n  ');
        _addLog('[voices] No ar-* voices. Sample:\n  $sample');
      } else {
        for (final v in arVoices) {
          _addLog('[voice] name=${v['name']}  locale=${v['locale']}');
        }
      }
    } catch (e) {
      _addLog('[error] listVoices: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _speakArabic(String text, String label) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final locale = await _findArLocale();
      if (locale == null) {
        _addLog('[speak] No ar-* voice found — cannot speak "$label".');
        return;
      }
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(0.4);
      await _tts.setPitch(1.0);
      final result = await _tts.speak(text);
      _addLog('[speak] $label  locale=$locale  result=$result');
    } catch (e) {
      _addLog('[error] speakArabic "$label": $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _speakEnglishFallback() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      final result = await _tts.speak('Letter Baa. Duck!');
      _addLog('[speak] English fallback  result=$result');
    } catch (e) {
      _addLog('[error] speakEnglishFallback: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    await _tts.stop();
    if (mounted) setState(() => _busy = false);
    _addLog('[stop] TTS stopped.');
  }

  // ── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        title: const Text('Arabic TTS Spike (Debug)'),
        backgroundColor: WqColors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: controls ──────────────────────────────────────────────
            SizedBox(
              width: 300,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Text('Controls', style: WqTheme.headingStyle(18)),
                  const SizedBox(height: 16),
                  _SpikeButton(
                    key: const Key('btn_list_voices'),
                    label: 'List ar-* Voices',
                    color: WqColors.teal,
                    enabled: !_busy,
                    onPressed: _listVoices,
                  ),
                  const SizedBox(height: 12),
                  _SpikeButton(
                    key: const Key('btn_speak_ba'),
                    arabicGlyph: 'ب',
                    label: 'Speak ب  (Baa — letter)',
                    color: WqColors.grape,
                    enabled: !_busy,
                    onPressed: () => _speakArabic('ب', 'ب (Baa)'),
                  ),
                  const SizedBox(height: 12),
                  _SpikeButton(
                    key: const Key('btn_speak_batta'),
                    arabicGlyph: 'بَطَّة',
                    label: 'Speak بَطَّة  (Batta — Duck)',
                    color: WqColors.grape,
                    enabled: !_busy,
                    onPressed: () => _speakArabic('بَطَّة', 'بَطَّة (Duck)'),
                  ),
                  const SizedBox(height: 12),
                  _SpikeButton(
                    key: const Key('btn_speak_english'),
                    label: 'Speak English Fallback\n"Letter Baa. Duck!"',
                    color: WqColors.sky,
                    enabled: !_busy,
                    onPressed: _speakEnglishFallback,
                  ),
                  const SizedBox(height: 12),
                  _SpikeButton(
                    key: const Key('btn_stop'),
                    label: 'Stop',
                    color: WqColors.coral,
                    enabled: true,
                    onPressed: _stop,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WqColors.backgroundAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: WqColors.lines),
                    ),
                    child: Text(
                      'Test checklist:\n'
                      '① Enable airplane mode\n'
                      '② List ar-* Voices → note offline voices\n'
                      '③ Speak ب → judge letter quality\n'
                      '④ Speak بَطَّة → judge word quality\n'
                      '⑤ Record in wiki result doc',
                      style: WqTheme.body.copyWith(
                        fontSize: 13,
                        color: WqColors.softInk,
                      ),
                    ),
                  ),
                ],
                ),
              ),
            ),

            const SizedBox(width: 24),

            // ── Right: log output ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Output Log', style: WqTheme.headingStyle(18)),
                      const SizedBox(width: 12),
                      if (_busy)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      const Spacer(),
                      if (_log.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() => _log.clear()),
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: WqColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: WqColors.lines),
                      ),
                      child: _log.isEmpty
                          ? Center(
                              child: Text(
                                'Tap a button to begin.',
                                style: WqTheme.body
                                    .copyWith(color: WqColors.softInk),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _log.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 8, color: WqColors.lines),
                              itemBuilder: (_, i) => Text(
                                _log[i],
                                style: const TextStyle(
                                  fontFamily: 'NotoNaskhArabic',
                                  fontSize: 14,
                                  color: WqColors.ink,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _SpikeButton extends StatelessWidget {
  const _SpikeButton({
    super.key,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onPressed,
    this.arabicGlyph,
  });

  final String label;
  final String? arabicGlyph;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : WqColors.lines,
        foregroundColor: Colors.white,
        disabledForegroundColor: WqColors.softInk,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: enabled ? onPressed : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (arabicGlyph != null) ...[
            Text(
              arabicGlyph!,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
