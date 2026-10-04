import 'package:plate_core/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'tunisia_colors.dart';

/// The Tunisian liveries: one ink on one field, a rim in silver or the ink.
///
/// Measured off the photos normalised to 520×110: the rim is 4–5 mm on every
/// plate (4.5 on the military one), so 0.041 of the height. The outer corner
/// is ~5 mm on the pressed plates and ~10 mm on the military one. Both ratios
/// are of the canvas height. Dashes are `PlateRule`s, so [PlateTheme.dividerColor]
/// is the ink.
abstract final class TunisiaThemes {
  static PlateTheme _livery({
    required Color field,
    required Color ink,
    required Color inactive,
    Color? rim,
    double plateRadiusRatio = 0.045,
  }) => PlateTheme(
    plateBackground: field,
    plateBorder: rim ?? ink,
    ink: ink,
    dividerColor: ink,
    borderWidthRatio: 0.041,
    plateRadiusRatio: plateRadiusRatio,
    activeColor: ink,
    inactiveColor: inactive,
    alertColor: const Color(0xFFD32F2F),
  );

  /// White on black in a silver rim: the ordinary plate, and the temporary
  /// (`ن ت`) plate, which the photo shows in the same paint.
  static final PlateTheme standard = _livery(
    field: TunisiaColors.black,
    ink: TunisiaColors.white,
    inactive: TunisiaColors.inactiveOnDark,
    rim: TunisiaColors.rimSilver,
  );

  /// White on blue in a silver rim: rental cars.
  static final PlateTheme rental = _livery(
    field: TunisiaColors.rentalBlue,
    ink: TunisiaColors.white,
    inactive: TunisiaColors.inactiveOnDark,
    rim: TunisiaColors.rimSilver,
  );

  /// Red on white, framed in red: ministries and state offices.
  static final PlateTheme government = _livery(
    field: TunisiaColors.governmentWhite,
    ink: TunisiaColors.governmentRed,
    inactive: TunisiaColors.inactiveOnLight,
  );

  /// Black on white, framed in black: diplomatic missions.
  static final PlateTheme diplomatic = _livery(
    field: TunisiaColors.diplomaticWhite,
    ink: TunisiaColors.diplomaticBlack,
    inactive: TunisiaColors.inactiveOnLight,
  );

  /// White on black, framed in white, with rounder corners.
  static final PlateTheme military = _livery(
    field: TunisiaColors.black,
    ink: TunisiaColors.white,
    inactive: TunisiaColors.inactiveOnDark,
    plateRadiusRatio: 0.09,
  );
}
