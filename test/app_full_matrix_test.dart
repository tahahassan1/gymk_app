import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/core/ui/app_formatters.dart';
import 'package:gymk_app/core/ui/app_date_field.dart';
import 'package:gymk_app/features/members/data/models/member.dart';
import 'package:gymk_app/features/subscriptions/data/models/subscription_record.dart';
import 'package:gymk_app/features/dropins/data/models/dropin.dart';
import 'package:gymk_app/features/statistics/business_logic/policies/monthly_cash_calculator.dart';

import 'support/gym_fixture.dart';
import 'support/pump_gym.dart';

const longName = 'أحمد محمد عبدالرحمن اسم طويل جدًا لاختبار كل شاشات الجيم';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final custom = find.byType(CustomScrollView).last;
    final scroll = find
        .descendant(of: custom, matching: find.byType(Scrollable))
        .first;
    tester.state<ScrollableState>(scroll).position.jumpTo(0);
    await tester.pumpAndSettle();
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(finder, 240, scrollable: scroll);
    }
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  if (finder.hitTestable().evaluate().isEmpty) {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void seed(GymFixture fixture) {
  fixture.memberRecords = [
    Member(
      id: 'member',
      name: longName,
      phone: '01001234567',
      createdAt: DateTime(2026, 10, 26),
    ),
  ];
  fixture.history = [
    SubscriptionRecord(
      id: 'october',
      memberId: 'member',
      startDate: DateOnly(2026, 10, 26),
      endDate: DateOnly(2026, 11, 26),
      amount: 100,
      paidAt: DateOnly(2026, 10, 26),
    ),
    SubscriptionRecord(
      id: 'november',
      memberId: 'member',
      startDate: DateOnly(2026, 11, 26),
      endDate: DateOnly(2026, 12, 26),
      amount: 150,
      paidAt: DateOnly(2026, 11, 10),
    ),
  ];
  fixture.sessions = [
    Dropin(id: 'seed-today', amount: 20, date: DateOnly(2026, 11, 10)),
    Dropin(
      id: 'seed-previous',
      name: 'حصة من شهر سابق',
      amount: 35,
      date: DateOnly(2026, 10, 31),
    ),
  ];
  fixture.publish();
}

void main() {
  for (final width in [
    320.0,
    360.0,
    390.0,
    430.0,
    599.0,
    600.0,
    601.0,
    768.0,
    1024.0,
    1280.0,
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('full screen/form/dialog matrix width $width scale $scale', (
        tester,
      ) async {
        final fixture = GymFixture();
        seed(fixture);
        await pumpGym(tester, fixture, width: width, height: 960, scale: scale);
        await tapVisible(tester, find.text('إضافة عضو'));
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'اسم العضو'),
          'عضو جديد من اختبار العرض',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'رقم الموبايل (اختياري)'),
          '01098765432',
        );
        await tapVisible(tester, find.text('حفظ'));
        expect(fixture.memberRecords, hasLength(2));
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('اشتراك جديد'));
        expect(find.text('اختار العضو'), findsOneWidget);
        await tapVisible(tester, find.text(longName).last);
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'المبلغ بالجنيه'),
          '0',
        );
        await tapVisible(tester, find.text('حفظ الاشتراك'));
        expect(
          find.text('اكتب مبلغ موجب بالجنيه من غير كسور.'),
          findsOneWidget,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'المبلغ بالجنيه'),
          '100',
        );
        await tapVisible(tester, find.byType(AppDateField).last);
        expect(find.byType(DatePickerDialog), findsOneWidget);
        await tapVisible(
          tester,
          find.text(
            MaterialLocalizations.of(
              tester.element(find.byType(DatePickerDialog)),
            ).cancelButtonLabel,
          ),
        );
        await tapVisible(tester, find.text('حفظ الاشتراك'));
        expect(fixture.history, hasLength(3));
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text(longName));
        await tapVisible(tester, find.text('تعديل بيانات العضو'));
        await tester.enterText(
          find.widgetWithText(TextFormField, 'اسم العضو'),
          'مسودة تعديل فقط',
        );
        await tapVisible(tester, find.byTooltip('إغلاق').last);
        expect(fixture.memberRecords.first.name, longName);
        await tapVisible(tester, find.text('تعديل الاشتراك').first);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'المبلغ بالجنيه'),
          '175',
        );
        await tapVisible(tester, find.text('حفظ الاشتراك'));
        await tapVisible(tester, find.text('حذف الاشتراك').first);
        expect(find.text('حذف الاشتراك؟'), findsOneWidget);
        await tapVisible(tester, find.text('رجوع'));
        await tapVisible(tester, find.text('حذف العضو نهائيًا'));
        expect(find.text('حذف $longName؟'), findsOneWidget);
        await tapVisible(tester, find.text('رجوع'));
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.text('الحصص'));
        await tester.enterText(
          find.widgetWithText(TextFormField, 'الاسم (اختياري)'),
          'اسم حصة طويل لاختبار الكتابة والعرض',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'المبلغ بالجنيه'),
          '25',
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('سجّل حصة'));
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('تعديل الحصة').first);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'المبلغ بالجنيه').last,
          '30',
        );
        await tapVisible(tester, find.byType(AppDateField).last);
        expect(find.byType(DatePickerDialog), findsOneWidget);
        await tapVisible(
          tester,
          find.text(
            MaterialLocalizations.of(
              tester.element(find.byType(DatePickerDialog)),
            ).cancelButtonLabel,
          ),
        );
        await tapVisible(tester, find.text('حفظ الحصة'));
        await tapVisible(tester, find.text('حذف الحصة').first);
        expect(find.text('حذف الحصة؟'), findsOneWidget);
        await tapVisible(tester, find.text('رجوع'));
        await tapVisible(tester, find.text('الإحصائيات'));
        expect(find.text('إجمالي المتحصلات'), findsOneWidget);
        final cash = MonthlyCashCalculator.calculate(
          DateOnly(2026, 11, 1),
          fixture.history,
          fixture.sessions,
        );
        expect(find.text(AppFormatters.totalMoney(cash.total)), findsOneWidget);
        await tapVisible(tester, find.byIcon(Icons.calendar_month).last);
        expect(find.text('اختار الشهر'), findsOneWidget);
        await tapVisible(
          tester,
          find.text(AppFormatters.month(DateOnly(2026, 10, 1))),
        );
        expect(
          find.text(AppFormatters.month(DateOnly(2026, 10, 1))),
          findsOneWidget,
        );
        await tapVisible(tester, find.text('الإعدادات'));
        await tester.enterText(
          find.widgetWithText(TextFormField, 'اسم الجيم'),
          'اسم جيم طويل محفوظ من الاختبار',
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('حفظ الإعدادات'));
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        fixture.remote = Completer<void>();
        final pending = fixture.repository.saveDropin(
          Dropin(id: 'pending-matrix', amount: 5, date: DateOnly(2026, 11, 10)),
          operationId: 'pending-matrix',
        );
        await tester.pump();
        await tapVisible(tester, find.text('تسجيل الخروج'));
        expect(find.text('في تغييرات لسه في الانتظار'), findsOneWidget);
        await tapVisible(tester, find.text('أفضل داخل'));
        fixture.remote!.complete();
        await pending.remoteResult;
        await tester.pumpAndSettle();
        if (width == 390 && scale == 1) {
          final semantics = tester.ensureSemantics();
          try {
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
          } finally {
            semantics.dispose();
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
