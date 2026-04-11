// test/utils/formatting_test.dart
//
// Tests for duration formatting logic used in TimeTrackerScreen
// and ActiveTimerCard. The function is duplicated in both widgets,
// which is itself a code smell -- extracting it would improve testability.
import 'package:flutter_test/flutter_test.dart';

/// Extracted from TimeTrackerScreen._formatDuration and ActiveTimerCard._formatDuration.
String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}

/// Extracted from ExpenseEditScreen._calculateMileageTotal.
double calculateMileageTotal(double distance, double costPerUnit) {
  return distance * costPerUnit;
}

void main() {
  group('formatDuration', () {
    test('formats zero duration', () {
      expect(formatDuration(Duration.zero), '00:00:00');
    });

    test('formats seconds only', () {
      expect(formatDuration(const Duration(seconds: 45)), '00:00:45');
    });

    test('formats minutes and seconds', () {
      expect(formatDuration(const Duration(minutes: 5, seconds: 30)), '00:05:30');
    });

    test('formats hours, minutes, and seconds', () {
      expect(
        formatDuration(const Duration(hours: 2, minutes: 15, seconds: 8)),
        '02:15:08',
      );
    });

    test('pads single-digit values with leading zeros', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03',
      );
    });

    test('handles exactly one hour', () {
      expect(formatDuration(const Duration(hours: 1)), '01:00:00');
    });

    test('handles large hour values (no overflow at 24h)', () {
      expect(
        formatDuration(const Duration(hours: 100, minutes: 30, seconds: 15)),
        '100:30:15',
      );
    });

    test('handles 59 minutes and 59 seconds', () {
      expect(
        formatDuration(const Duration(minutes: 59, seconds: 59)),
        '00:59:59',
      );
    });

    test('formats a typical work session (1h 30m)', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 30)),
        '01:30:00',
      );
    });
  });

  group('calculateMileageTotal', () {
    test('calculates distance * costPerUnit', () {
      expect(calculateMileageTotal(100.0, 0.67), closeTo(67.0, 0.01));
    });

    test('returns 0 when distance is 0', () {
      expect(calculateMileageTotal(0.0, 0.67), 0.0);
    });

    test('returns 0 when costPerUnit is 0', () {
      expect(calculateMileageTotal(50.0, 0.0), 0.0);
    });

    test('handles fractional distances', () {
      expect(calculateMileageTotal(12.5, 0.50), closeTo(6.25, 0.001));
    });
  });
}
