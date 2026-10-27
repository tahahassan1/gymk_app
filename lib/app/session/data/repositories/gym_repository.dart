import '../../../../core/data/mutation_registry.dart';
import '../../../../core/data/read_snapshot.dart';
import '../../../../features/dropins/data/models/dropin.dart';
import '../../../../features/members/data/models/member.dart';
import '../../../../features/settings/data/models/gym_settings.dart';
import '../../../../features/subscriptions/data/models/subscription_record.dart';

/// Typed account-scoped contracts. No Firebase snapshot or SDK object escapes.
abstract interface class GymRepository {
  String get uid;
  String newId();
  Stream<ReadSnapshot<List<Member>>> watchMembers();
  Stream<ReadSnapshot<List<SubscriptionRecord>>> watchSubscriptions();
  Stream<ReadSnapshot<List<Dropin>>> watchDropins();
  Stream<ReadSnapshot<GymSettings?>> watchSettings();
  ReadSnapshot<List<Member>>? get currentMembers;
  ReadSnapshot<List<SubscriptionRecord>>? get currentSubscriptions;
  ReadSnapshot<List<Dropin>>? get currentDropins;
  ReadSnapshot<GymSettings?>? get currentSettings;
  List<MutationNotice> get mutations;
  Stream<List<MutationNotice>> get mutationChanges;
  void dismissFailure(String operationId);
  Future<void> retryReads();
  Future<void> ensureInitialSettings(GymSettings defaults);
  MutationHandle saveMember(Member member, {required String operationId});
  MutationHandle saveSubscription(
    SubscriptionRecord record, {
    required String operationId,
  });
  MutationHandle deleteSubscription(
    SubscriptionRecord record, {
    required String operationId,
  });
  MutationHandle saveDropin(Dropin record, {required String operationId});
  MutationHandle deleteDropin(Dropin record, {required String operationId});
  MutationHandle saveSettings(
    GymSettings settings, {
    required String operationId,
  });
  MutationHandle deleteMemberCascade(
    String memberId,
    List<String> subscriptionIds, {
    required String operationId,
  });
  Future<void> close();
}
