import '../errors/app_failure.dart';
import 'date_only.dart';

/// Confirmed persisted date contract, separate from presentation formatting.
abstract final class DateOnlyCodec {
  static final _pattern = RegExp(r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$');

  static String encode(DateOnly date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DateOnly decode(Object? value) {
    if (value is! String || !_pattern.hasMatch(value)) {
      throw const AppFailure(FailureKind.validation, code: 'date-encoding');
    }
    try {
      return DateOnly(
        int.parse(value.substring(0, 4)),
        int.parse(value.substring(5, 7)),
        int.parse(value.substring(8, 10)),
      );
    } on ArgumentError {
      throw const AppFailure(FailureKind.validation, code: 'date-components');
    }
  }
}
