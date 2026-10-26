import 'package:flutter/widgets.dart';

abstract final class AppGeometry {
  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space24 = 24.0;
  static const space32 = 32.0;
  static const controlHeight = 52.0;
  static const touchTarget = 48.0;
  static const formWidth = 560.0;
  static const contentWidth = 1040.0;
  static const radius = BorderRadius.all(Radius.circular(12));
  static const sheetRadius = BorderRadius.vertical(top: Radius.circular(20));
  static const shadowOffset = Offset(3, 3);
  static const motionDuration = Duration(milliseconds: 160);
}
