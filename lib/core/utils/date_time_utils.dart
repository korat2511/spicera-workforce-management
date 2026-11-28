import 'package:intl/intl.dart';

class DateTimeUtils {
  DateTimeUtils._();

  static String formatDayDate(DateTime dateTime) =>
      DateFormat('EEE, d MMM').format(dateTime);

  /// Formats a date as a 3-letter weekday abbreviation (e.g. "MON").
  static String formatWeekdayShort(DateTime dateTime) =>
      DateFormat('EEE').format(dateTime).toUpperCase();

  /// Formats a date as "November 2026".
  static String formatMonthYear(DateTime dateTime) =>
      DateFormat('MMMM yyyy').format(dateTime);

  static String formatTime(DateTime dateTime) =>
      DateFormat('h:mm a').format(dateTime);

  /// Formats a "HH:mm" 24-hour string (e.g. "14:00") as "2:00 PM".
  static String formatTime24(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return formatTime(DateTime(2000, 1, 1, hour, minute));
  }

  static String toApiDate(DateTime dateTime) =>
      DateFormat('yyyy-MM-dd').format(dateTime);

  /// Formats a "yyyy-MM-dd" API date string (e.g. "2026-09-01") as
  /// "1 Sep 2026".
  static String formatApiDate(String isoDate) =>
      DateFormat('d MMM yyyy').format(DateTime.parse(isoDate));

  /// Formats an ISO8601 API timestamp (e.g. "2026-11-27T06:39:10+00:00") as
  /// "27 Nov 2026, 12:09 PM" in the device's local time.
  static String formatApiDateTime(String isoDateTime) => DateFormat(
    'd MMM yyyy, h:mm a',
  ).format(DateTime.parse(isoDateTime).toLocal());
}
