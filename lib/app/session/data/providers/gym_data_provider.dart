import '../../../../core/data/read_snapshot.dart';
import '../../../../features/dropins/data/models/dropin.dart';
import '../../../../features/members/data/models/member.dart';
import '../../../../features/settings/data/models/gym_settings.dart';
import '../../../../features/subscriptions/data/models/subscription_record.dart';

abstract interface class GymDataProvider {
  String get uid;
  String newId();
  Stream<ReadSnapshot<List<Member>>> members();
  Stream<ReadSnapshot<List<SubscriptionRecord>>> subscriptions();
  Stream<ReadSnapshot<List<Dropin>>> dropins();
  Stream<ReadSnapshot<GymSettings?>> settings();
  Future<void> saveMember(Member member);
  Future<void> saveSubscription(SubscriptionRecord record);
  Future<void> deleteSubscription(String id);
  Future<void> saveDropin(Dropin record);
  Future<void> deleteDropin(String id);
  Future<void> saveSettings(GymSettings settings);
  Future<void> ensureInitialSettings(GymSettings defaults);
  Future<void> deleteMemberWithSubscriptions(
    String memberId,
    List<String> subscriptionIds,
  );
}
