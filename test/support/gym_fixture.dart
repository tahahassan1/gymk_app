import 'dart:async';

import 'package:gymk_app/app/session/data/providers/gym_data_provider.dart';
import 'package:gymk_app/app/session/data/repositories/firestore_gym_repository.dart';
import 'package:gymk_app/core/data/read_snapshot.dart';
import 'package:gymk_app/features/members/data/models/member.dart';
import 'package:gymk_app/features/subscriptions/data/models/subscription_record.dart';
import 'package:gymk_app/features/dropins/data/models/dropin.dart';
import 'package:gymk_app/features/settings/data/models/gym_settings.dart';

import 'fake_gym_repository.dart';

/// Real repository/mutation machinery with a deterministic typed SDK boundary.
class GymFixture implements GymDataProvider {
  GymFixture() {
    repository = FirestoreGymRepository(this);
    publish();
  }
  late final FirestoreGymRepository repository;
  final memberSource = StreamController<ReadSnapshot<List<Member>>>.broadcast(
    sync: true,
  );
  final historySource =
      StreamController<ReadSnapshot<List<SubscriptionRecord>>>.broadcast(
        sync: true,
      );
  final dropinSource = StreamController<ReadSnapshot<List<Dropin>>>.broadcast(
    sync: true,
  );
  final settingsSource = StreamController<ReadSnapshot<GymSettings?>>.broadcast(
    sync: true,
  );
  List<Member> memberRecords = [];
  List<SubscriptionRecord> history = [];
  List<Dropin> sessions = [];
  GymSettings defaults = GymSettings(
    gymName: 'جيمك',
    subscriptionPrice: 100,
    dropinPrice: 20,
  );
  bool complete = true;
  bool delayLocal = false;
  Completer<void>? remote;
  int writes = 0;
  int _ids = 0;
  void Function()? _local;
  @override
  String get uid => 'fixture-owner';
  @override
  String newId() => 'intent-${++_ids}';
  void publish() {
    memberSource.add(
      snapshot(List<Member>.of(memberRecords), complete: complete),
    );
    historySource.add(
      snapshot(List<SubscriptionRecord>.of(history), complete: complete),
    );
    dropinSource.add(snapshot(List<Dropin>.of(sessions), complete: complete));
    settingsSource.add(snapshot<GymSettings?>(defaults, complete: complete));
  }

  void applyLocal() {
    _local?.call();
    _local = null;
    publish();
  }

  Future<void> _write(void Function() action) {
    writes++;
    _local = action;
    if (!delayLocal) applyLocal();
    return remote?.future ?? Future.value();
  }

  @override
  Stream<ReadSnapshot<List<Member>>> members() => memberSource.stream;
  @override
  Stream<ReadSnapshot<List<SubscriptionRecord>>> subscriptions() =>
      historySource.stream;
  @override
  Stream<ReadSnapshot<List<Dropin>>> dropins() => dropinSource.stream;
  @override
  Stream<ReadSnapshot<GymSettings?>> settings() => settingsSource.stream;
  @override
  Future<void> saveMember(Member member) => _write(() {
    memberRecords.removeWhere((m) => m.id == member.id);
    memberRecords.add(member);
  });
  @override
  Future<void> saveSubscription(SubscriptionRecord record) => _write(() {
    history.removeWhere((r) => r.id == record.id);
    history.add(record);
  });
  @override
  Future<void> deleteSubscription(String id) =>
      _write(() => history.removeWhere((r) => r.id == id));
  @override
  Future<void> deleteMemberWithSubscriptions(
    String memberId,
    List<String> subscriptionIds,
  ) => _write(() {
    memberRecords.removeWhere((m) => m.id == memberId);
    history.removeWhere((r) => subscriptionIds.contains(r.id));
  });
  @override
  Future<void> saveDropin(Dropin record) => _write(() {
    sessions.removeWhere((r) => r.id == record.id);
    sessions.add(record);
  });
  @override
  Future<void> deleteDropin(String id) =>
      _write(() => sessions.removeWhere((r) => r.id == id));
  @override
  Future<void> saveSettings(GymSettings value) =>
      _write(() => defaults = value);
  @override
  Future<void> ensureInitialSettings(GymSettings value) async {}
  Future<void> close() async {
    await repository.close();
    await Future.wait([
      memberSource.close(),
      historySource.close(),
      dropinSource.close(),
      settingsSource.close(),
    ]);
  }
}
