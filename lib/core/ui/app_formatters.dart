import 'package:intl/intl.dart';

import '../money/gymk_currency.dart';
import '../text/western_digits.dart';
import '../time/date_only.dart';

/// Presentation-only formatting. Persisted date encoding is a separate contract.
abstract final class AppFormatters {
  static String month(DateOnly value) =>
      '\u2068${(DateFormat.yMMMM('ar_EG')..useNativeDigits = false).format(DateTime(value.year, value.month))}\u2069';

  static String totalMoney(BigInt value) {
    final formatter = NumberFormat.currency(
      locale: 'ar_EG',
      name: GymkCurrency.code,
      decimalDigits: 0,
    );
    final digits = value.toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => formatter.symbols.GROUP_SEP,
    );
    return '\u2068$grouped ${formatter.currencySymbol}\u2069';
  }

  static String day(DateOnly value) =>
      '\u2068${date(DateTime(value.year, value.month, value.day))}\u2069';
  static String date(DateTime date) =>
      (DateFormat.yMMMMd('ar_EG')..useNativeDigits = false).format(date);

  /// Whole EGP with Western digits. Unicode isolation keeps the complete money
  /// expression together when placed in surrounding RTL text.
  static String money(int minorUnits) {
    final formatted = NumberFormat.currency(
      locale: 'ar_EG',
      name: GymkCurrency.code,
      decimalDigits: GymkCurrency.fractionDigits,
    ).format(minorUnits);
    return '\u2068${westernDigits(formatted)}\u2069';
  }
}
