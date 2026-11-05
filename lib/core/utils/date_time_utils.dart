import 'package:intl/intl.dart';

class DateTimeUtils {
  DateTimeUtils._();

  static String formatDayDate(DateTime dateTime) =>
      DateFormat('EEE, d MMM').format(dateTime);

  static String formatTime(DateTime dateTime) =>
      DateFormat('h:mm a').format(dateTime);
}
