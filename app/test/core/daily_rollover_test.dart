import 'package:flutter_test/flutter_test.dart';
import 'package:wonder_quest/core/persistence/save_data.dart';
import 'package:wonder_quest/core/daily_rollover.dart';

void main() {
  group('applyDailyRollover', () {
    late SaveData initial;

    setUp(() {
      initial = SaveData.initial(profileId: 'test-profile');
    });

    test('same day no-op: lastPlayedDate equals today', () {
      final today = DateTime(2026, 7, 1);
      final initial2 = initial.copyWith(
        lastPlayedDate: '2026-07-01',
        streak: 5,
        minutesToday: 30,
        week: [10, 20, 30, 40, 50, 60, 70],
      );

      final result = applyDailyRollover(initial2, today);

      expect(result.lastPlayedDate, '2026-07-01');
      expect(result.streak, 5);
      expect(result.minutesToday, 30);
      expect(result.week, [10, 20, 30, 40, 50, 60, 70]);
    });

    test('consecutive day streak increment: yesterday to today', () {
      final today = DateTime(2026, 7, 1); // Tuesday
      final initial2 = initial.copyWith(
        lastPlayedDate: '2026-06-30', // Monday
        streak: 5,
        minutesToday: 45,
      );

      final result = applyDailyRollover(initial2, today);

      expect(result.lastPlayedDate, '2026-07-01');
      expect(result.streak, 6);
      expect(result.minutesToday, 0);
    });

    test('gap resets streak to 1: older date to today', () {
      final today = DateTime(2026, 7, 1); // Tuesday
      final initial2 = initial.copyWith(
        lastPlayedDate: '2026-06-28', // Saturday (3 days ago)
        streak: 10,
        minutesToday: 50,
      );

      final result = applyDailyRollover(initial2, today);

      expect(result.lastPlayedDate, '2026-07-01');
      expect(result.streak, 1);
      expect(result.minutesToday, 0);
    });

    test('empty lastPlayedDate sets streak to 1', () {
      final today = DateTime(2026, 7, 1);
      final initial2 = initial.copyWith(
        lastPlayedDate: '',
        streak: 0,
        minutesToday: 0,
      );

      final result = applyDailyRollover(initial2, today);

      expect(result.lastPlayedDate, '2026-07-01');
      expect(result.streak, 1);
      expect(result.minutesToday, 0);
    });

    test('week array zeroed on ISO week change', () {
      // Monday, Jun 24 (week 26) to Wednesday, Jul 1 (week 27)
      final today = DateTime(2026, 7, 1); // Wednesday of week 27
      final initial2 = initial.copyWith(
        lastPlayedDate: '2026-06-24', // Wednesday of week 26
        week: [10, 20, 30, 40, 50, 60, 70],
        streak: 5,
      );

      final result = applyDailyRollover(initial2, today);

      expect(result.week, [0, 0, 0, 0, 0, 0, 0]);
      expect(result.lastPlayedDate, '2026-07-01');
    });

    test('same ISO week preserves week array', () {
      // Both in the same week
      final today = DateTime(2026, 7, 1); // Wednesday
      final initial2 = initial.copyWith(
        lastPlayedDate: '2026-06-30', // Tuesday (same week)
        week: [10, 20, 30, 40, 50, 60, 70],
        streak: 3,
      );

      final result = applyDailyRollover(initial2, today);

      expect(result.week, [10, 20, 30, 40, 50, 60, 70]);
      expect(result.lastPlayedDate, '2026-07-01');
    });
  });

  group('addPlayMinute', () {
    late SaveData initial;

    setUp(() {
      initial = SaveData.initial(profileId: 'test-profile');
    });

    test('increments minutesToday by 1', () {
      final now = DateTime(2026, 7, 1); // Wednesday
      final initial2 = initial.copyWith(minutesToday: 30);

      final result = addPlayMinute(initial2, now);

      expect(result.minutesToday, 31);
    });

    test('increments week at correct weekday slot (Monday)', () {
      final now = DateTime(2026, 6, 29); // Monday (weekday = 1)
      final initial2 = initial.copyWith(week: [0, 0, 0, 0, 0, 0, 0]);

      final result = addPlayMinute(initial2, now);

      expect(result.week[0], 1); // Monday
      expect(result.week[1], 0); // Tuesday
      expect(result.week[2], 0); // Wednesday
      expect(result.week[3], 0); // Thursday
      expect(result.week[4], 0); // Friday
      expect(result.week[5], 0); // Saturday
      expect(result.week[6], 0); // Sunday
    });

    test('increments week at correct weekday slot (Wednesday)', () {
      final now = DateTime(2026, 7, 1); // Wednesday (weekday = 3)
      final initial2 = initial.copyWith(week: [5, 10, 0, 0, 0, 0, 0]);

      final result = addPlayMinute(initial2, now);

      expect(result.week[0], 5); // Monday
      expect(result.week[1], 10); // Tuesday
      expect(result.week[2], 1); // Wednesday (incremented)
      expect(result.week[3], 0); // Thursday
      expect(result.week[4], 0); // Friday
      expect(result.week[5], 0); // Saturday
      expect(result.week[6], 0); // Sunday
    });

    test('increments week at correct weekday slot (Sunday)', () {
      final now = DateTime(2026, 7, 5); // Sunday (weekday = 7)
      final initial2 = initial.copyWith(week: [0, 0, 0, 0, 0, 0, 15]);

      final result = addPlayMinute(initial2, now);

      expect(result.week[0], 0); // Monday
      expect(result.week[1], 0); // Tuesday
      expect(result.week[2], 0); // Wednesday
      expect(result.week[3], 0); // Thursday
      expect(result.week[4], 0); // Friday
      expect(result.week[5], 0); // Saturday
      expect(result.week[6], 16); // Sunday (incremented)
    });

    test('multiple calls accumulate minutes and week', () {
      final now = DateTime(2026, 7, 1); // Wednesday
      var result = initial.copyWith(minutesToday: 0, week: [0, 0, 0, 0, 0, 0, 0]);

      result = addPlayMinute(result, now);
      result = addPlayMinute(result, now);
      result = addPlayMinute(result, now);

      expect(result.minutesToday, 3);
      expect(result.week[2], 3); // Wednesday accumulated 3 minutes
    });
  });
}
