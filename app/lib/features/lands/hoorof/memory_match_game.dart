import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/arabic_letters.dart';
import '../../../core/audio/sfx_service.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/save_controller.dart';
import '../../../domain/reward.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/reward_modal.dart';
import 'hoorof_utils.dart';

// ---------------------------------------------------------------------------
// Card model
// ---------------------------------------------------------------------------

@immutable
class _Card {
  const _Card({required this.id, required this.glyph});

  final int id;
  final String glyph;
}

// ---------------------------------------------------------------------------
// Memory card widget
// ---------------------------------------------------------------------------

/// A single face-down/face-up memory card with a flip animation.
///
/// The parent drives `faceUp` externally. When `faceUp` changes,
/// [didUpdateWidget] triggers [AnimationController.forward] or
/// [AnimationController.reverse].
class _MemoryCardWidget extends StatefulWidget {
  const _MemoryCardWidget({
    super.key,
    required this.glyph,
    required this.faceUp,
    required this.matched,
    required this.onTap,
  });

  final String glyph;
  final bool faceUp;
  final bool matched;
  final VoidCallback onTap;

  @override
  State<_MemoryCardWidget> createState() => _MemoryCardWidgetState();
}

class _MemoryCardWidgetState extends State<_MemoryCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: widget.faceUp ? 1.0 : 0.0,
    );
    _rotation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_MemoryCardWidget old) {
    super.didUpdateWidget(old);
    if (widget.faceUp != old.faceUp) {
      if (widget.faceUp) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: widget.key,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (context, child) {
          final angle = _rotation.value;
          final showFront = angle > math.pi / 2;

          final matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          final cardContent = showFront
              ? Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _FaceUp(
                    glyph: widget.glyph,
                    matched: widget.matched,
                  ),
                )
              : const _FaceDown();

          return Transform(
            transform: matrix,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.matched
                      ? WqColors.yellow
                      : WqColors.lines,
                  width: widget.matched ? 3 : 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: cardContent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FaceDown extends StatelessWidget {
  const _FaceDown();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: WqColors.grape,
      child: Center(
        child: Text(
          '✦',
          style: TextStyle(
            fontSize: 36,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _FaceUp extends StatelessWidget {
  const _FaceUp({required this.glyph, required this.matched});

  final String glyph;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: matched
          ? WqColors.yellow.withValues(alpha: 0.15)
          : WqColors.backgroundAlt,
      child: Center(
        child: Text(
          glyph,
          textDirection: TextDirection.rtl,
          style: arabicGlyphStyle(56),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MemoryMatchScreen
// ---------------------------------------------------------------------------

/// Hoorof — Game 4: Match the Letters.
///
/// 4 pairs (8 face-down cards) of Arabic letter glyphs.  The user taps to
/// reveal cards; matching pairs stay face-up.  All matched → completion.
class MemoryMatchScreen extends ConsumerStatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  ConsumerState<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends ConsumerState<MemoryMatchScreen> {
  static const _kPairs = 4;

  late List<_Card> _deck;
  late List<ArabicLetter> _pairLetters;

  final Set<int> _flippedIds = {};
  final Set<int> _matchedIds = {};
  bool _busy = false;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _initDeck();
    // Speak intro after mount.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        unawaited(
          ref.read(ttsServiceProvider).speakArabic(
            'جِد الحَرْفَيْنِ المُتَشابِهَيْن!',
            'Find the matching letters!',
          ),
        );
      }
    });
  }

  void _initDeck() {
    final rng = math.Random();
    final pool = List<ArabicLetter>.from(kArabicLetters)..shuffle(rng);
    _pairLetters = pool.take(_kPairs).toList();
    final glyphs = _pairLetters.map((l) => l.g).toList();
    final doubled = [...glyphs, ...glyphs];
    doubled.shuffle(rng);
    _deck = doubled
        .asMap()
        .entries
        .map((e) => _Card(id: e.key, glyph: e.value))
        .toList();
    _flippedIds.clear();
    _matchedIds.clear();
    _busy = false;
    _completing = false;
  }

  // ---------------------------------------------------------------------------
  // Tap handling
  // ---------------------------------------------------------------------------

  Future<void> _onTap(_Card card) async {
    if (_busy ||
        _flippedIds.contains(card.id) ||
        _matchedIds.contains(card.id)) {
      return;
    }

    final letter = kArabicLetters.firstWhere((l) => l.g == card.glyph);
    unawaited(
      ref.read(ttsServiceProvider).speakArabic(letter.nm, letter.tr),
    );

    setState(() => _flippedIds.add(card.id));

    if (_flippedIds.length == 2) {
      _busy = true;
      final ids = _flippedIds.toList();
      final a = _deck.firstWhere((c) => c.id == ids[0]);
      final b = _deck.firstWhere((c) => c.id == ids[1]);

      if (a.glyph == b.glyph) {
        // Match!
        await Future<void>.delayed(const Duration(milliseconds: 650));
        if (!mounted) return;
        unawaited(ref.read(sfxServiceProvider).play(Sfx.ding));
        unawaited(
          ref
              .read(ttsServiceProvider)
              .speakArabic('مُطابَقَة!', 'Match!'),
        );
        setState(() {
          _matchedIds
            ..add(a.id)
            ..add(b.id);
          _flippedIds.clear();
          _busy = false;
        });

        if (_matchedIds.length >= _kPairs * 2) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
          if (mounted) unawaited(_onComplete());
        }
      } else {
        // No match: flip back after delay.
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (mounted) {
          setState(() {
            _flippedIds.clear();
            _busy = false;
          });
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Completion
  // ---------------------------------------------------------------------------

  Future<void> _onComplete() async {
    if (_completing) return;
    _completing = true;

    for (final letter in _pairLetters) {
      final idx = kArabicLetters.indexWhere((l) => l.g == letter.g);
      if (idx >= 0) {
        await ref
            .read(saveControllerProvider.notifier)
            .markLevelDone('hrf-memory', idx, kArabicLetters.length);
      }
    }
    if (!mounted) {
      _completing = false;
      return;
    }

    final levels = ref.read(saveControllerProvider).requireValue.levels;
    final pt = arabicProgressTo(levels);

    await showRewardModal(
      context,
      ref,
      Reward(
        stars: 4,
        xp: 30,
        egg: true,
        sticker: '🧩',
        progressKey: 'arabic',
        progressTo: pt,
      ),
      onPlayAgain: () {
        if (mounted) {
          setState(_initDeck);
          _completing = false;
        }
      },
    );
    if (mounted) Navigator.of(context).pop();
    _completing = false;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('🧩 Match the Letters', style: WqTheme.headingStyle(20)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '🧩 ${_matchedIds.length ~/ 2}/$_kPairs',
                style: WqTheme.headingStyle(18).copyWith(color: WqColors.grape),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: _deck.map((card) {
              final faceUp = _flippedIds.contains(card.id) ||
                  _matchedIds.contains(card.id);
              return _MemoryCardWidget(
                key: ValueKey('mem-card-${card.id}'),
                glyph: card.glyph,
                faceUp: faceUp,
                matched: _matchedIds.contains(card.id),
                onTap: () => unawaited(_onTap(card)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
