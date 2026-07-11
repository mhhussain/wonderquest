import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../content/arabic_letters.dart';
import '../../core/art.dart';
import '../../core/progress_keys.dart';
import '../../core/persistence/save_data.dart';
import '../../core/save_controller.dart';
import '../../domain/badges.dart';
import '../../theme/wq_colors.dart';
import '../../theme/wq_theme.dart';
import 'settings_screen.dart';

export '../../domain/badges.dart' show readinessPercent;

// ---------------------------------------------------------------------------
// Pure helpers (exported for tests)
// ---------------------------------------------------------------------------

const _kAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

/// Display order + labels for the skill progress bars. `keys` with two
/// entries are averaged (Animals & World).
const kSkillBars = <({String label, List<String> keys, Color color})>[
  (label: 'Letters', keys: [ProgressKeys.letter], color: WqColors.orange),
  (label: 'Arabic', keys: [ProgressKeys.arabic], color: WqColors.coral),
  (label: 'Numbers', keys: [ProgressKeys.number], color: WqColors.teal),
  (label: 'Math', keys: [ProgressKeys.math], color: WqColors.sky),
  (label: 'Animals & World', keys: [ProgressKeys.animal, ProgressKeys.world], color: WqColors.grape),
  (label: 'Finding & Focus', keys: [ProgressKeys.find], color: WqColors.green),
];

/// Letter pairs young readers commonly confuse; flagged in coach notes when
/// both members of a pair are in `lettersLearning`.
const kConfusablePairs = [('B', 'D'), ('P', 'Q'), ('G', 'Q'), ('M', 'W')];

/// Percent value (0–100) for one skill bar (mean of its progress keys).
int skillPercent(List<String> keys, Map<String, int> progress) {
  if (keys.isEmpty) return 0;
  final sum = keys.fold<int>(0, (a, k) => a + (progress[k] ?? 0));
  return (sum / keys.length).round().clamp(0, 100);
}

/// Mean tracing accuracy (0–100) across all `trace:*` skill stats, or null
/// when no tracing has been recorded yet.
int? traceAccuracyPercent(Map<String, List<int>> skillStats) {
  var attempts = 0;
  var points = 0;
  skillStats.forEach((key, value) {
    if (key.startsWith(SkillKeys.tracePrefix) && value.length >= 2) {
      attempts += value[0];
      points += value[1];
    }
  });
  if (attempts == 0) return null;
  return (points / attempts).round().clamp(0, 100);
}

/// Plain-text weekly report for the "Email weekly report" CTA.
String weeklyReportBody(SaveData save) {
  final buffer = StringBuffer()
    ..writeln('Wonder Quest — weekly report for ${save.name}')
    ..writeln()
    ..writeln('Level ${save.level} · ${save.stars} stars · '
        '${save.streak}-day streak')
    ..writeln('This week: ${save.week.fold<int>(0, (a, b) => a + b)} min '
        '(today: ${save.minutesToday} min)')
    ..writeln()
    ..writeln('Skills:');
  for (final bar in kSkillBars) {
    buffer.writeln('- ${bar.label}: ${skillPercent(bar.keys, save.progress)}%');
  }
  final trace = traceAccuracyPercent(save.skillStats);
  if (trace != null) buffer.writeln('- Tracing accuracy: $trace%');
  buffer
    ..writeln()
    ..writeln('GSRP readiness: ${readinessPercent(save.progress)}%');
  return buffer.toString();
}

// readinessPercent now lives in domain/badges.dart (shared with the badge
// derivations); re-exported here for existing callers/tests.

/// How many of the 28 Arabic letters count as mastered, derived from the
/// `progress.arabic` percentage (the separate-Arabic-metric decision).
int arabicMasteredCount(int arabicPct) =>
    (arabicPct.clamp(0, 100) * kArabicLetters.length / 100).round();

