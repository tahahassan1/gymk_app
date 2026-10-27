import 'dart:async';

import '../errors/app_failure.dart';

enum MutationStage { submitted, locallyApplied, acknowledged, rejected }

enum MutationAction {
  saveMember,
  saveSubscription,
  deleteSubscription,
  saveDropin,
  deleteDropin,
  saveSettings,
  deleteMember,
}

final class MutationNotice {
  const MutationNotice({
    required this.id,
    required this.target,
    required this.action,
    required this.stage,
    required this.failure,
    this.targetName,
  });
  final String id;
  final String target;
  final String? targetName;
  final MutationAction action;
  final MutationStage stage;
  final AppFailure? failure;
  bool get pending =>
      stage == MutationStage.submitted || stage == MutationStage.locallyApplied;
}

final class MutationHandle {
  MutationHandle._(this.id, this.target, this.action, this.targetName);

  final String id;
  final String target;
  final String? targetName;
  final MutationAction action;
  MutationStage _stage = MutationStage.submitted;
  AppFailure? _failure;
  MutationStage get stage => _stage;
  AppFailure? get failure => _failure;
  final _local = Completer<AppFailure?>();
  final _remote = Completer<AppFailure?>();

  /// Null means this specific operation was observed locally, or acknowledged.
  /// A failure of local observation does not mean the cloud rejected the write.
  Future<AppFailure?> get localResult => _local.future;
  Future<AppFailure?> get remoteResult => _remote.future;
  bool get pending =>
      stage == MutationStage.submitted || stage == MutationStage.locallyApplied;
}

/// Owns eventual SDK failures after a form closes. All write futures are handled;
/// no custom durable queue or independently maintained optimistic record list.
final class MutationRegistry {
  final _handles = <String, MutationHandle>{};
  final _observers = <String, StreamSubscription<bool>>{};
  final _changes = StreamController<List<MutationNotice>>.broadcast(sync: true);
  bool _closed = false;

  List<MutationNotice> get current => List.unmodifiable(
    _handles.values.map(
      (handle) => MutationNotice(
        id: handle.id,
        target: handle.target,
        action: handle.action,
        stage: handle.stage,
        failure: handle.failure,
        targetName: handle.targetName,
      ),
    ),
  );
  Stream<List<MutationNotice>> get changes => _changes.stream;

  MutationHandle submit({
    required String id,
    required String target,
    required MutationAction action,
    required Stream<bool> localObservation,
    required Future<void> Function() write,
    required AppFailure Function(Object) mapFailure,
    String? targetName,
  }) {
    if (_closed) throw const AppFailure(FailureKind.unauthenticated);
    final previous = _handles[id];
    if (previous != null && previous.stage != MutationStage.rejected) {
      return previous;
    }
    final handle = MutationHandle._(id, target, action, targetName);
    _handles[id] = handle;
    _notify();
    _observers[id] = localObservation.listen(
      (matches) {
        if (_closed || !matches || !handle.pending) return;
        handle._stage = MutationStage.locallyApplied;
        if (!handle._local.isCompleted) handle._local.complete(null);
        _notify();
      },
      onError: (Object error, StackTrace trace) {
        if (_closed) return;
        // The write may still be queued: distinguish uncertain local observation
        // from an eventual rejection. A stable intent ID remains safe to retry.
        if (!handle._local.isCompleted) {
          handle._local.complete(
            const AppFailure(
              FailureKind.unavailable,
              code: 'local-confirmation',
            ),
          );
        }
      },
    );
    Future<void>.sync(write).then<void>(
      (_) {
        if (_closed) return;
        handle._stage = MutationStage.acknowledged;
        handle._failure = null;
        if (!handle._local.isCompleted) handle._local.complete(null);
        handle._remote.complete(null);
        _stopObserving(id);
        _notify();
      },
      onError: (Object error, StackTrace trace) {
        if (_closed) return;
        final failure = mapFailure(error);
        handle._stage = MutationStage.rejected;
        handle._failure = failure;
        if (!handle._local.isCompleted) handle._local.complete(failure);
        handle._remote.complete(failure);
        _stopObserving(id);
        _notify();
      },
    );
    return handle;
  }

  void dismissFailure(String id) {
    if (_handles[id]?.stage != MutationStage.rejected) return;
    _handles.remove(id);
    _notify();
  }

  void _notify() {
    if (!_closed) _changes.add(current);
  }

  void _stopObserving(String id) {
    final observer = _observers.remove(id);
    if (observer != null) unawaited(observer.cancel());
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final handle in _handles.values) {
      const ended = AppFailure(
        FailureKind.unauthenticated,
        code: 'session-ended',
      );
      if (!handle._local.isCompleted) handle._local.complete(ended);
      if (!handle._remote.isCompleted) handle._remote.complete(ended);
    }
    await Future.wait(_observers.values.map((observer) => observer.cancel()));
    _observers.clear();
    _handles.clear();
    await _changes.close();
  }
}
