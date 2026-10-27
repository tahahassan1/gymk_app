import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/app/session/data/providers/gym_data_provider.dart';
import 'package:gymk_app/app/session/data/repositories/firestore_gym_repository.dart';
import 'package:gymk_app/core/data/read_snapshot.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/features/dropins/data/models/dropin.dart';
import 'package:gymk_app/features/members/data/models/member.dart';
import 'package:gymk_app/features/settings/data/models/gym_settings.dart';
import 'package:gymk_app/features/subscriptions/data/models/subscription_record.dart';

import '../support/fake_gym_repository.dart';

class FakeProvider implements GymDataProvider {
  final memberSource = StreamController<ReadSnapshot<List<Member>>>.broadcast(
    sync: true,
  );
  final subscriptionSource =
      StreamController<ReadSnapshot<List<SubscriptionRecord>>>.broadcast(
        sync: true,
      );
  final dropinSource = StreamController<ReadSnapshot<List<Dropin>>>.broadcast(
    sync: true,
  );
  final settingsSource = StreamController<ReadSnapshot<GymSettings?>>.broadcast(
    sync: true,
  );
  final starts = <String, int>{};
  @override
  final uid = 'owner';

  void _start(String name) => starts[name] = (starts[name] ?? 0) + 1;
  @override
  Stream<ReadSnapshot<List<Member>>> members() {
    _start('members');
    return memberSource.stream;
  }

  @override
  Stream<ReadSnapshot<List<SubscriptionRecord>>> subscriptions() {
    _start('subscriptions');
    return subscriptionSource.stream;
  }

  @override
  Stream<ReadSnapshot<List<Dropin>>> dropins() {
    _start('dropins');
    return dropinSource.stream;
  }

  @override
  Stream<ReadSnapshot<GymSettings?>> settings() {
    _start('settings');
    return settingsSource.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');

  Future<void> close() async {
    await Future.wait([
      memberSource.close(),
      subscriptionSource.close(),
      dropinSource.close(),
      settingsSource.close(),
    ]);
  }
}

void main() {
  test('routes share four tenant sources; retry replaces them and close clears tenant references', () async {
    final provider = FakeProvider();
    final repository = FirestoreGymRepository(provider);
    final members = [
      Member(id: 'one', name: 'أحمد', createdAt: DateTime.utc(2026, 10, 27)),
    ];
    provider.memberSource.add(snapshot(members, complete: false));
    final first = await repository.watchMembers().first;
    final second = await repository.watchMembers().first;
    expect(first.data.single.id, second.data.single.id);
    expect(first.isComplete, isFalse);
    expect(provider.starts, {
      'members': 1,
      'subscriptions': 1,
      'dropins': 1,
      'settings': 1,
    });
    await repository.retryReads();
    expect(provider.starts.values, everyElement(2));
    await repository.close();
    expect(repository.currentMembers, isNull);
    expect(provider.memberSource.hasListener, isFalse);
    expect(provider.subscriptionSource.hasListener, isFalse);
    expect(provider.dropinSource.hasListener, isFalse);
    expect(provider.settingsSource.hasListener, isFalse);
    await provider.close();
  });

  test('read failure retains usable history but revokes completeness for safe cascades', () async {
    final provider = FakeProvider();
    final repository = FirestoreGymRepository(provider);
    provider.subscriptionSource.add(snapshot(<SubscriptionRecord>[]));
    expect(repository.currentSubscriptions!.isComplete, isTrue);
    provider.subscriptionSource.addError(
      const AppFailure(FailureKind.validation, code: 'malformed-record'),
    );
    expect(repository.currentSubscriptions!.isComplete, isFalse);
    expect(repository.currentSubscriptions!.data, isEmpty);
    final replay = <ReadSnapshot<List<SubscriptionRecord>>>[];
    final errors = <Object>[];
    final route = repository.watchSubscriptions().listen(
      replay.add,
      onError: errors.add,
    );
    await Future<void>.delayed(Duration.zero);
    expect(replay.single.isComplete, isFalse);
    expect(errors, hasLength(1));
    provider.subscriptionSource.add(
      snapshot(<SubscriptionRecord>[], complete: false),
    );
    expect(repository.currentSubscriptions!.isComplete, isFalse);
    provider.subscriptionSource.add(snapshot(<SubscriptionRecord>[]));
    expect(repository.currentSubscriptions!.isComplete, isTrue);
    await route.cancel();
    await repository.close();
    await provider.close();
  });
}