/// Rule-derived coach notes (no ML): practice ideas for the two lowest skill
/// bars, a flag per confusable pair fully in `lettersLearning`, and a win
/// line for the strongest skill.
List<String> coachNotes({
  required Map<String, int> progress,
  required List<String> lettersLearning,
}) {
  final notes = <String>[];

  final ranked = [
    for (final bar in kSkillBars)
      (label: bar.label, pct: skillPercent(bar.keys, progress)),
  ]..sort((a, b) => a.pct.compareTo(b.pct));

  for (final low in ranked.take(2)) {
    notes.add('⚠️ Practice idea: ${low.label} — a few short rounds this week');
  }

  final learning = lettersLearning.map((l) => l.toUpperCase()).toSet();
  for (final (a, b) in kConfusablePairs) {
    if (learning.contains(a) && learning.contains(b)) {
      notes.add(
          '⚠️ Watch ${a.toLowerCase()} / ${b.toLowerCase()} — often mixed up');
    }
  }

  final top = ranked.last;
  if (top.pct > 0) {
    notes.add('✅ ${top.label} is the strongest skill right now — nice win!');
  }
  return notes;
}

// ---------------------------------------------------------------------------
// DashboardScreen
// ---------------------------------------------------------------------------

/// Parent dashboard shown after the multiplication gate passes.
///
/// Calmer styling than the kid screens: white cards on
/// [WqColors.backgroundAlt], smaller type. All metrics derive from [SaveData]
/// (summary stats only — no event log exists, by decision). The AppBar
/// "Settings" action navigates to [SettingsScreen].
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final save = ref.watch(saveControllerProvider).asData?.value;

    return Scaffold(
      backgroundColor: WqColors.backgroundAlt,
      appBar: AppBar(
        backgroundColor: WqColors.backgroundAlt,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: WqColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Parent Dashboard', style: WqTheme.headingStyle(20)),
        actions: [
          IconButton(
            key: const Key('dashboard-settings'),
            icon: const Icon(Icons.settings_outlined, color: WqColors.ink),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: save == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                _TopStatsRow(save: save),
                const SizedBox(height: 14),
                _AlphabetCard(save: save),
                const SizedBox(height: 14),
                _ArabicCard(
                    arabicPct: save.progress[ProgressKeys.arabic] ?? 0),
                const SizedBox(height: 14),
                _WeekCard(week: save.week),
                const SizedBox(height: 14),
                _SessionHistoryCard(save: save),
                const SizedBox(height: 14),
                _SkillBarsCard(save: save),
                const SizedBox(height: 14),
                _CoachNotesCard(save: save),
                const SizedBox(height: 14),
                _ReadinessCard(save: save),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card scaffold
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WqColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: WqTheme.headingStyle(15).copyWith(color: WqColors.softInk),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Top stats row
// ---------------------------------------------------------------------------

class _TopStatsRow extends StatelessWidget {
  const _TopStatsRow({required this.save});

  final SaveData save;

  @override
  Widget build(BuildContext context) {
    Widget stat(String title, String big, String sub) {
      return Expanded(
        child: _Card(
          title: title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(big, style: WqTheme.headingStyle(26)),
              const SizedBox(height: 2),
              Text(
                sub,
                style: WqTheme.body
                    .copyWith(fontSize: 12, color: WqColors.softInk),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        stat('${Art.emoji('timer')} Today', '${save.minutesToday} min',
            'Goal: 20 min'),
        const SizedBox(width: 12),
        stat('${Art.emoji('streak')} Streak', '${save.streak} days',
            'Keep it going!'),
        const SizedBox(width: 12),
        stat('${Art.emoji('land-letter')} Letters',
            '${save.lettersMastered.length}/26',
            '${save.lettersLearning.length} in progress'),
        const SizedBox(width: 12),
        stat('${Art.emoji('land-number')} Numbers',
            '${save.numbersMastered.length}/20', 'Mastered'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Alphabet mastery grid
// ---------------------------------------------------------------------------

class _AlphabetCard extends StatelessWidget {
  const _AlphabetCard({required this.save});

  final SaveData save;

  @override
  Widget build(BuildContext context) {
    final mastered =
        save.lettersMastered.map((l) => l.toUpperCase()).toSet();
    final learning =
        save.lettersLearning.map((l) => l.toUpperCase()).toSet();

    return _Card(
      title: 'Letter recognition — A to Z',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final l in _kAlphabet.split(''))
                _MasteryTile(
                  key: ValueKey('alpha-$l'),
                  label: l,
                  color: mastered.contains(l)
                      ? WqColors.green
                      : learning.contains(l)
                          ? WqColors.yellow
                          : WqColors.lines,
                  inkOnLight: !mastered.contains(l) && !learning.contains(l),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const _MasteryLegend(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Arabic mastery grid
// ---------------------------------------------------------------------------

class _ArabicCard extends StatelessWidget {
  const _ArabicCard({required this.arabicPct});

  final int arabicPct;

  @override
  Widget build(BuildContext context) {
    final masteredCount = arabicMasteredCount(arabicPct);

    return _Card(
      title: 'Arabic letters — $masteredCount/${kArabicLetters.length}',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < kArabicLetters.length; i++)
            _MasteryTile(
              key: ValueKey('arabic-$i'),
              label: kArabicLetters[i].g,
              arabic: true,
              color: i < masteredCount ? WqColors.green : WqColors.lines,
              inkOnLight: i >= masteredCount,
            ),
        ],
      ),
    );
  }
}

class _MasteryTile extends StatelessWidget {
  const _MasteryTile({
    super.key,
    required this.label,
    required this.color,
    required this.inkOnLight,
    this.arabic = false,
  });

  final String label;
  final Color color;
  final bool inkOnLight;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
        style: TextStyle(
          fontFamily: arabic ? 'NotoNaskhArabic' : 'Baloo2',
          fontSize: arabic ? 16 : 15,
          fontWeight: FontWeight.w700,
          color: inkOnLight ? WqColors.softInk : Colors.white,
        ),
      ),
    );
  }
}

class _MasteryLegend extends StatelessWidget {
  const _MasteryLegend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style:
                WqTheme.body.copyWith(fontSize: 12, color: WqColors.softInk),
          ),
        ],
      );
    }

    return Row(
      children: [
        item(WqColors.green, 'Mastered'),
        const SizedBox(width: 14),
        item(WqColors.yellow, 'Learning'),
        const SizedBox(width: 14),
        item(WqColors.lines, 'Not started'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. This week — bar chart
// ---------------------------------------------------------------------------

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week});

  final List<int> week;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final total = week.fold<int>(0, (a, b) => a + b);

    return _Card(
      title: 'This week — $total min total',
      child: Column(
        children: [
          SizedBox(
            height: 90,
            child: CustomPaint(
              key: const Key('week-bars'),
              size: Size.infinite,
              painter: _WeekBarsPainter(week),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final d in _dayLabels)
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: WqTheme.body
                        .copyWith(fontSize: 12, color: WqColors.softInk),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekBarsPainter extends CustomPainter {
  _WeekBarsPainter(this.week);

  final List<int> week;

  @override
  void paint(Canvas canvas, Size size) {
    final maxDay = max(week.isEmpty ? 1 : week.reduce(max), 1);
    final slot = size.width / 7;
    final barW = slot * 0.5;

    for (var i = 0; i < 7 && i < week.length; i++) {
      final frac = week[i] / maxDay;
      final h = max(4.0, frac * size.height);
      final left = i * slot + (slot - barW) / 2;
      final paint = Paint()
        ..color = i == 6 ? WqColors.orange : WqColors.teal;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - h, barW, h),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WeekBarsPainter oldDelegate) =>
      !listEquals(oldDelegate.week, week);

  static bool listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ---------------------------------------------------------------------------
// 5. Skill progress bars
// ---------------------------------------------------------------------------

class _SkillBarsCard extends StatelessWidget {
  const _SkillBarsCard({required this.save});

  final SaveData save;

  @override
  Widget build(BuildContext context) {
    final trace = traceAccuracyPercent(save.skillStats);
    return _Card(
      title: 'Skill progress',
      child: Column(
        children: [
          for (final bar in kSkillBars)
            _SkillBarRow(
              label: bar.label,
              pct: skillPercent(bar.keys, save.progress),
              color: bar.color,
            ),
          // Tracing accuracy from skillStats (spec: Tracing skill bar).
          _SkillBarRow(
            key: const Key('skill-bar-tracing'),
            label: 'Tracing',
            pct: trace ?? 0,
            color: WqColors.pink,
            pctLabel: trace == null ? '—' : '$trace%',
          ),
        ],
      ),
    );
  }
}

class _SkillBarRow extends StatelessWidget {
  const _SkillBarRow({
    super.key,
    required this.label,
    required this.pct,
    required this.color,
    this.pctLabel,
  });

  final String label;
  final int pct;
  final Color color;

  /// Overrides the right-hand percent text (e.g. '—' when no data yet).
  final String? pctLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: WqTheme.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Stack(
                  children: [
                    Container(color: WqColors.lines),
                    FractionallySizedBox(
                      widthFactor: pct / 100,
                      child: Container(color: color),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              pctLabel ?? '$pct%',
              textAlign: TextAlign.right,
              style: WqTheme.body.copyWith(
                fontSize: 13,
                color: WqColors.softInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Coach notes
// ---------------------------------------------------------------------------

class _CoachNotesCard extends StatelessWidget {
  const _CoachNotesCard({required this.save});

  final SaveData save;

  @override
  Widget build(BuildContext context) {
    final notes = coachNotes(
      progress: save.progress,
      lettersLearning: save.lettersLearning,
    );

    return _Card(
      title: 'Coach notes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final note in notes)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: note.startsWith('✅')
                    ? const Color(0xFFEAF7DC)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                note,
                style: WqTheme.body.copyWith(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7. Readiness ring
// ---------------------------------------------------------------------------

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.save});

  final SaveData save;

  Future<void> _emailReport() async {
    final uri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': 'Wonder Quest weekly report — ${save.name}',
        'body': weeklyReportBody(save),
      },
    );
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final pct = readinessPercent(save.progress);

    return _Card(
      title: 'GSRP Readiness',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: CustomPaint(
                  key: const Key('readiness-ring'),
                  painter: _RingPainter(pct),
                  child: Center(
                    child: Text('$pct%', style: WqTheme.headingStyle(20)),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  pct >= 80
                      ? 'GSRP Ready'
                      : 'Overall progress across all 7 skills. '
                          '“GSRP Ready” at 80%.',
                  key: const Key('readiness-label'),
                  style: WqTheme.body.copyWith(
                    fontSize: 14,
                    fontWeight: pct >= 80 ? FontWeight.w800 : FontWeight.w400,
                    color: pct >= 80 ? WqColors.green : WqColors.softInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: const Key('email-weekly-report'),
              onPressed: _emailReport,
              icon: const Icon(Icons.mail_outline, size: 18),
              label: const Text('Email weekly report'),
              style: OutlinedButton.styleFrom(
                foregroundColor: WqColors.ink,
                side: const BorderSide(color: WqColors.lines, width: 2),
                minimumSize: const Size(64, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 8. Session history
// ---------------------------------------------------------------------------

/// Recent daily play sessions (from [SaveData.sessions]) plus completed game
/// counts per land ([SaveData.landPlays]).
class _SessionHistoryCard extends StatelessWidget {
  const _SessionHistoryCard({required this.save});

  final SaveData save;

  static const _landLabels = {
    ProgressKeys.letter: 'Letters',
    ProgressKeys.arabic: 'Arabic',
    ProgressKeys.number: 'Numbers',
    ProgressKeys.math: 'Math',
    ProgressKeys.animal: 'Animals',
    ProgressKeys.world: 'World',
    ProgressKeys.find: 'Finding',
  };

  @override
  Widget build(BuildContext context) {
    final recent = save.sessions.reversed.take(7).toList();
    final plays = [
      for (final e in _landLabels.entries)
        if ((save.landPlays[e.key] ?? 0) > 0)
          '${e.value} ${save.landPlays[e.key]}',
    ];

    return _Card(
      title: 'Session history',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recent.isEmpty)
            Text(
              'No sessions recorded yet — history appears after a few '
              'minutes of play.',
              style: WqTheme.body.copyWith(
                fontSize: 13,
                color: WqColors.softInk,
              ),
            )
          else
            for (final session in recent)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        session.date,
                        style: WqTheme.body.copyWith(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${session.minutes} min',
                      style: WqTheme.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          if (plays.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Games finished per land: ${plays.join(' · ')}',
              style: WqTheme.body.copyWith(
                fontSize: 12,
                color: WqColors.softInk,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.pct);

  final int pct;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 5;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = WqColors.lines;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = pct >= 80 ? WqColors.green : WqColors.teal;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * pct / 100,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.pct != pct;
}
