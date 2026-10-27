import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymk_app/app/app_routes.dart';
import 'package:gymk_app/app/app_runtime.dart';
import 'package:gymk_app/core/data/mutation_registry.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/core/ui/app_button.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/auth_cubit.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/mutation_feedback_cubit.dart';
import 'package:gymk_app/features/auth/data/models/auth_identity.dart';
import 'package:gymk_app/features/members/business_logic/cubit/members_cubit.dart';
import 'package:gymk_app/features/settings/data/models/gym_settings.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_clock.dart';
import '../../support/fake_gym_repository.dart';
import '../../support/fake_tenant_repository.dart';

import 'package:gymk_app/core/time/date_only.dart';

Future<AuthCubit> pumpRuntime(
  WidgetTester tester,
  FakeAuthRepository auth, {
  Map<String, FakeTenantRepository> tenants = const {},
  double width = 390,
  double height = 800,
  double scale = 1,
  void Function()? feedbackCreated,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final cubit = (await tester.runAsync(() async {
    final instance = AuthCubit(
      authRepository: auth,
      createGymRepository: (uid) => tenants[uid]!,
      initialSettings: GymSettings(
        gymName: 'جيمك',
        subscriptionPrice: 0,
        dropinPrice: 0,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    return instance;
  }))!;
  await tester.pumpWidget(
    AppRuntime(
      auth: cubit,
      createMembers: (repository) => MembersCubit(
        repository: repository,
        policy: SubscriptionPolicy(clock: FakeClock(DateOnly(2026, 10, 27))),
      ),
      createFeedback: (repository) {
        feedbackCreated?.call();
        return MutationFeedbackCubit(repository);
      },
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 3),
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      await auth.close();
      for (final tenant in tenants.values) {
        await tenant.close();
      }
    });
  });
  return cubit;
}

FakeTenantRepository tenant(String uid) => FakeTenantRepository(
  uid,
  initial: snapshot(
    GymSettings(gymName: 'جيم $uid', subscriptionPrice: 0, dropinPrice: 0),
    complete: false,
  ),
);

