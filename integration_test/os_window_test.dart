import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymk_app/app/app_runtime.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/core/ui/adaptive/app_layout_mode.dart';
import 'package:gymk_app/core/ui/adaptive/app_layout_scope.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/auth_cubit.dart';
import 'package:gymk_app/features/auth/business_logic/cubit/mutation_feedback_cubit.dart';
import 'package:gymk_app/features/auth/data/providers/firebase_auth_provider.dart';
import 'package:gymk_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:gymk_app/features/members/business_logic/cubit/members_cubit.dart';
import 'package:gymk_app/features/members/presentation/views/members_view.dart';
import 'package:gymk_app/features/members/presentation/widgets/member_row.dart';
import 'package:gymk_app/features/subscriptions/business_logic/policies/subscription_policy.dart';

import '../test/support/fake_clock.dart';
import 'support/emulator_fixture.dart';

// Coordinates actual OS changes/screenshots with tool/verify_android_windows.ps1.
// No TestFlutterView size, scale, or inset overrides are used in this test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real Android windows preserve query and open form drafts', (
    tester,
  ) async {
    final fixture = EmulatorFixture();
    late AuthCubit auth;
    late HttpServer server;
    final acknowledgements = <String, Completer<void>>{};
    await tester.runAsync(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 9876);
      server.listen((request) async {
        final id = request.uri.queryParameters['id'];
        final pending = acknowledgements[id];
        if (pending != null && !pending.isCompleted) pending.complete();
        request.response.write('ok');
        await request.response.close();
      });
      await fixture.start('gymk-os-windows');
      final collection = fixture.firestore
          .collection('users')
          .doc(fixture.repository.uid)
          .collection('members');
      final batch = fixture.firestore.batch();
      for (var i = 0; i < 400; i++) {
        batch.set(collection.doc('window-$i'), {
          'name': 'عضو تجربة ${i.toString().padLeft(3, '0')}',
          'phone': '01001234567',
          'createdAt': DateTime.utc(2026, 10, 26),
        });
      }
      await batch.commit();
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
      await auth.stream.firstWhere((s) => s.ready);
    });
    final clock = FakeClock(DateOnly(2026, 11, 10));
    await tester.pumpWidget(
      AppRuntime(
        auth: auth,
        clock: clock,
        createMembers: (repo) => MembersCubit(
          repository: repo,
          policy: SubscriptionPolicy(clock: clock),
        ),
        createFeedback: MutationFeedbackCubit.new,
      ),
    );
    await tester.pumpAndSettle();

    Size logicalSize() =>
        tester.view.physicalSize / tester.view.devicePixelRatio;
    Future<void> window(String id, bool Function(Size) matches) async {
      debugPrint('GYMK_WINDOW_REQUEST $id');
      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (!matches(logicalSize()) && DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      expect(matches(logicalSize()), isTrue, reason: '$id: ${logicalSize()}');
      await tester.pumpAndSettle();
      final scope = tester.element(find.byType(MembersView));
      expect(
        AppLayoutScope.of(scope),
        logicalSize().width < 600 ? AppLayoutMode.mobile : AppLayoutMode.tablet,
      );
      expect(tester.takeException(), isNull);
    }

    Future<void> capture(String id) async {
      final ack = acknowledgements[id] = Completer<void>();
      debugPrint('GYMK_WINDOW_CAPTURE $id size=${logicalSize()}');
      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (!ack.isCompleted && DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        // Render actual OS/IME transition frames during host screenshot capture.
        await tester.pump();
      }
      expect(
        ack.isCompleted,
        isTrue,
        reason: 'No host screenshot acknowledgement: $id',
      );
    }

    Future<void> tap(Finder target) async {
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    await window('phone', (s) => s.width == 390);
    final members = tester
        .element(find.byType(MembersView))
        .read<MembersCubit>();
    expect(members.state.rows, hasLength(400));
    expect(find.byType(MemberRow).evaluate().length, lessThan(50));
    await capture('phone');
    final search = find.widgetWithText(TextFormField, 'ابحث بالاسم');
    await tester.enterText(search, '099');
    final searchController = tester.widget<TextFormField>(search).controller;
    await tester.pumpAndSettle();
    for (final width in [599, 600]) {
      final id = 'width$width';
      await window(id, (s) => s.width == width);
      expect(
        tester.widget<TextFormField>(search).controller,
        same(searchController),
      );
      expect(members.state.query, '099');
      expect(members.state.rows, hasLength(1));
      expect(
        tester.element(find.byType(MembersView)).read<MembersCubit>(),
        same(members),
      );
      await capture(id);
    }
    await tap(find.text('إضافة عضو'));
    final name = find.widgetWithText(TextFormField, 'اسم العضو');
    await tester.enterText(name, 'مسودة محفوظة خلال تغيير النافذة');
    final controller = tester.widget<TextFormField>(name).controller;
    for (final id in [
      'width601',
      'tablet',
      'keyboard',
      'largeText',
      'landscape',
      'split',
      'wideSplit',
    ]) {
      if (id == 'keyboard') {
        final center = tester.getCenter(name);
        debugPrint(
          'GYMK_WINDOW_KEYBOARD ${center.dx.round()} ${center.dy.round()}',
        );
      }
      await window(
        id,
        (s) => switch (id) {
          'width601' => s.width == 601,
          'tablet' || 'largeText' => s.width == 1024,
          'wideSplit' => s.width >= 1000 && s.width < 1100,
          'keyboard' => s.width == 1024 && tester.view.viewInsets.bottom > 0,
          'landscape' => s.width == 840 && s.height == 390,
          'split' => s.width < 600,
          _ => false,
        },
      );
      if (id == 'largeText') {
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (MediaQuery.textScalerOf(tester.element(name)).scale(16) < 25 &&
            DateTime.now().isBefore(deadline)) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
        }
        expect(
          MediaQuery.textScalerOf(tester.element(name)).scale(16),
          greaterThan(25),
        );
      }
      expect(tester.widget<TextFormField>(name).controller, same(controller));
      expect(controller!.text, 'مسودة محفوظة خلال تغيير النافذة');
      expect(fixture.repository.currentMembers!.data, hasLength(400));
      await capture(id);
    }
    await tester.runAsync(fixture.firestore.disableNetwork);
    await tap(find.text('حفظ'));
    await tester.runAsync(() async {
      await fixture.repository.watchMembers().firstWhere(
        (s) => s.data.length == 401,
      );
    });
    await tester.pumpAndSettle();
    expect(fixture.repository.mutations.where((m) => m.pending), hasLength(1));
    await tester.enterText(search, '');
    await tap(find.text('الحصص'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'الاسم (اختياري)'),
      'مسودة حصة',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'المبلغ بالجنيه'),
      '60',
    );
    await tester.pumpAndSettle();
    // Other screen/form combinations and all breakpoints are exercised by the
    // full widget matrix; this target specifically verifies real window events.
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      await fixture.firestore.enableNetwork();
      await fixture.confirmed();
      await server.close(force: true);
    });
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(fixture.close);
    debugPrint('GYMK_WINDOWS_VERIFIED');
  }, timeout: const Timeout(Duration(minutes: 12)));
}
