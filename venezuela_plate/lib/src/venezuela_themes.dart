import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'venezuela_colors.dart';

/// Every current Venezuelan car plate is navy on the flag, so there is one
/// theme. The flag is geometry and lives on the spec's background.
abstract final class VenezuelaThemes {
  /// The navy frame is ~3 mm of 150 (3.0, 3.25, 2.75 on AB174SK).
  static const double borderWidthRatio = 0.02;

  /// ~8 mm corners on a 150 mm plate, estimated from the photographs' arcs.
  static const double _plateRadiusRatio = 0.053; // CALIBRATE

  static const PlateTheme standard = PlateTheme(
    plateBackground: VenezuelaColors.field,
    plateBorder: VenezuelaColors.ink,
    ink: VenezuelaColors.ink,
    dividerColor: VenezuelaColors.ink,
    borderWidthRatio: borderWidthRatio,
    plateRadiusRatio: _plateRadiusRatio,
    activeColor: VenezuelaColors.ink,
    inactiveColor: VenezuelaColors.inactive,
    alertColor: Color(0xFFD32F2F),
  );
}
