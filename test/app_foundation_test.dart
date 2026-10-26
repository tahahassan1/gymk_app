import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/app/app.dart';
import 'package:gymk_app/app/app_routes.dart';
import 'package:gymk_app/app/router.dart';
import 'package:gymk_app/core/ui/adaptive/app_layout_mode.dart';
import 'package:gymk_app/core/ui/adaptive/app_layout_scope.dart';
import 'package:gymk_app/core/ui/app_button.dart';
import 'package:gymk_app/core/ui/app_loading_state.dart';
import 'package:gymk_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

Future<GoRouter> pumpApp(
  WidgetTester tester, {
  double width = 390,
  double height = 800,
  double textScale = 1,
  String location = AppRoutes.members,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = createAppRouter(initialLocation: location);
  await tester.pumpWidget(GymkApp(router: router));
  await tester.pump(const Duration(milliseconds: 400));
  return router;
}

void main() {
  testWidgets(
    'Arabic startup replaces the demo and preserves four destinations',
    (tester) async {
      await pumpApp(tester);
      final context = tester.element(find.byType(NavigationBar));
      expect(Directionality.of(context), TextDirection.rtl);
      expect(Localizations.localeOf(context).languageCode, 'ar');
      expect(Theme.of(context).textTheme.bodyLarge!.fontFamily, 'Cairo');
      expect(find.text('جيمك'), findsOneWidget);
      expect(find.text('Flutter Demo'), findsNothing);
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.textContaining('الخدمة هتكون متاحة قريبًا'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Branch history, route and inherited mode survive resize and tab changes',
    (tester) async {
      final router = await pumpApp(tester, width: 599);
      router.go('/members/member-one');
      await tester.pumpAndSettle();
      expect(find.text('بيانات العضو'), findsOneWidget);
      final navigation = find.byType(NavigationBar);
      await tester.tap(
        find.descendant(of: navigation, matching: find.text('الإحصائيات')),
      );
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(600, 800);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.statistics,
      );
      final scope = tester.widget<AppLayoutScope>(find.byType(AppLayoutScope));
      expect(scope.mode, AppLayoutMode.tablet);
      // The content pane is narrower than 600; it must still inherit tablet mode.
      expect(tester.getSize(find.byType(AppLayoutScope)).width, lessThan(600));
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('الأعضاء'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/members/member-one',
      );
      tester.view.physicalSize = const Size(599, 800);
      await tester.pumpAndSettle();
      expect(find.text('بيانات العضو'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 599.0, 600.0, 601.0, 768.0, 1024.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Shell fits width $width with text scale $scale and short height',
        (tester) async {
          await pumpApp(tester, width: width, height: 360, textScale: scale);
          expect(
            find.byType(width < 600 ? NavigationBar : NavigationRail),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Open form preserves controllers, values and validation across resize with keyboard insets',
    (tester) async {
      await pumpApp(tester, location: AppRoutes.foundation);
      final open = find.widgetWithText(AppButton, 'معاينة النموذج');
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.widgetWithText(AppButton, 'حفظ'));
      await tester.pump();
      expect(find.text('اكتب الاسم الأول'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(
        fields.at(0),
        'أحمد محمد عبد الرحمن اسم عربي طويل',
      );
      await tester.enterText(fields.at(1), '01012345678');
      final editable = find.byType(EditableText);
      final controller = tester.widget<EditableText>(editable.first).controller;
      final formState = tester.state(find.byType(Form));
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      tester.view.physicalSize = const Size(768, 600);
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.widget<EditableText>(editable.first).controller,
        same(controller),
      );
      expect(tester.state(find.byType(Form)), same(formState));
      expect(controller.text, 'أحمد محمد عبد الرحمن اسم عربي طويل');
      expect(
        tester.widget<EditableText>(editable.at(1)).textDirection,
        TextDirection.ltr,
      );
      await tester.ensureVisible(find.widgetWithText(AppButton, 'حفظ'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pump();
      await tester.tap(find.widgetWithText(AppButton, 'حفظ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(Form), findsNothing);
      expect(
        find.text('تمت تجربة النموذج. مفيش بيانات اتحفظت.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Supplied loading artwork renders and reduced motion uses a static image',
    (tester) async {
      await pumpApp(tester, location: AppRoutes.foundation);
      await tester.ensureVisible(find.byType(AppLoadingState));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LottieBuilder), findsOneWidget);
      expect(tester.takeException(), isNull);
      final context = tester.element(find.byType(AppLoadingState));
      final data = MediaQuery.of(context).copyWith(disableAnimations: true);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: MediaQuery(
            data: data,
            child: const Scaffold(body: AppLoadingState()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(LottieBuilder), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    },
  );

  testWidgets('Unknown route offers a working recovery action', (tester) async {
    final router = await pumpApp(tester, location: '/missing');
    expect(find.text('مش قادرين نفتح الصفحة'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'الرجوع للأعضاء'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.members);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  for (final width in [320.0, 768.0]) {
    testWidgets('Large-text forms and date/deletion dialogs fit at $width', (
      tester,
    ) async {
      await pumpApp(
        tester,
        width: width,
        height: 700,
        textScale: 2,
        location: AppRoutes.foundation,
      );
      final open = find.widgetWithText(AppButton, 'معاينة النموذج');
      await tester.scrollUntilVisible(
        open,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(open);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(Form), findsOneWidget);
      await tester.ensureVisible(find.widgetWithText(AppButton, 'حفظ'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('إغلاق'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final delete = find.widgetWithText(AppButton, 'معاينة الحذف');
      await tester.scrollUntilVisible(
        delete,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(delete);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('رجوع'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final date = find.text('اختار التاريخ');
      await tester.scrollUntilVisible(
        date,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(date);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(DatePickerDialog))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
