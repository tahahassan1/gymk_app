import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/features/settings/presentation/widgets/settings_workspace.dart';
import 'package:gymk_app/features/dropins/data/models/dropin.dart';
import 'package:gymk_app/core/time/date_only.dart';

import '../../support/gym_fixture.dart';
import '../../support/pump_gym.dart';
import '../../support/fake_auth_repository.dart';

void main() {
  for (final width in [390.0, 600.0, 1024.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('settings fit Arabic width $width at $scale', (tester) async {
        final fixture = GymFixture();
        await pumpGym(tester, fixture, width: width, scale: scale);
        await tester.tap(find.text('الإعدادات'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'اسم الجيم'),
          'اسم جيم طويل لاختبار المسودة والكتابة',
        );
        final controller = tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'اسم الجيم'),
            )
            .controller;
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        tester.view.physicalSize = Size(width < 600 ? 1024 : 390, 840);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(
                find.widgetWithText(TextFormField, 'اسم الجيم'),
              )
              .controller,
          same(controller),
        );
        await tester.ensureVisible(find.text('حفظ الإعدادات'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('حفظ الإعدادات'));
        await tester.pumpAndSettle();
        expect(
          fixture.defaults.gymName,
          'اسم جيم طويل لاختبار المسودة والكتابة',
        );
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
      });
    }
  }
  testWidgets(
    'pending sign-out can stay or continue once; dialog survives resize',
    (tester) async {
      final fixture = GymFixture();
      final authentication = FakeAuthRepository();
      await pumpGym(tester, fixture, authentication: authentication);
      fixture.remote = Completer<void>();
      final handle = fixture.repository.saveDropin(
        Dropin(id: 'pending', amount: 20, date: DateOnly(2026, 11, 10)),
        operationId: 'pending-create',
      );
      await tester.pump();
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      final scrollable = find
          .descendant(
            of: find.byType(SettingsWorkspace),
            matching: find.byType(SingleChildScrollView),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('تسجيل الخروج'),
        200,
        scrollable: find
            .descendant(of: scrollable, matching: find.byType(Scrollable))
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('تسجيل الخروج'));
      await tester.pumpAndSettle();
      expect(find.text('في تغييرات لسه في الانتظار'), findsOneWidget);
      tester.view.physicalSize = const Size(600, 840);
      await tester.pumpAndSettle();
      await tester.tap(find.text('أفضل داخل'));
      await tester.pumpAndSettle();
      expect(authentication.signOuts, 0);
      await tester.ensureVisible(find.text('تسجيل الخروج'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تسجيل الخروج'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('خروج دلوقتي'));
      await tester.pumpAndSettle();
      expect(authentication.signOuts, 1);
      fixture.remote!.complete();
      await handle.remoteResult;
    },
  );
}
