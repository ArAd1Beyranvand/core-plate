import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'mali_colors.dart';

/// The themes for Mali plates — one simple black on white.
abstract final class MaliThemes {
  static const double _borderWidthRatio = 0.04;
  static const double _radiusRatio = 0.12;

  /// The standard Mali plate theme: black ink on white field, black frame.
  static const PlateTheme standard = PlateTheme.monochrome(
    field: MaliColors.white,
    ink: MaliColors.black,
    inactive: Color(0x66666666),
    borderWidthRatio: _borderWidthRatio,
    plateRadiusRatio: _radiusRatio,
  );
}
