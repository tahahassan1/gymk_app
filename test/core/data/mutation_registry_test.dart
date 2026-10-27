import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/data/member_mutation_gate.dart';
import 'package:gymk_app/core/data/mutation_registry.dart';
import 'package:gymk_app/core/errors/app_failure.dart';

void main() {
  late MutationRegistry registry;
  late StreamController<bool> local;
  late Completer<void> cloud;
  var writes = 0;

  MutationHandle submit({String id = 'intent'}) => registry.submit(
    id: id,
    target: 'member',
    action: MutationAction.saveSubscription,
    localObservation: local.stream,
    write: () {
      writes++;
      return cloud.future;
    },
    mapFailure: (_) => const AppFailure(FailureKind.permission),
  );

  setUp(() {
    registry = MutationRegistry();
    local = StreamController<bool>.broadcast(sync: true);
    cloud = Completer<void>();
    writes = 0;
  });
  tearDown(() async {
    await registry.close();
    await local.close();
  });

  test(
    'local application releases offline forms before cloud acknowledgement',
    () async {
      final handle = submit();
      final before = registry.current;
      local.add(false);
      expect(handle.stage, MutationStage.submitted);
      local.add(true);
      expect(await handle.localResult, isNull);
      expect(handle.stage, MutationStage.locallyApplied);
      expect(handle.pending, isTrue);
      expect(
        before.single.stage,
        MutationStage.submitted,
        reason: 'Published notices are immutable',
      );
      cloud.complete();
      expect(await handle.remoteResult, isNull);
      expect(handle.stage, MutationStage.acknowledged);
      expect(handle.pending, isFalse);
    },
  );

  test(
    'eventual rejection survives a closed form and preserves affected action',
    () async {
      final handle = submit();
      local.add(true);
      await handle.localResult;
      cloud.completeError(StateError('rules rejected'));
      expect((await handle.remoteResult)?.kind, FailureKind.permission);
      expect(registry.current.single.stage, MutationStage.rejected);
      expect(registry.current.single.target, 'member');
      expect(registry.current.single.action, MutationAction.saveSubscription);
      registry.dismissFailure(handle.id);
      expect(registry.current, isEmpty);
    },
  );

  test(
    'duplicate intent is submitted once and retry keeps its stable ID',
    () async {
      final first = submit();
      expect(submit(), same(first));
      expect(writes, 1);
      cloud.completeError(StateError('rejected'));
      await first.remoteResult;
      cloud = Completer<void>();
      final retried = submit();
      expect(retried.id, first.id);
      expect(writes, 2);
      cloud.complete();
      await retried.remoteResult;
    },
  );

  test(
    'member gate rejects conflicting mutations until local application',
    () async {
      final gate = MemberMutationGate();
      final first = gate.run('member', submit);
      expect(
        () => gate.run('member', submit),
        throwsA(
          isA<AppFailure>().having(
            (value) => value.kind,
            'kind',
            FailureKind.conflict,
          ),
        ),
      );
      local.add(true);
      await first.localResult;
      final second = gate.run('member', () => submit(id: 'next'));
      expect(second.id, 'next');
      expect(
        writes,
        2,
        reason:
            'The lock does not wait indefinitely for offline acknowledgement',
      );
      cloud.complete();
      await second.remoteResult;
    },
  );

  test(
    'read observation error is not reported as cloud write rejection',
    () async {
      final handle = submit();
      local.addError(StateError('read unavailable'));
      expect((await handle.localResult)?.code, 'local-confirmation');
      expect(handle.stage, MutationStage.submitted);
      cloud.complete();
      expect(await handle.remoteResult, isNull);
      expect(handle.stage, MutationStage.acknowledged);
    },
  );

  test(
    'session close releases waiters and ignores late write completions',
    () async {
      final handle = submit();
      await registry.close();
      expect((await handle.localResult)?.code, 'session-ended');
      cloud.completeError(StateError('late rejection'));
      await Future<void>.delayed(Duration.zero);
      expect(() => submit(id: 'late'), throwsA(isA<AppFailure>()));
    },
  );
}
