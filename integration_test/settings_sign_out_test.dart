import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymk_app/app/app_runtime.dart';
import 'package:gymk_app/app/session/data/providers/firestore_gym_data_provider.dart';
import 'package:gymk_app/app/session/data/repositories/firestore_gym_repository.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/auth_cubit.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/mutation_feedback_cubit.dart';
import 'package:gymk_app/features/auth/data/providers/firebase_auth_provider.dart';
import 'package:gymk_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:gymk_app/features/members/business_logic/cubit/members_cubit.dart';
import 'package:gymk_app/features/members/data/models/member.dart';
import 'package:gymk_app/features/members/presentation/views/members_view.dart';
import 'package:gymk_app/features/settings/business_logic/cubit/settings_cubit.dart';
import 'package:gymk_app/features/settings/data/models/gym_settings.dart';
import 'package:gymk_app/features/settings/presentation/widgets/settings_workspace.dart';
import 'package:gymk_app/features/dropins/business_logic/cubit/dropin_form_cubit.dart';
import 'package:gymk_app/features/subscriptions/business_logic/cubit/subscription_form_cubit.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';

import '../test/support/fake_clock.dart';
import 'support/emulator_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native offline settings pending sign-out A-B-A isolation and SDK queue',
    (tester) async {
      final fixture = EmulatorFixture();
      final clock = FakeClock(DateOnly(2026, 11, 10));
      final owned = <FirestoreGymRepository>[];
      late AuthCubit auth;
      late String owner;
      late String email;
      const password = 'emulator-fixture-only-123';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('جيمك — اختبار الإعدادات والخروج')),
        ),
      );
      await tester.runAsync(() async {
        await fixture.start('gymk-settings-sign-out');
        final repo = fixture.repository;
        owner = repo.uid;
        email = 'gymk-${DateTime.now().microsecondsSinceEpoch}@example.test';
        await fixture.auth.currentUser!.linkWithCredential(
          EmailAuthProvider.credential(email: email, password: password),
        );
        final member = Member(
          id: 'pending-delete',
          name: 'عضو أ المحذوف',
          createdAt: DateTime(2026, 10, 26),
        );
        await repo
            .saveMember(member, operationId: repo.newId())
            .remoteResult
            .timeout(const Duration(seconds: 20));
        await fixture.confirmed();
        var first = true;
        auth = AuthCubit(
          authRepository: FirebaseAuthRepository(
            FirebaseAuthProvider(
              firebase: fixture.auth,
              google: GoogleSignIn.instance,
            ),
          ),
          createGymRepository: (uid) {
            if (first && uid == owner) {
              first = false;
              return repo;
            }
            final created = FirestoreGymRepository(
              FirestoreGymDataProvider(firestore: fixture.firestore, uid: uid),
            );
            owned.add(created);
            return created;
          },
          initialSettings: GymSettings(
            gymName: 'جيمك',
            subscriptionPrice: 0,
            dropinPrice: 0,
          ),
        );
        await auth.stream
            .firstWhere((s) => s.ready)
            .timeout(const Duration(seconds: 20));
      });
      await tester.pumpWidget(
        AppRuntime(
          auth: auth,
          clock: clock,
          createMembers: (repo) => MembersCubit(
            repository: repo,
            policy: SubscriptionPolicy(clock: clock),
          ),
          createFeedback: (repo) => MutationFeedbackCubit(repo),
        ),
      );
      await tester.pumpAndSettle();
      final oldMembers = tester
          .element(find.byType(MembersView))
          .read<MembersCubit>();
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      final oldSettings = tester
          .element(find.byType(SettingsWorkspace))
          .read<SettingsCubit>();
      await tester.runAsync(fixture.firestore.disableNetwork);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'اسم الجيم'),
        'جيم خاص بحساب أ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'سعر الاشتراك الافتراضي بالجنيه'),
        '300',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'سعر الحصة الافتراضي بالجنيه'),
        '50',
      );
      await tester.ensureVisible(find.text('حفظ الإعدادات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ الإعدادات'));
      await tester.runAsync(() async {
        await oldSettings.stream
            .firstWhere((s) => s.submission.applied)
            .timeout(const Duration(seconds: 15));
        final repo = fixture.repository;
        final subscription = SubscriptionFormCubit(
          repository: repo,
          policy: SubscriptionPolicy(clock: clock),
          memberId: 'pending-delete',
        );
        final dropin = DropinFormCubit(repository: repo, clock: clock);
        expect(subscription.state.amount, '300');
        expect(dropin.state.amount, '50');
        await subscription.close();
        await dropin.close();
        final created = repo.saveMember(
          Member(
            id: 'pending-create',
            name: 'عضو أ المعلق',
            createdAt: DateTime(2026, 10, 26),
          ),
          operationId: 'create-before-sign-out',
        );
        expect(
          await created.localResult.timeout(const Duration(seconds: 15)),
          isNull,
        );
        final deleted = repo.deleteMemberCascade(
          'pending-delete',
          [],
          operationId: 'delete-before-sign-out',
        );
        expect(
          await deleted.localResult.timeout(const Duration(seconds: 15)),
          isNull,
        );
      });
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('تسجيل الخروج'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تسجيل الخروج'));
      await tester.pumpAndSettle();
      expect(find.text('في تغييرات لسه في الانتظار'), findsOneWidget);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 840);
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      await tester.tap(find.text('أفضل داخل'));
      await tester.pumpAndSettle();
      expect(auth.state.ready, isTrue);
      await tester.ensureVisible(find.text('تسجيل الخروج'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تسجيل الخروج'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('خروج دلوقتي'));
      await tester.runAsync(() async {
        if (auth.state.identity != null) {
          await auth.stream
              .firstWhere((s) => s.identity == null)
              .timeout(const Duration(seconds: 20));
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('تسجيل الدخول بحساب Google'), findsOneWidget);
      expect(oldMembers.isClosed, isTrue);
      expect(oldSettings.isClosed, isTrue);
      expect(find.text('جيم خاص بحساب أ'), findsNothing);
      await tester.runAsync(() async {
        final other = (await fixture.auth.signInAnonymously()).user!.uid;
        expect(other, isNot(owner));
        await fixture.firestore.enableNetwork();
        await auth.stream
            .firstWhere((s) => s.ready && s.identity!.uid == other)
            .timeout(const Duration(seconds: 30));
        final repo = auth.state.repository!;
        final rows = await repo
            .watchMembers()
            .firstWhere((s) => s.isComplete)
            .timeout(const Duration(seconds: 20));
        expect(rows.data, isEmpty);
        expect(repo.currentSettings!.data!.subscriptionPrice, 0);
      });
      await tester.pumpAndSettle();
      expect(find.text('عضو أ المعلق'), findsNothing);
      expect(find.text('جيم خاص بحساب أ'), findsNothing);
      await tester.runAsync(() async {
        await fixture.auth.signOut();
        await fixture.auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await auth.stream
            .firstWhere((s) => s.ready && s.identity!.uid == owner)
            .timeout(const Duration(seconds: 30));
        final repo = auth.state.repository!;
        final rows = await repo
            .watchMembers()
            .firstWhere(
              (s) =>
                  s.isComplete &&
                  !s.hasPendingWrites &&
                  s.data.any((m) => m.id == 'pending-create'),
            )
            .timeout(const Duration(seconds: 30));
        expect(rows.data.any((m) => m.id == 'pending-delete'), isFalse);
        final settings = await repo
            .watchSettings()
            .firstWhere(
              (s) =>
                  s.isComplete &&
                  !s.hasPendingWrites &&
                  s.data?.subscriptionPrice == 300,
            )
            .timeout(const Duration(seconds: 30));
        expect(settings.data!.gymName, 'جيم خاص بحساب أ');
        final server = await fixture.firestore
            .collection('users')
            .doc(owner)
            .collection('members')
            .get();
        expect(server.docs.any((d) => d.id == 'pending-create'), isTrue);
        expect(server.docs.any((d) => d.id == 'pending-delete'), isFalse);
        debugPrint(
          'Native A-B-A: SDK retained A create/delete/settings queue, B stayed isolated, A changes acknowledged on returning.',
        );
      });
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
      await tester.runAsync(() async {
        for (final repo in owned) {
          await repo.close();
        }
        await fixture.close();
      });
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
