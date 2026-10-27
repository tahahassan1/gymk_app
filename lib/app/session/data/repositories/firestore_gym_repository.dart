import 'dart:async';

import '../../../../core/data/member_mutation_gate.dart';
import '../../../../core/data/member_cascade_limit.dart';
import '../../../../core/data/mutation_registry.dart';
import '../../../../core/data/read_snapshot.dart';
import '../../../../core/data/shared_read.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../features/dropins/data/models/dropin.dart';
import '../../../../features/members/data/models/member.dart';
import '../../../../features/settings/data/models/gym_settings.dart';
import '../../../../features/subscriptions/data/models/subscription_record.dart';
import '../providers/firebase_failure.dart';
import '../providers/gym_data_provider.dart';
import 'gym_repository.dart';

/// One repository instance and four source listeners per captured UID. Routes
/// subscribe to replayed streams; a screen rebuild cannot create SDK listeners.
final class FirestoreGymRepository implements GymRepository {
  FirestoreGymRepository(this.provider)
    : _members = SharedRead.fromFactory(provider.members),
      _subscriptions = SharedRead.fromFactory(provider.subscriptions),
      _dropins = SharedRead.fromFactory(provider.dropins),
      _settings = SharedRead.fromFactory(provider.settings);

  final GymDataProvider provider;
  final SharedRead<ReadSnapshot<List<Member>>> _members;
  final SharedRead<ReadSnapshot<List<SubscriptionRecord>>> _subscriptions;
  final SharedRead<ReadSnapshot<List<Dropin>>> _dropins;
  final SharedRead<ReadSnapshot<GymSettings?>> _settings;
  final _registry = MutationRegistry();
  final _memberGate = MemberMutationGate();

  @override
  String get uid => provider.uid;
  @override
  String newId() => provider.newId();
  @override
  Stream<ReadSnapshot<List<Member>>> watchMembers() => _watch(_members);
  @override
  Stream<ReadSnapshot<List<SubscriptionRecord>>> watchSubscriptions() =>
      _watch(_subscriptions);
  @override
  Stream<ReadSnapshot<List<Dropin>>> watchDropins() => _watch(_dropins);
  @override
  Stream<ReadSnapshot<GymSettings?>> watchSettings() => _watch(_settings);
  @override
  ReadSnapshot<List<Member>>? get currentMembers => _current(_members);
  @override
  ReadSnapshot<List<SubscriptionRecord>>? get currentSubscriptions =>
      _current(_subscriptions);
  @override
  ReadSnapshot<List<Dropin>>? get currentDropins => _current(_dropins);
  @override
  ReadSnapshot<GymSettings?>? get currentSettings => _current(_settings);
  @override
  List<MutationNotice> get mutations => _registry.current;
  @override
  Stream<List<MutationNotice>> get mutationChanges => _registry.changes;
  @override
  void dismissFailure(String operationId) =>
      _registry.dismissFailure(operationId);
  @override
  Future<void> ensureInitialSettings(GymSettings defaults) =>
      provider.ensureInitialSettings(defaults);

  @override
  Future<void> retryReads() => Future.wait([
    _members.retry(),
    _subscriptions.retry(),
    _dropins.retry(),
    _settings.retry(),
  ]);

  Stream<bool> _observed<T>(
    SharedRead<ReadSnapshot<T>> read,
    bool Function(T) matches,
  ) {
    final before = read.latest;
    return read.watch().map(
      (snapshot) => !identical(snapshot, before) && matches(snapshot.data),
    );
  }

  MutationHandle _submit({
    required String id,
    required String target,
    required MutationAction action,
    required Stream<bool> observation,
    required Future<void> Function() write,
    String? targetName,
  }) => _registry.submit(
    id: id,
    target: target,
    action: action,
    localObservation: observation,
    write: write,
    mapFailure: firebaseFailure,
    targetName: targetName,
  );

  ReadSnapshot<T>? _current<T>(SharedRead<ReadSnapshot<T>> read) {
    final latest = read.latest;
    return read.hasFailure ? latest?.asIncomplete() : latest;
  }

  Stream<ReadSnapshot<T>> _watch<T>(SharedRead<ReadSnapshot<T>> read) => read
      .watch()
      .map((snapshot) => read.hasFailure ? snapshot.asIncomplete() : snapshot);

  @override
  MutationHandle saveMember(Member member, {required String operationId}) =>
      _memberGate.run(
        member.id,
        () => _submit(
          id: operationId,
          target: member.id,
          action: MutationAction.saveMember,
          targetName: member.name,
          observation: _observed(
            _members,
            (records) => records.any(
              (record) =>
                  record.id == member.id &&
                  record.name == member.name &&
                  record.phone == member.phone &&
                  record.createdAt.isAtSameMomentAs(member.createdAt),
            ),
          ),
          write: () => provider.saveMember(member),
        ),
      );

