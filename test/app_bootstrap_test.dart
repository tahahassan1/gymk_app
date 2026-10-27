import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/app/app_bootstrap.dart';
import 'package:gymk_app/core/ui/app_button.dart';
import 'package:gymk_app/core/ui/app_loading_state.dart';

void main() {
  for (final width in [390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'bootstrap loading/error/retry is Arabic and bounded at $width, scale $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 600);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          var attempts = 0;
          var readyBuilds = 0;
          var pending = Completer<void>();
          await tester.pumpWidget(
            AppBootstrap(
              initialize: () {
                attempts++;
                return pending.future;
              },
              readyBuilder: () {
                readyBuilds++;
                return const MaterialApp(home: Text('جاهز'));
              },
            ),
          );
          expect(find.byType(AppLoadingState), findsOneWidget);
          expect(
            Directionality.of(tester.element(find.byType(AppLoadingState))),
            TextDirection.rtl,
          );
          pending.completeError(StateError('initialization failed'));
          await tester.pump();
          expect(find.text('مش قادرين نبدأ التطبيق'), findsOneWidget);
          pending = Completer<void>();
          await tester.tap(find.widgetWithText(AppButton, 'حاول تاني'));
          await tester.pump();
          expect(attempts, 2);
          pending.complete();
          await tester.pump();
          expect(find.text('جاهز'), findsOneWidget);
          tester.view.physicalSize = Size(width == 390 ? 768 : 390, 600);
          await tester.pump();
          expect(readyBuilds, 1);
          expect(attempts, 2);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
