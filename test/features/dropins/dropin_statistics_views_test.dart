import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/time/date_only.dart';
import 'package:gymk_app/features/dropins/business_logic/cubit/dropins_cubit.dart';
import 'package:gymk_app/features/dropins/presentation/widgets/dropins_workspace.dart';
import 'package:gymk_app/features/dropins/data/models/dropin.dart';
import 'package:gymk_app/features/statistics/business_logic/cubit/statistics_cubit.dart';
import 'package:gymk_app/features/statistics/presentation/widgets/statistics_controls.dart';

import '../../support/gym_fixture.dart';
import '../../support/pump_gym.dart';

void main() {
  for (final width in [390.0, 600.0, 1024.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('drop-ins and reports Arabic $width at $scale', (
        tester,
      ) async {
        final fixture = GymFixture();
        fixture.sessions = [
          Dropin(
            id: 'one',
            name: 'اسم طويل للحصة الفردية في الجيم لاختبار الالتفاف',
            amount: 25,
            date: DateOnly(2026, 11, 10),
          ),
        ];
        fixture.publish();
        await pumpGym(tester, fixture, width: width, scale: scale);
        await tester.tap(find.text('الحصص'));
        await tester.pumpAndSettle();
        expect(find.text('الاسم (اختياري)'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.enterText(
          find.widgetWithText(TextFormField, 'الاسم (اختياري)'),
          'مسودة حصة',
        );
        tester.view.physicalSize = Size(width < 600 ? 768 : 390, 840);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextFormField, 'مسودة حصة'), findsOneWidget);
        await tester.tap(find.text('الإحصائيات'));
        await tester.pumpAndSettle();
        expect(find.text('إجمالي المتحصلات'), findsOneWidget);
        expect(find.text('مفيش متحصلات مسجلة للشهر ده'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'day/month selection and quick draft survive breakpoint; edit date moves totals',
    (tester) async {
      final fixture = GymFixture();
      await pumpGym(tester, fixture, width: 599);
      await tester.tap(find.text('الحصص'));
      await tester.pumpAndSettle();
      final list = tester
          .element(find.byType(DropinsWorkspace))
          .read<DropinsCubit>();
      list.dayChanged(DateOnly(2026, 10, 31));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'الاسم (اختياري)'),
        'حصة تجريبية',
      );
      final controller = tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'الاسم (اختياري)'),
          )
          .controller;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      for (final width in [600.0, 601.0, 1024.0, 599.0]) {
        tester.view.physicalSize = Size(width, 840);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(
                find.widgetWithText(TextFormField, 'الاسم (اختياري)'),
              )
              .controller,
          same(controller),
        );
        expect(list.state.day, DateOnly(2026, 10, 31));
      }
      await tester.ensureVisible(find.text('سجّل حصة'));
      await tester.tap(find.text('سجّل حصة'));
      await tester.pumpAndSettle();
      expect(fixture.sessions.single.date, DateOnly(2026, 11, 10));
      expect(list.state.day, DateOnly(2026, 10, 31));
      tester.view.resetViewInsets();
      list.showToday();
      await tester.pumpAndSettle();
      await tester.tap(find.text('الإحصائيات'));
      await tester.pumpAndSettle();
      final report = tester
          .element(find.byType(StatisticsControls))
          .read<StatisticsCubit>();
      report.monthChanged(DateOnly(2026, 10, 1));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(600, 840);
      await tester.pumpAndSettle();
      expect(report.state.month, DateOnly(2026, 10, 1));
      report.monthChanged(DateOnly(2026, 11, 1));
      await tester.pumpAndSettle();
      expect(report.state.cash.dropinIncome, BigInt.from(20));
      await tester.tap(find.byTooltip('الشهر السابق'));
      await tester.pumpAndSettle();
      expect(report.state.month, DateOnly(2026, 10, 1));
      await tester.tap(find.byTooltip('الشهر التالي'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.calendar_month).last);
      await tester.pumpAndSettle();
      expect(find.text('اختار الشهر'), findsOneWidget);
      await tester.tap(find.text('رجوع'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
