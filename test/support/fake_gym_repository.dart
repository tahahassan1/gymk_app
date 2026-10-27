import 'dart:async';

import 'package:gymk_app/app/session/data/repositories/gym_repository.dart';
import 'package:gymk_app/core/data/read_snapshot.dart';
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

  @override
  String get uid => 'owner';
  @override
  Stream<ReadSnapshot<List<Member>>> watchMembers() {
    memberConsumers++;
    return members.stream;
  }

  @override
  Stream<ReadSnapshot<List<SubscriptionRecord>>> watchSubscriptions() {
    coverageConsumers++;
    return subscriptions.stream;
  }

  @override
  Future<void> retryReads() async {
    retries++;
  }

  @override
  Future<void> close() async {
    await members.close();
    await subscriptions.close();
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
