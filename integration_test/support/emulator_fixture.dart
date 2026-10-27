import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gymk_app/app/initialize_firebase.dart';
import 'package:gymk_app/app/session/data/providers/firestore_gym_data_provider.dart';
import 'package:gymk_app/app/session/data/repositories/firestore_gym_repository.dart';
import 'package:gymk_app/features/settings/data/models/gym_settings.dart';

/// Isolated demo services; never authenticates or writes against production.
final class EmulatorFixture {
  late final FirebaseApp app;
  late final FirebaseAuth auth;
  late final FirebaseFirestore firestore;
  late final FirestoreGymRepository repository;
  Future<void> start(String name) async {
    await initializeFirebase();
    app = await Firebase.initializeApp(
      name: name,
      options: const FirebaseOptions(
        apiKey: 'demo-gymk-api-key',
        appId: '1:1234567890:android:1234567890abcdef',
        messagingSenderId: '1234567890',
        projectId: 'demo-gymk',
      ),
    );
    auth = FirebaseAuth.instanceFor(app: app);
    firestore = FirebaseFirestore.instanceFor(app: app);
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    firestore.useFirestoreEmulator('10.0.2.2', 8080);
    await auth.useAuthEmulator('10.0.2.2', 9099);
    await auth.signOut();
    final uid = (await auth.signInAnonymously()).user!.uid;
    repository = FirestoreGymRepository(
      FirestoreGymDataProvider(firestore: firestore, uid: uid),
    );
    await repository.ensureInitialSettings(
      GymSettings(
        gymName: 'جيم الاختبار',
        subscriptionPrice: 100,
        dropinPrice: 20,
      ),
    );
    await confirmed();
  }

  Future<void> confirmed() async {
    await Future.wait([
      repository.watchMembers().firstWhere(
        (s) => s.isComplete && !s.hasPendingWrites,
      ),
      repository.watchSubscriptions().firstWhere(
        (s) => s.isComplete && !s.hasPendingWrites,
      ),
      repository.watchDropins().firstWhere(
        (s) => s.isComplete && !s.hasPendingWrites,
      ),
      repository.watchSettings().firstWhere(
        (s) => s.isComplete && !s.hasPendingWrites,
      ),
    ]).timeout(const Duration(seconds: 30));
  }

  Future<void> close() async {
    await repository.close();
    await firestore.enableNetwork();
    await auth.signOut();
    await firestore.terminate();
    await app.delete();
  }
}
