import 'package:gymk_app/core/time/clock.dart';
import 'package:gymk_app/core/time/date_only.dart';

final class FakeClock implements Clock {
  FakeClock(this.date);

  DateOnly date;
  int reads = 0;

  @override
  DateOnly today() {
    reads++;
    return date;
  }
}
