import 'package:intl/intl.dart';

/// Presentation-only formatting. No persisted date encoding or currency choice.
abstract final class AppFormatters {
  static String date(DateTime date) =>
      (DateFormat.yMMMMd('ar_EG')..useNativeDigits = false).format(date);
}
