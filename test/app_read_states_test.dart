import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/errors/app_failure.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/core/ui/app_loading_state.dart';
import 'package:gymk_app/features/dropins/data/models/dropin.dart';
import 'package:gymk_app/features/members/data/models/member.dart';

import 'support/gym_fixture.dart';
import 'support/pump_gym.dart';
import 'app_full_matrix_test.dart' show tapVisible;

void main() {
  testWidgets(
    'initial loading, unverified empty cache, read error and confirmed empty are distinct',
    (tester) async {
      final fixture = GymFixture(publishInitial: false);
      await pumpGym(tester, fixture, settle: false);
      expect(find.byType(AppLoadingState), findsOneWidget);
      expect(find.text('لسه مفيش أعضاء'), findsNothing);
      fixture.complete = false;
      fixture.publish();
      await tester.pumpAndSettle();
      expect(
        find.text('مفيش أعضاء في البيانات المتاحة على الجهاز'),
        findsOneWidget,
      );
      expect(find.text('لسه مفيش أعضاء'), findsNothing);
      fixture.memberRecords = [
        Member(
          id: 'cached',
          name: 'عضو من الكاش',
          createdAt: DateTime(2026, 10, 26),
        ),
      ];
      fixture.publish();
      await tester.pumpAndSettle();
      fixture.memberSource.addError(const AppFailure(FailureKind.unavailable));
      await tester.pumpAndSettle();
      expect(find.text('عضو من الكاش'), findsOneWidget);
      expect(find.text('حاول تاني'), findsOneWidget);
      fixture.memberRecords = [];
      fixture.complete = true;
      fixture.publish();
      await tester.pumpAndSettle();
      expect(find.text('لسه مفيش أعضاء'), findsOneWidget);
      fixture.complete = false;
      fixture.publish();
      await tapVisible(tester, find.text('الحصص'));
      expect(
        find.text('مفيش حصص في البيانات المتاحة لليوم ده'),
        findsOneWidget,
      );
      expect(find.text('مفيش حصص مسجلة في اليوم ده'), findsNothing);
      await tapVisible(tester, find.text('الإحصائيات'));
      expect(find.text('مفيش متحصلات مسجلة للشهر ده'), findsNothing);
      expect(find.text('من البيانات المتاحة فقط'), findsNWidgets(3));
      fixture.complete = true;
      fixture.publish();
      await tester.pumpAndSettle();
      expect(find.text('مفيش متحصلات مسجلة للشهر ده'), findsOneWidget);
    },
  );
  testWidgets(
    'short landscape with keyboard and pending change keeps the open form usable',
    (tester) async {
      final fixture = GymFixture();
      await pumpGym(tester, fixture, width: 840, height: 390, scale: 2);
      await tapVisible(tester, find.text('إضافة عضو'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'اسم العضو'),
        'مسودة في الوضع الأفقي',
      );
      fixture.remote = Completer<void>();
      final handle = fixture.repository.saveDropin(
        Dropin(id: 'pending', amount: 20, date: DateOnly(2026, 11, 10)),
        operationId: 'pending',
      );
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('حفظ'));
      expect(fixture.memberRecords.single.name, 'مسودة في الوضع الأفقي');
      expect(tester.takeException(), isNull);
      fixture.remote!.complete();
      await handle.remoteResult;
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
    },
  );
}
