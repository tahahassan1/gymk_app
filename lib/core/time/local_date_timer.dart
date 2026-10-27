import 'dart:async';

/// Re-schedules from local components so DST and clock changes on resume work.
final class LocalDateTimer {
  LocalDateTimer(this.onRollover) {
    restart();
  }
  final void Function() onRollover;
  Timer? _timer;
  void restart() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(next.difference(now), () {
      onRollover();
      restart();
    });
  }

  void cancel() => _timer?.cancel();
}
