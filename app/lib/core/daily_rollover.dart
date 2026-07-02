import 'package:wonder_quest/core/persistence/save_data.dart';

/// Applies daily rollover logic to save data.
///
/// Rules:
/// - Dates are compared as 'yyyy-MM-dd' strings in local time
/// - If lastPlayedDate == today, no change
/// - If yesterday, streak += 1, minutesToday = 0
/// - If older or empty, streak = 1, minutesToday = 0
/// - Always sets lastPlayedDate to today
/// - If ISO week changed, zeroes the whole week list first
SaveData applyDailyRollover(SaveData s, DateTime now) {
  final todayString = _formatDate(now);

  // No change if it's the same day
  if (s.lastPlayedDate == todayString) {
    return s;
  }

  // Check if ISO week has changed
  bool weekChanged = false;
  if (s.lastPlayedDate.isNotEmpty) {
    final lastDate = _parseDate(s.lastPlayedDate);
    if (lastDate != null && !_isSameISOWeek(lastDate, now)) {
      weekChanged = true;
    }
  }

  // Determine new streak
  int newStreak = 1;
  if (s.lastPlayedDate.isNotEmpty) {
    final lastDate = _parseDate(s.lastPlayedDate);
    if (lastDate != null) {
      final yesterday = now.subtract(const Duration(days: 1));
      if (_isSameDay(lastDate, yesterday)) {
        // Consecutive day: increment streak
        newStreak = s.streak + 1;
      }
      // Otherwise, streak resets to 1 (gap or older date)
    }
  }

  // Build the new week list
  List<int> newWeek = s.week;
  if (weekChanged) {
    newWeek = [0, 0, 0, 0, 0, 0, 0];
  }

  return s.copyWith(
    streak: newStreak,
    minutesToday: 0,
    lastPlayedDate: todayString,
    week: newWeek,
  );
}

/// Adds one minute to both minutesToday and the current weekday slot.
SaveData addPlayMinute(SaveData s, DateTime now) {
  final newMinutesToday = s.minutesToday + 1;

  // Weekday: 1=Monday, 7=Sunday in Dart
  // week array: index 0=Monday, 6=Sunday
  final weekIndex = now.weekday - 1;
  final newWeek = List<int>.from(s.week);
  newWeek[weekIndex] = newWeek[weekIndex] + 1;

  return s.copyWith(
    minutesToday: newMinutesToday,
    week: newWeek,
  );
}

/// Formats a DateTime as 'yyyy-MM-dd' string in local time.
String _formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
         '${date.month.toString().padLeft(2, '0')}-'
         '${date.day.toString().padLeft(2, '0')}';
}

/// Parses a 'yyyy-MM-dd' string to DateTime in local time.
/// Returns null if parsing fails.
DateTime? _parseDate(String dateString) {
  try {
    final parts = dateString.split('-');
    if (parts.length != 3) return null;
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}

/// Checks if two dates are the same day (ignoring time).
bool _isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
         date1.month == date2.month &&
         date1.day == date2.day;
}

/// Gets the Monday of the ISO week containing the given date.
DateTime _getWeekMonday(DateTime date) {
  return date.subtract(Duration(days: date.weekday - 1));
}

/// Checks if two dates are in the same ISO week.
bool _isSameISOWeek(DateTime date1, DateTime date2) {
  final monday1 = _getWeekMonday(date1);
  final monday2 = _getWeekMonday(date2);

  return monday1.year == monday2.year &&
         monday1.month == monday2.month &&
         monday1.day == monday2.day;
}
