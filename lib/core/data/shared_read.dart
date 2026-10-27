import 'dart:async';

/// One owned source subscription with replay to route consumers. This is only
/// an in-memory projection; Firestore remains the durable application store.
final class SharedRead<T> {
  SharedRead(Stream<T> source) : this.fromFactory(() => source);

  SharedRead.fromFactory(this._source) {
    _listen();
  }

  final Stream<T> Function() _source;
  bool _restarting = false;

  void _listen() {
    _subscription = _source().listen(
      (value) {
        if (_closed) return;
        _latest = value;
        _hasLatest = true;
        _lastError = null;
        _events.add(value);
      },
      onError: (Object error, StackTrace trace) {
        if (_closed) return;
        _lastError = (error, trace);
        _events.addError(error, trace);
      },
    );
  }

  final _events = StreamController<T>.broadcast(sync: true);
  late StreamSubscription<T> _subscription;
  T? _latest;
  bool _hasLatest = false;
  bool _closed = false;
  (Object, StackTrace)? _lastError;

  T? get latest => _latest;
  bool get hasFailure => _lastError != null;

  Future<void> retry() async {
    if (_closed || _restarting) return;
    _restarting = true;
    try {
      await _subscription.cancel();
      if (!_closed) _listen();
    } finally {
      _restarting = false;
    }
  }

  Stream<T> watch() => Stream<T>.multi((sink) {
    if (_closed) {
      sink.close();
      return;
    }
    final subscription = _events.stream.listen(
      sink.add,
      onError: sink.addError,
      onDone: sink.close,
    );
    sink.onCancel = subscription.cancel;
    if (_hasLatest) sink.add(_latest as T);
    if (_lastError case final error?) sink.addError(error.$1, error.$2);
  });

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _latest = null;
    _hasLatest = false;
    _lastError = null;
    await _subscription.cancel();
    await _events.close();
  }
}
