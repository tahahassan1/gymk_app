import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gymk_app/app/initialize_firebase.dart';
import 'package:gymk_app/app/session/data/providers/firestore_gym_data_provider.dart';
import 'package:gymk_app/app/session/data/repositories/firestore_gym_repository.dart';

/// Fixed named demo app deliberately survives the host's Android force-stop.
/// No test-side durable queue, ID file or second application-data store.
final class RestartSession {
  late final FirebaseApp app;
  late final FirebaseAuth auth;
  late final FirebaseFirestore firestore;
  late final FirestoreGymRepository repository;
  Future<void> open({required bool seed}) async {
    await initializeFirebase();
    app = await Firebase.initializeApp(
      name: 'gymk-process-restart',
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
    await firestore.disableNetwork();
    await auth.useAuthEmulator('10.0.2.2', 9099);
    if (seed) {
      await auth.signOut();
      await auth.signInAnonymously();
      await firestore.enableNetwork();
    }
    final user = await auth
        .authStateChanges()
        .firstWhere((u) => u != null)
        .timeout(const Duration(seconds: 20));
    repository = FirestoreGymRepository(
      FirestoreGymDataProvider(firestore: firestore, uid: user!.uid),
    );
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
    ]).timeout(const Duration(minutes: 2));
  }

  Future<void> close() async {
    await repository.close();
    await auth.signOut();
    await firestore.terminate();
    await app.delete();
  }
}
