import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymk_app/app/app_routes.dart';
import 'package:gymk_app/app/app_runtime.dart';
import 'package:gymk_app/app/initialize_firebase.dart';
import 'package:gymk_app/app/session/data/providers/firestore_gym_data_provider.dart';
import 'package:gymk_app/app/session/data/repositories/firestore_gym_repository.dart';
import 'package:gymk_app/core/time/clock.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/auth_cubit.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/mutation_feedback_cubit.dart';
import 'package:gymk_app/features/auth/data/providers/firebase_auth_provider.dart';
import 'package:gymk_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:gymk_app/features/members/business_logic/cubit/members_cubit.dart';
import 'package:gymk_app/features/members/data/models/member.dart';
import 'package:gymk_app/features/settings/data/models/gym_settings.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';

// Anonymous identities are emulator fixtures only. Product sign-in remains Google.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native session restore, settings preservation and A to B teardown',
    (tester) async {
      late FirebaseApp app;
      late FirebaseAuth nativeAuth;
      late FirebaseFirestore firestore;
      late AuthCubit auth;
      final repositories = <FirestoreGymRepository>[];
      final members = <MembersCubit>[];
      final feedback = <MutationFeedbackCubit>[];
      final defaults = GymSettings(
        gymName: 'جيمك',
        subscriptionPrice: 0,
        dropinPrice: 0,
      );

      AuthCubit createAuth() => AuthCubit(
        authRepository: FirebaseAuthRepository(
          FirebaseAuthProvider(
            firebase: nativeAuth,
            google: GoogleSignIn.instance,
          ),
        ),
        createGymRepository: (uid) {
          final repository = FirestoreGymRepository(
            FirestoreGymDataProvider(firestore: firestore, uid: uid),
          );
          repositories.add(repository);
          return repository;
        },
        initialSettings: defaults,
      );

      Future<void> ready() async {
        if (auth.state.ready) return;
        await auth.stream
            .firstWhere((state) => state.ready)
            .timeout(const Duration(seconds: 30));
      }

      void expectSettings(GymSettings expected) {
        final actual = auth.state.repository!.currentSettings!.data!;
        expect(actual.gymName, expected.gymName);
        expect(actual.subscriptionPrice, expected.subscriptionPrice);
        expect(actual.dropinPrice, expected.dropinPrice);
      }

      Widget runtime() => AppRuntime(
        auth: auth,
        createMembers: (repository) {
          final cubit = MembersCubit(
            repository: repository,
            policy: SubscriptionPolicy(clock: const SystemClock()),
          );
          members.add(cubit);
          return cubit;
        },
        createFeedback: (repository) {
          final cubit = MutationFeedbackCubit(repository);
          feedback.add(cubit);
          return cubit;
        },
      );

      await tester.runAsync(() async {
        await initializeFirebase();
        app = await Firebase.initializeApp(
          name: 'gymk-auth-integration',
          options: const FirebaseOptions(
            apiKey: 'demo-gymk-api-key',
            appId: '1:1234567890:android:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: 'demo-gymk',
          ),
        );
        nativeAuth = FirebaseAuth.instanceFor(app: app);
        firestore = FirebaseFirestore.instanceFor(app: app);
        firestore.settings = const Settings(persistenceEnabled: true);
        firestore.useFirestoreEmulator('10.0.2.2', 8080);
        await nativeAuth.useAuthEmulator('10.0.2.2', 9099);
        await nativeAuth.signOut();
        await nativeAuth.signInAnonymously();
        auth = createAuth();
        await ready();
        expectSettings(defaults);
        final custom = GymSettings(
          gymName: 'جيم الحساب أ',
          subscriptionPrice: 345,
          dropinPrice: 40,
        );
        final write = auth.state.repository!.saveSettings(
          custom,
          operationId: auth.state.repository!.newId(),
        );
        expect(
          await write.remoteResult.timeout(const Duration(seconds: 20)),
          isNull,
        );
        // A second online login must not reset the owner's existing prices.
        await auth.close();
        auth = createAuth();
        await ready();
        expectSettings(custom);
        await auth.close();
        // Restore the actual native authenticated identity while Firestore is offline.
        await firestore.disableNetwork();
        auth = createAuth();
        await ready();
        expectSettings(custom);
      });

      await tester.pumpWidget(runtime());
      await tester.pumpAndSettle();
      final shellContext = tester.element(find.byType(NavigationBar));
      final oldMembers = shellContext.read<MembersCubit>();
      final oldFeedback = shellContext.read<MutationFeedbackCubit>();
      final router = GoRouter.of(shellContext);
      router.go('/members/account-a-private');
      await tester.pumpAndSettle();
      final oldRepository = auth.state.repository!;
      await tester.runAsync(() async {
        final member = Member(
          id: oldRepository.newId(),
          name: 'عضو خاص بالحساب أ',
          createdAt: DateTime.now(),
        );
        final pending = oldRepository.saveMember(
          member,
          operationId: oldRepository.newId(),
        );
        expect(await pending.localResult, isNull);
        expect(pending.pending, isTrue);
        expect(oldRepository.currentMembers!.data.single.name, member.name);
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('في انتظار التأكيد'), findsOneWidget);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 800);
      await tester.pumpAndSettle();
      expect(feedback.single, same(oldFeedback));
      expect(
        router.routeInformationProvider.value.uri.path,
        '/members/account-a-private',
      );
      await tester.tap(find.byTooltip('التفاصيل'));
      await tester.pumpAndSettle();
      expect(find.textContaining('عضو خاص بالحساب أ'), findsOneWidget);

      await tester.runAsync(() async {
        await auth.signOut();
        if (auth.state.identity != null) {
          await auth.stream
              .firstWhere((state) => state.identity == null)
              .timeout(const Duration(seconds: 10));
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('تسجيل الدخول بحساب Google'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(oldMembers.isClosed, isTrue);
      expect(oldFeedback.isClosed, isTrue);
      await tester.runAsync(() async {
        await firestore.enableNetwork();
        final next = (await nativeAuth.signInAnonymously()).user!;
        await ready();
        expect(auth.state.identity!.uid, next.uid);
        expect(auth.state.repository!.uid, isNot(oldRepository.uid));
        expectSettings(defaults);
        final snapshot = await auth.state.repository!.watchMembers().firstWhere(
          (snapshot) => snapshot.isComplete,
        );
        expect(snapshot.data, isEmpty);
        expect(oldRepository.currentMembers, isNull);
      });
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.members);
      expect(find.textContaining('في انتظار التأكيد'), findsNothing);
      expect(find.text('عضو خاص بالحساب أ'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.runAsync(() async {
        for (final repository in repositories) {
          await repository.close();
        }
        await nativeAuth.signOut();
        await firestore.terminate();
        await app.delete();
      });
    },
  );
}
