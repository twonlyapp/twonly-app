// Function to calculate time difference
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/utils/misc.dart';

void main() {
  test('Time difference calculation between different time zones', () {
    // Test case 1: Current time is in UTC and start time is in UTC+2
    DateTime now = DateTime.parse('2023-10-01T10:00:00Z'); // 10:00 UTC
    DateTime startTime =
        DateTime.parse('2023-10-01T12:00:00+02:00'); // 12:00 UTC+2

    Duration difference = calculateTimeDifference(now, startTime);
    expect(difference.inHours, equals(0)); // 10:00 UTC - 12:00 UTC+2 = 0 hours

    // Test case 2: Current time is in UTC-1 and start time is in UTC+1
    now = DateTime.parse('2023-10-01T09:00:00-01:00'); // 09:00 UTC-1
    startTime = DateTime.parse('2023-10-01T11:00:00+01:00'); // 11:00 UTC+1

    difference = calculateTimeDifference(now, startTime);
    expect(
        difference.inHours, equals(0)); // 09:00 UTC-1 - 11:00 UTC+1 = 0 hours

    // Test case 3: Current time is in UTC+3 and start time is in UTC-1
    now = DateTime.parse('2023-10-01T15:00:00+03:00'); // 15:00 UTC+3
    startTime = DateTime.parse('2023-10-01T13:00:00-01:00'); // 13:00 UTC-1

    difference = calculateTimeDifference(now, startTime);
    expect(
        difference.inHours, equals(-2)); // 15:00 UTC+3 - 13:00 UTC-1 = -2 hours
  });
}
