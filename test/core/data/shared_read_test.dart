import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/app/session/data/providers/provider_stream.dart';
import 'package:gymk_app/core/data/shared_read.dart';

void main() {
  test(
    'closing with an active route consumer also completes the consumer',
    () async {
      final source = StreamController<int>.broadcast(sync: true);
      final read = SharedRead(source.stream);
      final values = <int>[];
      var done = false;
      final consumer = read.watch().listen(
        values.add,
        onDone: () => done = true,
      );
      source.add(1);
      await Future<void>.delayed(Duration.zero);
      await read.close().timeout(const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);
      expect(done, isTrue);
      expect(values, [1]);
      await consumer.cancel();
      await source.close();
    },
  );

  test('provider cancellation works without another SDK snapshot', () async {
    final source = StreamController<int>.broadcast(sync: true);
    Stream<int> provider() => providerStream(source.stream, (value) => value);

    final read = SharedRead<int>.fromFactory(provider);
    final first = read.watch().first;
    await Future<void>.delayed(Duration.zero);
    source.add(1);
    expect(await first, 1);
    await read.close().timeout(const Duration(seconds: 1));
    expect(source.hasListener, isFalse);
    await source.close();
  });

  test('retry replaces a failed source without losing cached data or duplicating listeners', () async {
    final sources = List.generate(
      2,
      (_) => StreamController<int>.broadcast(sync: true),
    );
    var starts = 0;
    final read = SharedRead<int>.fromFactory(() => sources[starts++].stream);
    sources[0].add(1);
    final values = <int>[];
    final subscription = read.watch().listen(
      values.add,
      onError: (Object _) {},
    );
    await Future<void>.delayed(Duration.zero);
    sources[0].addError(StateError('terminal listener error'));
    await Future.wait([read.retry(), read.retry()]);
    expect(starts, 2);
    expect(read.latest, 1);
    expect(sources[0].hasListener, isFalse);
    sources[0].add(99);
    sources[1].add(2);
    await Future<void>.delayed(Duration.zero);
    expect(values, [1, 2]);
    await subscription.cancel();
    await read.close();
    for (final source in sources) {
      await source.close();
    }
  });

  test('multiple consumers share one source and receive cached data', () async {
    var listeners = 0;
    var cancellations = 0;
    final source = StreamController<int>.broadcast(
      sync: true,
      onListen: () => listeners++,
      onCancel: () => cancellations++,
    );
    final read = SharedRead(source.stream);
    source.add(1);
    final first = <int>[];
    final second = <int>[];
    final a = read.watch().listen(first.add);
    final b = read.watch().listen(second.add);
    await Future<void>.delayed(Duration.zero);
    source.add(2);
    await Future<void>.delayed(Duration.zero);
    expect(first, [1, 2]);
    expect(second, [1, 2]);
    expect(listeners, 1);
    await a.cancel();
    await b.cancel();
    expect(cancellations, 0, reason: 'Session, not route, owns the source');
    await read.close();
    expect(cancellations, 1);
    await source.close();
  });

  test(
    'a read error retains data and is replayed to a newly opened route',
    () async {
      final source = StreamController<int>(sync: true);
      final read = SharedRead(source.stream);
      source.add(42);
      source.addError(StateError('unavailable'));
      final values = <int>[];
      final failures = <Object>[];
      final subscription = read.watch().listen(
        values.add,
        onError: failures.add,
      );
      await Future<void>.delayed(Duration.zero);
      expect(values, [42]);
      expect(failures, hasLength(1));
      expect(read.latest, 42);
      source.add(43);
      await Future<void>.delayed(Duration.zero);
      final reopened = <int>[];
      final reopenedErrors = <Object>[];
      final other = read.watch().listen(
        reopened.add,
        onError: reopenedErrors.add,
      );
      await Future<void>.delayed(Duration.zero);
      expect(reopened, [43]);
      expect(reopenedErrors, isEmpty);
      await subscription.cancel();
      await other.cancel();
      await read.close();
      await source.close();
    },
  );

  test(
    'close cancels the tenant listener and ignores subsequent source data',
    () async {
      var cancelled = false;
      final source = StreamController<int>.broadcast(
        sync: true,
        onCancel: () => cancelled = true,
      );
      final read = SharedRead(source.stream);
      source.add(1);
      await read.close();
      source.add(2);
      expect(cancelled, isTrue);
      expect(
        read.latest,
        isNull,
        reason: 'Closed tenant projections release cached references',
      );
      expect(await read.watch().toList(), isEmpty);
      await read.close();
      await source.close();
    },
  );
}