void main() {
  for (final width in [320.0, 599.0, 600.0, 601.0, 768.0, 1024.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Google sign-in fits RTL width $width and text scale $scale in a short window',
        (tester) async {
          await pumpRuntime(
            tester,
            FakeAuthRepository(),
            width: width,
            height: 360,
            scale: scale,
          );
          final button = find.widgetWithText(
            AppButton,
            'تسجيل الدخول بحساب Google',
          );
          expect(button, findsOneWidget);
          expect(Directionality.of(tester.element(button)), TextDirection.rtl);
          await tester.ensureVisible(button);
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'an in-flight Google action survives 599 to 600 without another request',
    (tester) async {
      final auth = FakeAuthRepository()
        ..pendingSignIn = Completer<SignInResult>();
      final cubit = await pumpRuntime(tester, auth, width: 599);
      final button = find.widgetWithText(
        AppButton,
        'تسجيل الدخول بحساب Google',
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      tester.view.physicalSize = const Size(600, 800);
      await tester.pump();
      expect(cubit.state.signingIn, isTrue);
      expect(auth.signIns, 1);
      expect(tester.widget<AppButton>(button).busy, isTrue);
      auth.pendingSignIn!.complete(SignInResult.cancelled);
      await tester.pumpAndSettle();
      expect(cubit.state.signingIn, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'account change resets nested history and removes an open form draft',
    (tester) async {
      final auth = FakeAuthRepository(current: AuthIdentity('A'));
      final a = tenant('A');
      final b = tenant('B');
      final cubit = await pumpRuntime(tester, auth, tenants: {'A': a, 'B': b});
      final router = GoRouter.of(tester.element(find.byType(NavigationBar)));
      router.go('/members/private-a');
      await tester.pumpAndSettle();
      router.go(AppRoutes.foundation);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final open = find.widgetWithText(AppButton, 'معاينة النموذج');
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(
        find.byType(TextFormField).first,
        'مسودة الحساب أ',
      );
      auth.change(AuthIdentity('B'));
      await tester.runAsync(() async {
        if (!cubit.state.ready || cubit.state.identity?.uid != 'B') {
          await cubit.stream
              .firstWhere((state) => state.ready && state.identity?.uid == 'B')
              .timeout(const Duration(seconds: 2));
        }
      });
      await tester.pumpAndSettle();
      expect(cubit.state.identity!.uid, 'B');
      expect(a.closed, isTrue);
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.members);
      expect(find.byType(Form), findsNothing);
      expect(find.text('مسودة الحساب أ'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'account change removes an open mutation dialog and its previous gym names',
    (tester) async {
      final auth = FakeAuthRepository(current: AuthIdentity('A'));
      final a = tenant('A');
      final b = tenant('B');
      final cubit = await pumpRuntime(tester, auth, tenants: {'A': a, 'B': b});
      a.emitMutations(const [
        MutationNotice(
          id: 'private-intent',
          target: 'private-member',
          targetName: 'اسم خاص بالحساب أ',
          action: MutationAction.saveMember,
          stage: MutationStage.locallyApplied,
          failure: null,
        ),
      ]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('التفاصيل'));
      await tester.pumpAndSettle();
      expect(find.textContaining('اسم خاص بالحساب أ'), findsOneWidget);
      auth.change(AuthIdentity('B'));
      await tester.runAsync(() async {
        if (!cubit.state.ready || cubit.state.identity?.uid != 'B') {
          await cubit.stream
              .firstWhere((state) => state.ready && state.identity?.uid == 'B')
              .timeout(const Duration(seconds: 2));
        }
      });
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('اسم خاص بالحساب أ'), findsNothing);
      expect(a.closed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [390.0, 768.0]) {
    testWidgets('setup recovery fits width $width with large text', (
      tester,
    ) async {
      final auth = FakeAuthRepository(current: AuthIdentity('A'));
      final repository = FakeTenantRepository(
        'A',
        initial: snapshot<GymSettings?>(null),
      )..bootstrapError = const AppFailure(FailureKind.permission);
      await pumpRuntime(
        tester,
        auth,
        tenants: {'A': repository},
        width: width,
        height: 360,
        scale: 2,
      );
      final retry = find.widgetWithText(AppButton, 'حاول تاني');
      await tester.ensureVisible(retry);
      await tester.pump();
      expect(retry, findsOneWidget);
      expect(find.text('تسجيل الخروج'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'pending/rejected feedback stays visible across resize and dismisses only its message',
    (tester) async {
      final auth = FakeAuthRepository(current: AuthIdentity('A'));
      final repository = tenant('A');
      var feedbackInstances = 0;
      await pumpRuntime(
        tester,
        auth,
        tenants: {'A': repository},
        width: 599,
        feedbackCreated: () => feedbackInstances++,
      );
      repository.emitMutations(const [
        MutationNotice(
          id: 'intent',
          target: 'member',
          targetName: 'أحمد محمد',
          action: MutationAction.deleteMember,
          stage: MutationStage.locallyApplied,
          failure: null,
        ),
      ]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('التفاصيل'));
      await tester.pumpAndSettle();
      expect(find.textContaining('أحمد محمد'), findsOneWidget);
      tester.view.physicalSize = const Size(600, 800);
      await tester.pumpAndSettle();
      expect(feedbackInstances, 1);
      repository.emitMutations(const [
        MutationNotice(
          id: 'intent',
          target: 'member',
          targetName: 'أحمد محمد',
          action: MutationAction.deleteMember,
          stage: MutationStage.rejected,
          failure: AppFailure(FailureKind.permission),
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.textContaining('العملية اترفضت'), findsOneWidget);
      await tester.tap(find.byTooltip('إخفاء الرسالة'));
      await tester.pumpAndSettle();
      expect(repository.mutations, isEmpty);
      expect(find.text('مفيش تغييرات معلقة متابَعة دلوقتي.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
