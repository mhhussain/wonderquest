import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/math_content.dart';
import '../../../core/audio/sfx_service.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/save_controller.dart';
import '../../../domain/reward.dart';
import '../../../theme/wq_colors.dart';
import '../../../theme/wq_theme.dart';
import '../../../widgets/level_select.dart';
import '../../../widgets/reward_modal.dart';
import 'station_theatrics.dart';

// ---------------------------------------------------------------------------
// Pre-computed pools — one per station, deterministic seed
// ---------------------------------------------------------------------------

final _kZooPool = genMathProblems(
  MathType.count, 'zoo', 80, Random('math_zoo'.hashCode));
final _kSnackPool = genMathProblems(
  MathType.add, 'snack', 80, Random('math_snack'.hashCode));
final _kGemsPool = genMathProblems(
  MathType.add, 'gems', 80, Random('math_gems'.hashCode));
final _kEggsPool = genMathProblems(
  MathType.sub, 'eggs', 80, Random('math_eggs'.hashCode));
final _kCookiePool = genMathProblems(
  MathType.sub, 'cookie', 80, Random('math_cookie'.hashCode));
final _kMorlesPool = genMathProblems(
  MathType.compare, 'morles', 80, Random('math_morles'.hashCode));

List<MathProblem> _poolFor(MathStation station) {
  switch (station.id) {
    case 'zoo':    return _kZooPool;
    case 'snack':  return _kSnackPool;
    case 'gems':   return _kGemsPool;
    case 'eggs':   return _kEggsPool;
    case 'cookie': return _kCookiePool;
    case 'morles': return _kMorlesPool;
    default:
      throw ArgumentError('Unknown station id: ${station.id}');
  }
}

Reward _rewardFor(MathStation station) {
  switch (station.id) {
    case 'zoo':
      return const Reward(
        stars: 3, xp: 28, egg: true,
        progressKey: 'math', progressTo: 50,
      );
    case 'snack':
      return const Reward(
        stars: 3, xp: 30, egg: true,
        progressKey: 'math', progressTo: 60,
      );
    case 'gems':
      return const Reward(
        stars: 3, xp: 30, egg: true,
        progressKey: 'math', progressTo: 60,
      );
    case 'eggs':
      return const Reward(
        stars: 3, xp: 30, egg: true,
        progressKey: 'math', progressTo: 55,
      );
    case 'cookie':
      return const Reward(
        stars: 3, xp: 30, egg: true,
        progressKey: 'math', progressTo: 55,
      );
    case 'morles':
      return const Reward(
        stars: 3, xp: 26, sticker: '⚖️',
        progressKey: 'math', progressTo: 50,
      );
    default:
      return const Reward(
        stars: 3, xp: 26,
        progressKey: 'math', progressTo: 50,
      );
  }
}

// ---------------------------------------------------------------------------
// MathStationScreen — manages LevelSelect → GameDeck flow
// ---------------------------------------------------------------------------

/// Screen for a single math station.
///
/// Shows [LevelSelect] with 4 game slots, then [GameDeck] with 10 questions
/// per game. Progress key is `math_<station.id>`.
///
/// For the compare station, [_compareWantMore] alternates between true/false
/// after each correct answer so the prompt toggles between "MORE" and "FEWER".
class MathStationScreen extends ConsumerStatefulWidget {
  const MathStationScreen({super.key, required this.station});

  final MathStation station;

  @override
  ConsumerState<MathStationScreen> createState() => _MathStationScreenState();
}

class _MathStationScreenState extends ConsumerState<MathStationScreen> {
  int? _gameIndex;

  /// Toggled after each correct compare answer so the "MORE"/"FEWER" prompt
  /// alternates across questions within the same game.
  bool _compareWantMore = true;

  String get _typeId => 'math_${widget.station.id}';

  void _onPlay(int index) => setState(() => _gameIndex = index);

  Future<void> _onComplete() async {
    final gi = _gameIndex!;
    await ref
        .read(saveControllerProvider.notifier)
        .markLevelDone(_typeId, gi, 4);
    if (!mounted) return;
    await showRewardModal(
      context,
      ref,
      _rewardFor(widget.station),
      onPlayAgain: () {
        if (mounted) setState(() => _gameIndex = null);
      },
    );
    if (mounted) setState(() => _gameIndex = null);
  }

