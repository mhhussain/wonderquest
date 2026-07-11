
import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/daily_rollover.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/progress_keys.dart';
import 'package:wonder_quest/domain/reward.dart';
import 'package:wonder_quest/domain/reward_engine.dart';
import 'package:wonder_quest/domain/trace_scorer.dart';
import 'package:wonder_quest/features/parent/dashboard_screen.dart';

void main() {
  SaveData base() => SaveData.initial(profileId: 'test');

  group('landPlays (per-land session totals)', () {
    test('applyReward with a progressKey counts one play for that land', () {
      var s = base();
      const r = Reward(progressKey: ProgressKeys.math, progressTo: 10);
      s = applyReward(s, r);
      s = applyReward(s, r);
      expect(s.landPlays[ProgressKeys.math], 2);
    });

    test('applyReward without a progressKey counts nothing', () {
      final s = applyReward(base(), const Reward(stars: 1));
      expect(s.landPlays, isEmpty);
    });
  });

  group('sessions (daily play history)', () {
    test('addPlayMinute creates and increments today\'s entry', () {
      final now = DateTime(2026, 7, 11, 10);
      var s = addPlayMinute(base(), now);
      s = addPlayMinute(s, now);
      expect(s.sessions, hasLength(1));
      expect(s.sessions.single.date, '2026-07-11');
      expect(s.sessions.single.minutes, 2);
    });

    test('a new day appends a new entry', () {
      var s = addPlayMinute(base(), DateTime(2026, 7, 10));
      s = addPlayMinute(s, DateTime(2026, 7, 11));
      expect(s.sessions.map((e) => e.date), ['2026-07-10', '2026-07-11']);
    });

    test('history is capped at maxSessionHistory entries', () {
      var s = base();
      for (var day = 1; day <= SaveData.maxSessionHistory + 5; day++) {
        s = addPlayMinute(s, DateTime(2026, 1, 1).add(Duration(days: day)));
      }
      expect(s.sessions, hasLength(SaveData.maxSessionHistory));
      // Oldest entries trimmed, newest kept.
      expect(s.sessions.last.date, '2026-02-05');
    });
  });

  group('skillStats persistence', () {
    test('new analytics fields survive a JSON round-trip', () {
      final s = base().copyWith(
        skillStats: {
          'letter:B': [4, 300],
          'trace:B': [2, 180],
        },
        landPlays: {ProgressKeys.letter: 3},
        sessions: [const SessionEntry(date: '2026-07-11', minutes: 12)],
      );
      final restored = SaveData.fromJson(s.toJson());
      expect(restored, s);
    });

    test('missing analytics keys default to empty (old saves)', () {
      final json = base().toJson()
        ..remove('skillStats')
        ..remove('landPlays')
        ..remove('sessions');
      final restored = SaveData.fromJson(json);
      expect(restored.skillStats, isEmpty);
      expect(restored.landPlays, isEmpty);
      expect(restored.sessions, isEmpty);
    });
  });

  group('TraceScorer.accuracy', () {
    test('all stroke points on the glyph → accuracy 1.0', () {
      final scorer = TraceScorer(guidePoints: const [Offset(10, 10)]);
      scorer.addStrokePoint(const Offset(12, 12));
      expect(scorer.accuracy, 1.0);
    });

    test('half the stroke points off the glyph → accuracy 0.5', () {
      final scorer = TraceScorer(guidePoints: const [Offset(10, 10)]);
      scorer.addStrokePoint(const Offset(10, 10)); // hit
      scorer.addStrokePoint(const Offset(300, 300)); // miss
      expect(scorer.accuracy, 0.5);
    });

    test('no stroke points → degenerate accuracy 1.0', () {
      final scorer = TraceScorer(guidePoints: const [Offset(10, 10)]);
      expect(scorer.accuracy, 1.0);
    });
  });

  group('traceAccuracyPercent', () {
    test('null when no trace stats recorded', () {
      expect(traceAccuracyPercent({}), isNull);
      expect(traceAccuracyPercent({'letter:B': [3, 300]}), isNull);
    });

    test('mean percent across all trace:* keys', () {
      expect(
        traceAccuracyPercent({
          'trace:B': [1, 90],
          'trace:ب': [1, 70],
        }),
        80,
      );
    });
  });

  test('weeklyReportBody includes name, skills, and readiness', () {
    final body = weeklyReportBody(base().copyWith(name: 'Hassan'));
    expect(body, contains('Hassan'));
    expect(body, contains('Letters'));
    expect(body, contains('GSRP readiness'));
  });
}
