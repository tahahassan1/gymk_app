import 'dart:async';

import 'package:gymk_app/app/session/data/repositories/gym_repository.dart';
import 'package:gymk_app/core/data/read_snapshot.dart';
import 'package:gymk_app/core/data/mutation_registry.dart';
import 'package:gymk_app/features/members/data/models/member.dart';
import 'package:gymk_app/features/subscriptions/data/models/subscription_record.dart';

/// Typed repository fake for Cubits. Unsupported calls fail loudly.
class FakeGymRepository implements GymRepository {
  final members = StreamController<ReadSnapshot<List<Member>>>.broadcast(
    sync: true,
  );
  final subscriptions =
      StreamController<ReadSnapshot<List<SubscriptionRecord>>>.broadcast(
        sync: true,
      );
  int memberConsumers = 0;
  int coverageConsumers = 0;
  int retries = 0;
  int mutationConsumers = 0;
  int _ids = 0;
  final mutationSource = StreamController<List<MutationNotice>>.broadcast(
    sync: true,
  );
  List<MutationNotice> notices = const [];

  @override
  String newId() => 'fake-${++_ids}';
  @override
  List<MutationNotice> get mutations => notices;
  @override
  Stream<List<MutationNotice>> get mutationChanges {
    mutationConsumers++;
    return mutationSource.stream;
  }

  void emitMutations(List<MutationNotice> value) {
    notices = value;
    mutationSource.add(value);
  }

  @override
  void dismissFailure(String operationId) => emitMutations(
    notices.where((notice) => notice.id != operationId).toList(),
  );

  @override
  String get uid => 'owner';
  @override
  Stream<ReadSnapshot<List<Member>>> watchMembers() {
    memberConsumers++;
    return members.stream.map((value) {
      _currentMembers = value;
      return value;
    });
  }

  @override
  Stream<ReadSnapshot<List<SubscriptionRecord>>> watchSubscriptions() {
    coverageConsumers++;
    return subscriptions.stream.map((value) {
      _currentSubscriptions = value;
      return value;
    });
  }

  ReadSnapshot<List<Member>>? _currentMembers;
  ReadSnapshot<List<SubscriptionRecord>>? _currentSubscriptions;
  @override
  ReadSnapshot<List<Member>>? get currentMembers => _currentMembers;
  @override
  ReadSnapshot<List<SubscriptionRecord>>? get currentSubscriptions =>
      _currentSubscriptions;

  @override
  Future<void> retryReads() async {
    retries++;
  }

  @override
  Future<void> close() async {
    await members.close();
    await subscriptions.close();
    await mutationSource.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Unexpected repository call: ${invocation.memberName}',
  );
}

ReadSnapshot<T> snapshot<T>(
  T data, {
  bool complete = true,
  bool pending = false,
}) => ReadSnapshot(
  data: data,
  fromCache: !complete,
  hasPendingWrites: pending,
  isComplete: complete,
);