  Widget _buildQuestion(
    BuildContext context,
    MathProblem problem,
    VoidCallback advance,
  ) {
    final wantMore = _compareWantMore;
    return MathStationQuestion(
      key: ValueKey('math-q-${problem.a}-${problem.b}-${problem.answer}-${problem.obj}-$wantMore'),
      problem: problem,
      station: widget.station,
      wantMore: wantMore,
      advance: () {
        // Toggle the compare prompt before advancing so the rebuilt
        // question widget gets the flipped wantMore value.
        if (widget.station.type == MathType.compare) {
          setState(() => _compareWantMore = !_compareWantMore);
        }
        advance();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WqColors.background,
      appBar: AppBar(
        backgroundColor: WqColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WqColors.ink),
          onPressed: () {
            if (_gameIndex != null) {
              setState(() => _gameIndex = null);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          '${widget.station.emoji} ${widget.station.title}',
          style: WqTheme.headingStyle(22),
        ),
      ),
      body: _gameIndex == null
          ? LevelSelect(
              typeId: _typeId,
              games: 4,
              title: widget.station.title,
              color: widget.station.color,
              onPlay: _onPlay,
            )
          : GameDeck<MathProblem>(
              typeId: _typeId,
              gameIndex: _gameIndex!,
              pool: _poolFor(widget.station),
              games: 4,
              perGame: 10,
              questionBuilder: _buildQuestion,
              onComplete: _onComplete,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// MathStationQuestion — shared question runner
// ---------------------------------------------------------------------------

/// Renders one math question for any of the 6 stations.
///
/// Objects-first pedagogy:
/// - **Count / Add**: child taps every object (all groups) → choices unlock.
/// - **Sub**: objects shown with some gone/animated; choices always active.
/// - **Compare**: child taps a panel (no number choices).
///
/// The equation (`2+2=4`) is revealed **only after a correct answer**.
class MathStationQuestion extends ConsumerStatefulWidget {
  const MathStationQuestion({
    super.key,
    required this.problem,
    required this.station,
    required this.advance,
    this.wantMore = true,
  });

  final MathProblem problem;
  final MathStation station;
  final VoidCallback advance;

  /// Only relevant for the compare station.
  /// `true` = "Which has MORE?"; `false` = "Which has FEWER?".
  final bool wantMore;

  @override
  ConsumerState<MathStationQuestion> createState() =>
      _MathStationQuestionState();
}

class _MathStationQuestionState extends ConsumerState<MathStationQuestion> {
  // ── Tap-to-count state (count / add) ────────────────────────────────────────
  final List<int> _counted = [];

  // ── Choice state (count / add / sub) ────────────────────────────────────────
  int? _picked;
  bool _correct = false;

  // ── Compare state (morles) ──────────────────────────────────────────────────
  bool? _pickedA; // null = not answered; true = A; false = B
  bool? _compareCorrect;

  bool get _solved => _correct || _compareCorrect == true;

  /// Number of taps required before choices unlock (count/add only).
  int get _required {
    switch (widget.station.type) {
      case MathType.count:
        return widget.problem.a;
      case MathType.add:
        return widget.problem.a + widget.problem.b;
      case MathType.sub:
      case MathType.compare:
        return 0; // no gate
    }
  }

  bool get _allCounted =>
      widget.station.type == MathType.sub ||
      widget.station.type == MathType.compare ||
      _counted.length >= _required;

  // ── Handlers ────────────────────────────────────────────────────────────────

  void _tapObject(int id) {
    if (_counted.contains(id)) return;
    final next = List<int>.from(_counted)..add(id);
    setState(() {
      _counted
        ..clear()
        ..addAll(next);
    });
    unawaited(
      ref.read(ttsServiceProvider).speak('${next.length}', rate: 0.9, pitch: 1.2),
    );
  }

  Future<void> _choose(int n) async {
    if (!_allCounted || _correct) return;

    final ok = n == widget.problem.answer;
    setState(() {
      _picked = n;
      _correct = ok;
    });

    if (ok) {
      unawaited(ref.read(sfxServiceProvider).play(Sfx.ding));
      unawaited(
        ref.read(ttsServiceProvider).speak(
          '${_equationStr()}! Great job!',
          rate: 0.9,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (mounted) widget.advance();
    } else {
      unawaited(ref.read(sfxServiceProvider).play(Sfx.wrong));
      unawaited(ref.read(ttsServiceProvider).speak('Try again!', rate: 0.95));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() { _picked = null; _correct = false; });
    }
  }

  Future<void> _compareChoose(bool choseA) async {
    if (_compareCorrect != null) return;

    final aHasMore = widget.problem.answer == 1;
    // wantMore=true  → correct side is the one with MORE.
    // wantMore=false → correct side is the one with FEWER.
    final bool ok = widget.wantMore
        ? (choseA == aHasMore)
        : (choseA != aHasMore);

    setState(() {
      _pickedA = choseA;
      _compareCorrect = ok;
    });

    if (ok) {
      unawaited(ref.read(sfxServiceProvider).play(Sfx.ding));
      final word = widget.wantMore ? 'more' : 'fewer';
      unawaited(
        ref.read(ttsServiceProvider).speak(
          'Yes! That group has $word.',
          rate: 0.9,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (mounted) widget.advance();
    } else {
      unawaited(ref.read(sfxServiceProvider).play(Sfx.wrong));
      unawaited(ref.read(ttsServiceProvider).speak('Try again!', rate: 0.95));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() { _pickedA = null; _compareCorrect = null; });
    }
  }

  String _equationStr() {
    final p = widget.problem;
    switch (widget.station.type) {
      case MathType.count:
        return '${p.a}';
      case MathType.add:
        return '${p.a} + ${p.b} = ${p.answer}';
      case MathType.sub:
        return '${p.a} − ${p.b} = ${p.answer}';
      case MathType.compare:
        return '';
    }
  }

  String _promptText() {
    final p = widget.problem;
    switch (widget.station.type) {
      case MathType.count:
        return 'How many ${p.obj} are in the zoo?';
      case MathType.add:
        if (widget.station.id == 'snack') {
          return 'Rex has ${p.a} ${p.obj}, give ${p.b} more! How many?';
        }
        return 'How many ${p.obj} altogether?';
      case MathType.sub:
        if (widget.station.id == 'eggs') {
          return '${p.a} eggs — ${p.b} hatched! How many left?';
        }
        return '${p.a} cookies — ${p.b} eaten! How many left?';
      case MathType.compare:
        return widget.wantMore
            ? 'Which group has MORE?'
            : 'Which group has FEWER?';
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final type = widget.station.type;
    final isCompare = type == MathType.compare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Prompt ────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            _promptText(),
            textAlign: TextAlign.center,
            style: WqTheme.headingStyle(20).copyWith(
              color: isCompare
                  ? (widget.wantMore ? WqColors.green : WqColors.coral)
                  : WqColors.softInk,
              fontWeight: isCompare ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),

        // ── Scene (theatric) ──────────────────────────────────────────────────
        Expanded(
          flex: 3,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildScene(),
              ),
            ),
          ),
        ),

        // ── Tap-hint (count/add only, before gate is satisfied) ───────────────
        if ((type == MathType.count || type == MathType.add) && !_allCounted)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Tap each one to count!',
              textAlign: TextAlign.center,
              style: WqTheme.headingStyle(16)
                  .copyWith(color: widget.station.color),
            ),
          ),

        // ── Number choice buttons (count / add / sub) ─────────────────────────
        if (!isCompare)
          Expanded(
            flex: 2,
            child: Center(
              child: IgnorePointer(
                ignoring: !_allCounted,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: widget.problem.choices.map((n) {
                    final isPicked = _picked == n;
                    final Color bg;
                    if (!_allCounted) {
                      bg = WqColors.backgroundAlt;
                    } else if (isPicked && _correct) {
                      bg = WqColors.green;
                    } else if (isPicked && !_correct) {
                      bg = WqColors.coral;
                    } else {
                      bg = WqColors.backgroundAlt;
                    }

                    return GestureDetector(
                      key: Key('math-choice-$n'),
                      onTap: () => _choose(n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _allCounted
                                ? widget.station.color
                                : WqColors.lines,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$n',
                            style: TextStyle(
                              fontFamily: 'Baloo2',
                              fontWeight: FontWeight.w800,
                              fontSize: 52,
                              color: isPicked
                                  ? Colors.white
                                  : (_allCounted
                                      ? widget.station.color
                                      : WqColors.softInk),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildScene() {
    final p = widget.problem;
    switch (widget.station.id) {
      case 'zoo':
        return ZooCountScene(
          problem: p,
          counted: _counted,
          onTap: _tapObject,
          solved: _solved,
        );
      case 'snack':
        return DinoSnackScene(
          problem: p,
          counted: _counted,
          onTap: _tapObject,
          solved: _solved,
        );
      case 'gems':
        return TreasureHuntScene(
          problem: p,
          counted: _counted,
          onTap: _tapObject,
          solved: _solved,
        );
      case 'eggs':
        return LostDinoEggsScene(
          problem: p,
          solved: _solved,
        );
      case 'cookie':
        return CookieMathScene(
          problem: p,
          solved: _solved,
        );
      case 'morles':
        return MoreOrLessScene(
          problem: p,
          wantMore: widget.wantMore,
          onChoose: (choseA) => unawaited(_compareChoose(choseA)),
          correct: _compareCorrect,
          pickedA: _pickedA,
        );
      default:
        return const Text('Unknown station');
    }
  }
}
