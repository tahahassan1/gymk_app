import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymk_app/core/ui/adaptive/app_adaptive_layout.dart';

void main() {
  testWidgets('599/600/601 select only the required builder', (tester) async {
    var mobileBuilds = 0;
    var tabletBuilds = 0;
    Future<void> render(double width) => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SizedBox(
            width: width,
            child: AppAdaptiveLayout(
              mobileBuilder: (_) {
                mobileBuilds++;
                return const Text('mobile');
              },
              tabletBuilder: (_) {
                tabletBuilds++;
                return const Text('tablet');
              },
            ),
          ),
        ),
      ),
    );
    await render(599);
    expect(find.text('mobile'), findsOneWidget);
    expect((mobileBuilds, tabletBuilds), (1, 0));
    await render(600);
    expect(find.text('tablet'), findsOneWidget);
    expect((mobileBuilds, tabletBuilds), (1, 1));
    await render(601);
    expect((mobileBuilds, tabletBuilds), (1, 2));
  });

  testWidgets('Unbounded width has an explicit failure', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            height: 100,
            child: AppAdaptiveLayout(
              mobileBuilder: (_) => const SizedBox.shrink(),
              tabletBuilder: (_) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    final exception = tester.takeException();
    expect(exception, isA<FlutterError>());
    expect(exception.toString(), contains('bounded parent width'));
  });
}
