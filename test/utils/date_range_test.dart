// test/utils/date_range_test.dart
//
// Tests for the date range calculation logic used in ReportsScreen.
// The logic is replicated here because it's embedded in the widget state.
// This highlights a refactoring opportunity: extract this into a utility.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum TimePeriod { thisWeek, lastWeek, lastMonth, thisYear }

/// Extracted from ReportsScreen._getDateRange for testability.
DateTimeRange getDateRange(TimePeriod period, {DateTime? now}) {
  now ??= DateTime.now();
  switch (period) {
    case TimePeriod.thisWeek:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return DateTimeRange(
        start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case TimePeriod.lastWeek:
      final endOfLastWeek = now.subtract(Duration(days: now.weekday));
      final startOfLastWeek =
          endOfLastWeek.subtract(const Duration(days: 6));
      return DateTimeRange(
        start: DateTime(startOfLastWeek.year, startOfLastWeek.month,
            startOfLastWeek.day),
        end: DateTime(endOfLastWeek.year, endOfLastWeek.month,
            endOfLastWeek.day, 23, 59, 59),
      );
    case TimePeriod.lastMonth:
      final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
      final lastDayOfLastMonth =
          firstDayOfCurrentMonth.subtract(const Duration(days: 1));
      final firstDayOfLastMonth =
          DateTime(lastDayOfLastMonth.year, lastDayOfLastMonth.month, 1);
      return DateTimeRange(
          start: firstDayOfLastMonth, end: lastDayOfLastMonth);
    case TimePeriod.thisYear:
      return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
  }
}

void main() {
  group('getDateRange', () {
    // Wednesday, 2025-03-12
    final wednesday = DateTime(2025, 3, 12, 14, 30);

    group('thisWeek', () {
      test('starts on Monday of the current week', () {
        final range = getDateRange(TimePeriod.thisWeek, now: wednesday);
        // Wednesday weekday = 3, so Monday = March 10
        expect(range.start, DateTime(2025, 3, 10));
      });

      test('ends on the current day at 23:59:59', () {
        final range = getDateRange(TimePeriod.thisWeek, now: wednesday);
        expect(range.end, DateTime(2025, 3, 12, 23, 59, 59));
      });

      test('works correctly on a Monday', () {
        final monday = DateTime(2025, 3, 10, 9, 0);
        final range = getDateRange(TimePeriod.thisWeek, now: monday);
        expect(range.start, DateTime(2025, 3, 10));
        expect(range.end, DateTime(2025, 3, 10, 23, 59, 59));
      });

      test('works correctly on a Sunday', () {
        final sunday = DateTime(2025, 3, 16, 20, 0);
        final range = getDateRange(TimePeriod.thisWeek, now: sunday);
        expect(range.start, DateTime(2025, 3, 10));
        expect(range.end, DateTime(2025, 3, 16, 23, 59, 59));
      });
    });

    group('lastWeek', () {
      test('spans Monday to Sunday of the previous week', () {
        final range = getDateRange(TimePeriod.lastWeek, now: wednesday);
        // Last week: Mon Mar 3 -> Sun Mar 9
        expect(range.start, DateTime(2025, 3, 3));
        expect(range.end.day, 9);
        expect(range.end.month, 3);
      });

      test('last week from Monday gives the correct prior week', () {
        final monday = DateTime(2025, 3, 10, 9, 0);
        final range = getDateRange(TimePeriod.lastWeek, now: monday);
        expect(range.start, DateTime(2025, 3, 3));
      });
    });

    group('lastMonth', () {
      test('returns the full previous month', () {
        final march15 = DateTime(2025, 3, 15);
        final range = getDateRange(TimePeriod.lastMonth, now: march15);
        expect(range.start, DateTime(2025, 2, 1));
        expect(range.end.month, 2);
        expect(range.end.day, 28); // Feb 2025 has 28 days
      });

      test('handles January (previous month is December of prior year)', () {
        final jan15 = DateTime(2025, 1, 15);
        final range = getDateRange(TimePeriod.lastMonth, now: jan15);
        expect(range.start, DateTime(2024, 12, 1));
        expect(range.end, DateTime(2024, 12, 31));
      });

      test('handles leap year February correctly', () {
        final march1 = DateTime(2024, 3, 1); // 2024 is a leap year
        final range = getDateRange(TimePeriod.lastMonth, now: march1);
        expect(range.start, DateTime(2024, 2, 1));
        expect(range.end.day, 29); // Leap year Feb has 29 days
      });
    });

    group('thisYear', () {
      test('starts on January 1 of the current year', () {
        final range = getDateRange(TimePeriod.thisYear, now: wednesday);
        expect(range.start, DateTime(2025, 1, 1));
      });

      test('ends at the current datetime', () {
        final range = getDateRange(TimePeriod.thisYear, now: wednesday);
        expect(range.end, wednesday);
      });
    });
  });
}
