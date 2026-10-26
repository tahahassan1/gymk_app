import 'date_only.dart';

/// Inject at business-logic boundaries; read once per calculation/command.
abstract interface class Clock {
  DateOnly today();
}

/// The MVP follows the device's local calendar, without a fixed gym timezone.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateOnly today() => DateOnly.fromDateTime(DateTime.now());
}
