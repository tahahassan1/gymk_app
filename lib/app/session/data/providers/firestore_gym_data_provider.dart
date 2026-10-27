import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/model_validation.dart';
import '../../../../core/data/read_snapshot.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../features/dropins/data/models/dropin.dart';
import '../../../../features/members/data/models/member.dart';
import '../../../../features/settings/data/models/gym_settings.dart';
import '../../../../features/subscriptions/data/models/subscription_record.dart';
import 'firebase_failure.dart';
import 'gym_data_provider.dart';
import 'provider_stream.dart';
import 'record_codecs.dart';

/// Captures one tenant. Firebase paths, snapshots and serialization end here.
final class FirestoreGymDataProvider implements GymDataProvider {
  FirestoreGymDataProvider({required this.firestore, required String uid})
    : uid = documentId(uid);

  final FirebaseFirestore firestore;
  @override
  final String uid;

  DocumentReference<Map<String, dynamic>> get _user =>
      firestore.collection('users').doc(uid);

  @override
  String newId() => _user.collection('members').doc().id;

  @override
  Stream<ReadSnapshot<List<Member>>> members() =>
      _collection('members', RecordCodecs.member);
  @override
  Stream<ReadSnapshot<List<SubscriptionRecord>>> subscriptions() =>
      _collection('subscriptions', RecordCodecs.subscription);
  @override
  Stream<ReadSnapshot<List<Dropin>>> dropins() =>
      _collection('dropins', RecordCodecs.dropin);

  Stream<ReadSnapshot<List<T>>> _collection<T>(
    String name,
    T Function(String, Map<String, dynamic>) decode,
  ) {
    var confirmed = false;
    return providerStream(
      _user.collection(name).snapshots(includeMetadataChanges: true),
      (snapshot) {
        confirmed = confirmed || !snapshot.metadata.isFromCache;
        return ReadSnapshot<List<T>>(
          data: List.unmodifiable(
            snapshot.docs.map((doc) => decode(doc.id, doc.data())),
          ),
          fromCache: snapshot.metadata.isFromCache,
          hasPendingWrites: snapshot.metadata.hasPendingWrites,
          isComplete: confirmed,
        );
      },
      onFailure: () => confirmed = false,
    );
  }

  @override
  Stream<ReadSnapshot<GymSettings?>> settings() {
    var confirmed = false;
    return providerStream(_user.snapshots(includeMetadataChanges: true), (
      snapshot,
    ) {
      confirmed = confirmed || !snapshot.metadata.isFromCache;
      final raw = snapshot.data()?['settings'];
      if (snapshot.exists && raw is! Map<String, dynamic>) {
        throw const AppFailure(FailureKind.validation, code: 'settings-map');
      }
      return ReadSnapshot<GymSettings?>(
        data: raw == null
            ? null
            : RecordCodecs.settings(raw as Map<String, dynamic>),
        fromCache: snapshot.metadata.isFromCache,
        hasPendingWrites: snapshot.metadata.hasPendingWrites,
        isComplete: confirmed,
      );
    }, onFailure: () => confirmed = false);
  }

  @override
  Future<void> saveMember(Member member) => _user
      .collection('members')
      .doc(member.id)
      .set(RecordCodecs.memberData(member));
  @override
  Future<void> saveSubscription(SubscriptionRecord record) => _user
      .collection('subscriptions')
      .doc(record.id)
      .set(RecordCodecs.subscriptionData(record));
  @override
  Future<void> deleteSubscription(String id) =>
      _user.collection('subscriptions').doc(documentId(id)).delete();
  @override
  Future<void> saveDropin(Dropin record) => _user
      .collection('dropins')
      .doc(record.id)
      .set(RecordCodecs.dropinData(record));
  @override
  Future<void> deleteDropin(String id) =>
      _user.collection('dropins').doc(documentId(id)).delete();
  @override
  Future<void> saveSettings(GymSettings settings) => _user.set({
    'settings': RecordCodecs.settingsData(settings),
  }, SetOptions(merge: true));

  @override
  Future<void> ensureInitialSettings(GymSettings defaults) async {
    // Transactions require a server read. They are used only for first-account
    // bootstrap, never normal offline forms; concurrent bootstrap cannot reset
    // another session's already-created settings.
    try {
      await firestore.runTransaction(
        (transaction) async {
          final snapshot = await transaction.get(_user);
          if (!snapshot.exists) {
            transaction.set(_user, {
              'settings': RecordCodecs.settingsData(defaults),
            });
          }
        },
        maxAttempts: 3,
        timeout: const Duration(seconds: 15),
      );
    } catch (error) {
      throw firebaseFailure(error);
    }
  }

  @override
  Future<void> deleteMemberWithSubscriptions(
    String memberId,
    List<String> subscriptionIds,
  ) {
    final batch = firestore.batch();
    for (final id in subscriptionIds) {
      batch.delete(_user.collection('subscriptions').doc(documentId(id)));
    }
    batch.delete(_user.collection('members').doc(documentId(memberId)));
    return batch.commit();
  }
}
