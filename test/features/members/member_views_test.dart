import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/features/members/data/models/member.dart';

import '../../support/gym_fixture.dart';
import '../../support/pump_gym.dart';

void main() {
  testWidgets(
    'hundreds-member list stays lazy and retains scroll across shell layouts',
    (tester) async {
      final fixture = GymFixture();
      fixture.memberRecords = List.generate(
        400,
        (i) => Member(
          id: 'member-$i',
          name: 'عضو ${i.toString().padLeft(3, '0')}',
          createdAt: DateTime(2026, 10, 26),
        ),
      );
      fixture.publish();
      await pumpGym(tester, fixture, width: 599);
      Finder scroll() => find
          .descendant(
            of: find.byType(CustomScrollView).last,
            matching: find.byType(Scrollable),
          )
          .first;
      tester.state<ScrollableState>(scroll()).position.jumpTo(1800);
      await tester.pumpAndSettle();
      for (final width in [600.0, 1024.0, 601.0, 599.0]) {
        tester.view.physicalSize = Size(width, 840);
        await tester.pumpAndSettle();
        expect(tester.state<ScrollableState>(scroll()).position.pixels, 1800);
        expect(tester.takeException(), isNull);
      }
      expect(fixture.writes, 0);
    },
  );
  for (final width in [390.0, 600.0, 1024.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('members and details RTL $width at $scale', (tester) async {
        final fixture = GymFixture();
        fixture.memberRecords = [
          Member(
            id: 'one',
            name: 'أحمد محمد عبدالرحمن اسم طويل جدًا لاختبار عرض العضو',
            phone: '01001234567',
            createdAt: DateTime(2026, 10, 26),
          ),
        ];
        fixture.publish();
        await pumpGym(tester, fixture, width: width, scale: scale);
        expect(
          Directionality.of(tester.element(find.text('ابحث بالاسم'))),
          TextDirection.rtl,
        );
        await tester.scrollUntilVisible(
          find.text(fixture.memberRecords.single.name),
          200,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView).last,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.text(fixture.memberRecords.single.name),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(fixture.memberRecords.single.name));
        await tester.pumpAndSettle();
        expect(find.text('جدّد الاشتراك'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'search/filter and open keyboard form survive 599/600/601; one write on duplicate tap',
    (tester) async {
      final fixture = GymFixture();
      fixture.memberRecords = [
        Member(id: 'one', name: 'أحمد', createdAt: DateTime(2026, 10, 26)),
      ];
      fixture.publish();
      await pumpGym(tester, fixture, width: 599);
      await tester.enterText(find.byType(TextFormField), 'أح');
      for (final width in [600.0, 601.0, 599.0]) {
        tester.view.physicalSize = Size(width, 840);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(TextFormField, 'أح'), findsOneWidget);
      }
      await tester.tap(find.text('إضافة عضو'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'اسم العضو'),
        'عضو جديد',
      );
      final field = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'اسم العضو'),
      );
      final controller = field.controller;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      tester.view.physicalSize = const Size(600, 840);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'اسم العضو'),
            )
            .controller,
        same(controller),
      );
      await tester.ensureVisible(find.text('حفظ'));
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(
        fixture.memberRecords.where((m) => m.name == 'عضو جديد'),
        hasLength(1),
      );
      expect(fixture.writes, 1);
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
    },
  );
  testWidgets(
    'new subscription picker can add and select member without losing parent search',
    (tester) async {
      final fixture = GymFixture();
      await pumpGym(tester, fixture);
      await tester.tap(find.text('اشتراك جديد'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'عضو');
      await tester.tap(find.text('إضافة عضو جديد'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'اسم العضو'),
        'عضو من الاختيار',
      );
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(find.text('عضو من الاختيار').last, findsOneWidget);
      expect(find.text('حفظ الاشتراك'), findsOneWidget);
      tester.view.physicalSize = const Size(768, 840);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('حفظ الاشتراك'));
      await tester.tap(find.text('حفظ الاشتراك'));
      await tester.pumpAndSettle();
      expect(fixture.history.single.memberId, fixture.memberRecords.single.id);
      expect(tester.takeException(), isNull);
    },
  );
}
