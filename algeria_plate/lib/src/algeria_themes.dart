import 'package:plate_core/plate_core.dart';
import 'package:flutter/widgets.dart';

import 'algeria_colors.dart';

/// The Algerian liveries: one ink on one field, framed in the ink.
///
/// Rim and corner are measured off the artwork normalised to 520×110: the
/// black rim is 4.3 mm, the outer corner radius 7.4 mm. Both ratios are of
/// the canvas height, so the two-line plate's rim scales with it.
abstract final class AlgeriaThemes {
  static PlateTheme _field({
    required Color field,
    required Color ink,
    required Color inactive,
    double borderWidthRatio = 0.039,
  }) => PlateTheme(
    plateBackground: field,
    plateBorder: ink,
    ink: ink,
    dividerColor: ink,
    borderWidthRatio: borderWidthRatio,
    plateRadiusRatio: 0.067,
    activeColor: ink,
    inactiveColor: inactive,
    alertColor: const Color(0xFFD32F2F),
  );

  /// Black on white: every front plate.
  static final PlateTheme front = _field(
    field: AlgeriaColors.white,
    ink: AlgeriaColors.black,
    inactive: AlgeriaColors.inactiveOnLight,
  );

  /// Black on yellow: every rear plate.
  static final PlateTheme rear = _field(
    field: AlgeriaColors.yellow,
    ink: AlgeriaColors.black,
    inactive: AlgeriaColors.inactiveOnLight,
  );

  /// Black on teal: diplomatic plates, front and rear.
  static final PlateTheme diplomatic = _field(
    field: AlgeriaColors.diplomaticTeal,
    ink: AlgeriaColors.black,
    inactive: AlgeriaColors.inactiveOnDark,
  );

  /// Silver on black with a silver rim, 4.8 mm in the army photo.
  static final PlateTheme army = _field(
    field: AlgeriaColors.armyField,
    ink: AlgeriaColors.armySilver,
    inactive: AlgeriaColors.inactiveOnDark,
    borderWidthRatio: 0.044,
  );
}
