import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'cuba_colors.dart';

/// Cuba prints every 2013 plate black on white, so there is one theme. The
/// natural-person/legal-entity difference is the strip, which is geometry and
/// lives on the spec.
abstract final class CubaThemes {
  /// The dark frame is ~3.3 mm on both shapes (3.3 of 110 on the car, measured
  /// off K 000 807 and D 004 027). The motorcycle overrides this on its spec to
  /// keep the same millimetres on a 140 mm plate.
  static const double borderWidthRatio = 0.03;

  /// ~5 mm corners on a 110 mm plate, estimated from the photographs' arcs.
  static const double _plateRadiusRatio = 0.045; // CALIBRATE

  static const PlateTheme standard = PlateTheme(
    plateBackground: CubaColors.field,
    plateBorder: CubaColors.ink,
    ink: CubaColors.ink,
    dividerColor: CubaColors.ink,
    borderWidthRatio: borderWidthRatio,
    plateRadiusRatio: _plateRadiusRatio,
    activeColor: CubaColors.ink,
    inactiveColor: CubaColors.inactive,
    alertColor: Color(0xFFD32F2F),
  );
}