  @override
  MutationHandle saveSubscription(
    SubscriptionRecord record, {
    required String operationId,
  }) => _memberGate.run(
    record.memberId,
    () => _submit(
      id: operationId,
      target: record.memberId,
      action: MutationAction.saveSubscription,
      targetName: _memberName(record.memberId),
      observation: _observed(
        _subscriptions,
        (records) => records.any(
          (value) =>
              value.id == record.id &&
              value.memberId == record.memberId &&
              value.amount == record.amount &&
              value.startDate == record.startDate &&
              value.endDate == record.endDate &&
              value.paidAt == record.paidAt,
        ),
      ),
      write: () => provider.saveSubscription(record),
    ),
  );

  @override
  MutationHandle deleteSubscription(
    SubscriptionRecord record, {
    required String operationId,
  }) => _memberGate.run(
    record.memberId,
    () => _submit(
      id: operationId,
      target: record.memberId,
      action: MutationAction.deleteSubscription,
      targetName: _memberName(record.memberId),
      observation: _observed(
        _subscriptions,
        (records) => !records.any((value) => value.id == record.id),
      ),
      write: () => provider.deleteSubscription(record.id),
    ),
  );

  @override
  MutationHandle saveDropin(Dropin record, {required String operationId}) =>
      _submit(
        id: operationId,
        target: record.id,
        action: MutationAction.saveDropin,
        targetName: record.name,
        observation: _observed(
          _dropins,
          (records) => records.any(
            (value) =>
                value.id == record.id &&
                value.name == record.name &&
                value.amount == record.amount &&
                value.date == record.date,
          ),
        ),
        write: () => provider.saveDropin(record),
      );

  @override
  MutationHandle deleteDropin(Dropin record, {required String operationId}) =>
      _submit(
        id: operationId,
        target: record.id,
        action: MutationAction.deleteDropin,
        targetName: record.name,
        observation: _observed(
          _dropins,
          (records) => !records.any((value) => value.id == record.id),
        ),
        write: () => provider.deleteDropin(record.id),
      );

  @override
  MutationHandle saveSettings(
    GymSettings settings, {
    required String operationId,
  }) => _submit(
    id: operationId,
    target: uid,
    action: MutationAction.saveSettings,
    targetName: settings.gymName,
    observation: _observed(
      _settings,
      (value) =>
          value != null &&
          value.gymName == settings.gymName &&
          value.subscriptionPrice == settings.subscriptionPrice &&
          value.dropinPrice == settings.dropinPrice,
    ),
    write: () => provider.saveSettings(settings),
  );

  @override
  MutationHandle deleteMemberCascade(
    String memberId,
    List<String> subscriptionIds, {
    required String operationId,
  }) => _memberGate.run(memberId, () {
    final members = currentMembers;
    final history = currentSubscriptions;
    if (members == null ||
        history == null ||
        !members.isComplete ||
        !history.isComplete) {
      throw const AppFailure(FailureKind.incompleteData);
    }
    if (!members.data.any((m) => m.id == memberId)) {
      throw const AppFailure(FailureKind.notFound);
    }
    final actual = history.data
        .where((r) => r.memberId == memberId)
        .map((r) => r.id)
        .toSet();
    if (actual.length > MemberCascadeLimit.subscriptions) {
      throw const AppFailure(FailureKind.tooLarge);
    }
    if (actual.length != subscriptionIds.length ||
        actual.length != subscriptionIds.toSet().length ||
        !actual.containsAll(subscriptionIds)) {
      throw const AppFailure(FailureKind.conflict, code: 'stale-history');
    }
    return _submit(
      id: operationId,
      target: memberId,
      action: MutationAction.deleteMember,
      targetName: _memberName(memberId),
      observation: _observeCascade(memberId),
      write: () =>
          provider.deleteMemberWithSubscriptions(memberId, subscriptionIds),
    );
  });

  Stream<bool> _observeCascade(String memberId) {
    final beforeMembers = _members.latest;
    final beforeHistory = _subscriptions.latest;
    return Stream<bool>.multi((sink) {
      void check() {
        final members = _members.latest;
        final history = _subscriptions.latest;
        final changed =
            !identical(members, beforeMembers) ||
            !identical(history, beforeHistory);
        sink.add(
          changed &&
              members != null &&
              history != null &&
              !members.data.any((member) => member.id == memberId) &&
              !history.data.any((record) => record.memberId == memberId),
        );
      }

      final memberSubscription = _members.watch().listen(
        (_) => check(),
        onError: sink.addError,
      );
      final historySubscription = _subscriptions.watch().listen(
        (_) => check(),
        onError: sink.addError,
      );
      sink.onCancel = () async {
        await memberSubscription.cancel();
        await historySubscription.cancel();
      };
    });
  }

  String? _memberName(String id) {
    for (final member in currentMembers?.data ?? const <Member>[]) {
      if (member.id == id) return member.name;
    }
    return null;
  }

  @override
  Future<void> close() async {
    await _registry.close();
    await Future.wait([
      _members.close(),
      _subscriptions.close(),
      _dropins.close(),
      _settings.close(),
    ]);
  }
}
