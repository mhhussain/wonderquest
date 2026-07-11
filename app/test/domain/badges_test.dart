import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/progress_keys.dart';
import 'package:wonder_quest/domain/badges.dart';

void main() {
  SaveData base() => SaveData.initial(profileId: 'test');

  group('earnedBadgeIds', () {
    test('fresh save earns no badges', () {
      expect(earnedBadgeIds(base()), isEmpty);
    });

    test('streak badges at 3 and 7 days', () {
      expect(earnedBadgeIds(base().copyWith(streak: 2)), isEmpty);
      expect(earnedBadgeIds(base().copyWith(streak: 3)), contains('streak-3'));
      final week = earnedBadgeIds(base().copyWith(streak: 7));
      expect(week, containsAll(['streak-3', 'streak-7']));
    });

    test('star milestones at 25 and 100', () {
      expect(earnedBadgeIds(base().copyWith(stars: 24)), isEmpty);
      expect(earnedBadgeIds(base().copyWith(stars: 25)), contains('stars-25'));
      expect(
          earnedBadgeIds(base().copyWith(stars: 100)), contains('stars-100'));
    });

    test('level milestones at 5 and 10', () {
      expect(earnedBadgeIds(base().copyWith(level: 5)), contains('level-5'));
      expect(earnedBadgeIds(base().copyWith(level: 10)),
          containsAll(['level-5', 'level-10']));
    });

    test('per-module mastery at $kMasteryBadgePct%', () {
      final s = base().copyWith(progress: {
        ...base().progress,
        ProgressKeys.math: kMasteryBadgePct,
      });
      expect(earnedBadgeIds(s), contains('mastery-math'));
      expect(earnedBadgeIds(s), isNot(contains('mastery-letter')));
    });

    test('GSRP Ready when readiness reaches 80', () {
      final s = base().copyWith(
        progress: {for (final k in ProgressKeys.all) k: 80},
      );
      expect(earnedBadgeIds(s), contains('gsrp-ready'));
    });
  });

  test('badge ids are unique and every module has a mastery badge', () {
    final ids = kAllBadges.map((b) => b.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final key in ProgressKeys.all) {
      expect(ids, contains('mastery-$key'));
    }
  });

  test('readinessPercent is the mean of the 7 progress keys', () {
    expect(readinessPercent({for (final k in ProgressKeys.all) k: 50}), 50);
    expect(readinessPercent({}), 0);
  });
}
