import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymk_app/app/app_runtime.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/auth_cubit.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/mutation_feedback_cubit.dart';
import 'package:gymk_app/features/auth/data/providers/firebase_auth_provider.dart';
import 'package:gymk_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:gymk_app/features/members/business_logic/cubit/members_cubit.dart';
import 'package:gymk_app/features/members/data/models/member.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';
import 'package:gymk_app/core/time/date_only.dart';

import '../test/support/fake_clock.dart';
import 'support/emulator_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native Arabic member UI keyboard renewal and resize continuity',
    (tester) async {
      final fixture = EmulatorFixture();
      late AuthCubit auth;
      await tester.runAsync(() async {
        await fixture.start('gymk-member-ui');
        final member = Member(
          id: 'ui-member',
          name: 'أحمد محمد عبدالرحمن تجربة الواجهة',
          phone: '01001234567',
          createdAt: DateTime(2026, 10, 26),
        );
        await fixture.repository
            .saveMember(member, operationId: fixture.repository.newId())
            .remoteResult;
        await fixture.confirmed();
        auth = AuthCubit(
          authRepository: FirebaseAuthRepository(
            FirebaseAuthProvider(
              firebase: fixture.auth,
              google: GoogleSignIn.instance,
            ),
          ),
          createGymRepository: (_) => fixture.repository,
          initialSettings: fixture.repository.currentSettings!.data!,
        );
        await auth.stream
            .firstWhere((s) => s.ready)
            .timeout(const Duration(seconds: 20));
      });
      await tester.pumpWidget(
        AppRuntime(
          auth: auth,
          clock: FakeClock(DateOnly(2026, 11, 10)),
          createMembers: (repo) => MembersCubit(
            repository: repo,
            policy: SubscriptionPolicy(
              clock: FakeClock(DateOnly(2026, 11, 10)),
            ),
          ),
          createFeedback: (repo) => MutationFeedbackCubit(repo),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('إضافة عضو'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextFormField, 'اسم العضو'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'اسم العضو'),
        'عضو مسجل أوفلاين',
      );
      final controller = tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'اسم العضو'),
          )
          .controller;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(768, 840);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'اسم العضو'),
            )
            .controller,
        same(controller),
      );
      await tester.runAsync(fixture.firestore.disableNetwork);
      await tester.ensureVisible(find.text('حفظ'));
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(find.text('عضو مسجل أوفلاين'), findsOneWidget);
      await tester.tap(find.text('أحمد محمد عبدالرحمن تجربة الواجهة'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('جدّد الاشتراك'));
      await tester.tap(find.text('جدّد الاشتراك'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'المبلغ بالجنيه'),
        '150',
      );
      tester.view.physicalSize = const Size(390, 840);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '150'), findsOneWidget);
      await tester.ensureVisible(find.text('حفظ الاشتراك'));
      await tester.tap(find.text('حفظ الاشتراك'));
      await tester.pumpAndSettle();
      expect(fixture.repository.currentSubscriptions!.data.single.amount, 150);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        await fixture.firestore.enableNetwork();
        await fixture.confirmed();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.runAsync(fixture.close);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
