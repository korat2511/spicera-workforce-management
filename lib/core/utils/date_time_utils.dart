import 'package:intl/intl.dart';

class DateTimeUtils {
  DateTimeUtils._();

  static String formatDayDate(DateTime dateTime) =>
      DateFormat('EEE, d MMM').format(dateTime);

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
}
