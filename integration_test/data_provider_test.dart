import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymk_app/app/session/data/providers/firestore_gym_data_provider.dart';
import 'package:gymk_app/app/initialize_firebase.dart';
import 'package:gymk_app/app/session/data/repositories/firestore_gym_repository.dart';
import 'package:gymk_app/core/data/mutation_registry.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/features/dropins/data/models/dropin.dart';
import 'package:gymk_app/features/members/data/models/member.dart';
import 'package:gymk_app/features/settings/data/models/gym_settings.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native persistence, local application, eventual rejection and tenant isolation',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Gymk — isolated SDK verification')),
        ),
      );
      await tester.runAsync(() async {
        await initializeFirebase();
        expect(FirebaseFirestore.instance.settings.persistenceEnabled, isTrue);
        expect(
          FirebaseFirestore.instance.settings.cacheSizeBytes,
          Settings.CACHE_SIZE_UNLIMITED,
        );
        final app = await Firebase.initializeApp(
          name: 'gymk-integration',
          options: const FirebaseOptions(
            apiKey: 'demo-gymk-api-key',
            appId: '1:1234567890:android:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: 'demo-gymk',
          ),
        );
        final auth = FirebaseAuth.instanceFor(app: app);
        final firestore = FirebaseFirestore.instanceFor(app: app);
        firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        firestore.useFirestoreEmulator('10.0.2.2', 8080);
        await auth.useAuthEmulator('10.0.2.2', 9099);
        await auth.signOut();
        final owned = <FirestoreGymRepository>[];
        addTearDown(() async {
          for (final repository in owned) {
            await repository.close();
          }
          await auth.signOut();
          await firestore.terminate();
          await app.delete();
        });
        final owner = (await auth.signInAnonymously()).user!.uid;
        await firestore.disableNetwork();
        var repository = FirestoreGymRepository(
          FirestoreGymDataProvider(firestore: firestore, uid: owner),
        );
        owned.add(repository);
        final cached = await repository.watchMembers().first.timeout(
          const Duration(seconds: 15),
        );
        expect(cached.fromCache, isTrue);
        expect(cached.isComplete, isFalse);
        expect(cached.data, isEmpty);

        final member = Member(
          id: repository.newId(),
          name: 'عضو تجربة SDK',
          createdAt: DateTime.utc(2026, 10, 27, 10),
        );
        final created = repository.saveMember(
          member,
          operationId: repository.newId(),
        );
        expect(
          await created.localResult.timeout(const Duration(seconds: 15)),
          isNull,
        );
        expect(created.stage, MutationStage.locallyApplied);
        expect(created.pending, isTrue);
        expect(repository.currentMembers!.data.single.id, member.id);
        await firestore.enableNetwork();
        expect(
          await created.remoteResult.timeout(const Duration(seconds: 20)),
          isNull,
        );
        await repository
            .watchMembers()
            .firstWhere(
              (snapshot) => snapshot.isComplete && !snapshot.hasPendingWrites,
            )
            .timeout(const Duration(seconds: 15));

        final defaults = GymSettings(
          gymName: 'جيمك',
          subscriptionPrice: 0,
          dropinPrice: 0,
        );
        await repository.ensureInitialSettings(defaults);
        await repository.ensureInitialSettings(
          GymSettings(
            gymName: 'يجب ألا يستبدل',
            subscriptionPrice: 999,
            dropinPrice: 999,
          ),
        );
        final settings = await repository
            .watchSettings()
            .firstWhere(
              (snapshot) => snapshot.isComplete && snapshot.data != null,
            )
            .timeout(const Duration(seconds: 15));
        expect(settings.data!.gymName, 'جيمك');
        expect(settings.data!.subscriptionPrice, 0);

        await firestore.disableNetwork();
        final invalidCorrection = Member(
          id: member.id,
          name: 'تغيير هيتراجع',
          createdAt: DateTime.utc(2026, 10, 28),
        );
        final rejected = repository.saveMember(
          invalidCorrection,
          operationId: repository.newId(),
        );
        expect(
          await rejected.localResult.timeout(const Duration(seconds: 15)),
          isNull,
        );
        expect(rejected.stage, MutationStage.locallyApplied);
        // Form ownership can end here: the repository still handles this future.
        await firestore.enableNetwork();
        expect(
          (await rejected.remoteResult.timeout(const Duration(seconds: 20)))
              ?.kind,
          FailureKind.permission,
        );
        final rollback = await repository
            .watchMembers()
            .firstWhere(
              (snapshot) =>
                  snapshot.data.any((record) => record.name == member.name),
            )
            .timeout(const Duration(seconds: 15));
        expect(rollback.data.single.createdAt, member.createdAt);
        expect(
          repository.mutations.any(
            (notice) => notice.stage == MutationStage.rejected,
          ),
          isTrue,
        );

        final session = Dropin(
          id: repository.newId(),
          amount: 50,
          date: DateOnly(2026, 10, 27),
        );
        final createIntent = repository.newId();
        final sessionWrite = repository.saveDropin(
          session,
          operationId: createIntent,
        );
        expect(
          repository.saveDropin(session, operationId: createIntent),
          same(sessionWrite),
        );
        expect(
          await sessionWrite.localResult.timeout(const Duration(seconds: 15)),
          isNull,
        );
        expect(
          await sessionWrite.remoteResult.timeout(const Duration(seconds: 20)),
          isNull,
        );
        expect(
          repository.currentDropins!.data.where(
            (record) => record.id == session.id,
          ),
          hasLength(1),
        );
        await firestore.disableNetwork();
        final deletion = repository.deleteDropin(
          session,
          operationId: repository.newId(),
        );
        expect(
          await deletion.localResult.timeout(const Duration(seconds: 15)),
          isNull,
        );
        expect(repository.currentDropins!.data, isEmpty);
        expect(
          repository.mutations.any(
            (notice) => notice.id == deletion.id && notice.pending,
          ),
          isTrue,
        );
        await firestore.enableNetwork();
        expect(
          await deletion.remoteResult.timeout(const Duration(seconds: 20)),
          isNull,
        );
        debugPrint(
          'SDK verification: pending deletion tracked after row disappearance',
        );
        debugPrint(
          'SDK verification: rollback observed; closing first session',
        );
        await repository.close().timeout(const Duration(seconds: 10));
        debugPrint('SDK verification: first session closed');
        await firestore.disableNetwork();
        repository = FirestoreGymRepository(
          FirestoreGymDataProvider(firestore: firestore, uid: owner),
        );
        owned.add(repository);
        final coldProjection = await repository.watchMembers().first.timeout(
          const Duration(seconds: 15),
        );
        expect(coldProjection.data.single.id, member.id);
        expect(
          coldProjection.isComplete,
          isFalse,
          reason: 'A new repository does not inherit server completeness from cached data',
        );
        debugPrint('SDK verification: cached projection remains incomplete');
        await repository.close().timeout(const Duration(seconds: 10));
        await firestore.enableNetwork();
        await auth.signOut();
        final other = (await auth.signInAnonymously()).user!.uid;
        final otherRepository = FirestoreGymRepository(
          FirestoreGymDataProvider(firestore: firestore, uid: other),
        );
        owned.add(otherRepository);
        final otherData = await otherRepository
            .watchMembers()
            .firstWhere((snapshot) => snapshot.isComplete)
            .timeout(const Duration(seconds: 15));
        expect(otherData.data, isEmpty);
        expect(other, isNot(owner));
        debugPrint('SDK verification: second tenant is isolated');
        await otherRepository.close();
        await auth.signOut();
      });
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
