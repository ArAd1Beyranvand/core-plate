import 'package:plate_core/plate_core.dart';
import 'package:flutter/widgets.dart';

import 'bolivia_colors.dart';

/// The Bolivian liveries: one ink on one field, framed in the ink.
///
/// Measured off the PTA photo normalised to 300×152: the pressed rim is
/// 3–4.4 mm, 0.023 of the height, and the outer corner ~6 mm, 0.04. The
/// diplomatic plate's rim is an unpainted lip, so its frame is the field.
/// The Mercosur plate (400×130) has a thin black edge, ~2.5 mm.
abstract final class BoliviaThemes {
  static PlateTheme _livery({
    required Color field,
    required Color ink,
    required Color inactive,
    Color? rim,
    double borderWidthRatio = 0.023,
  }) => PlateTheme(
    plateBackground: field,
    plateBorder: rim ?? ink,
    ink: ink,
    dividerColor: ink,
    borderWidthRatio: borderWidthRatio,
    plateRadiusRatio: 0.04,
    activeColor: ink,
    inactiveColor: inactive,
    alertColor: const Color(0xFFD32F2F),
  );

  /// Blue on white: every PTA plate, whatever its service.
  static final PlateTheme standard = _livery(
    field: BoliviaColors.white,
    ink: BoliviaColors.blue,
    inactive: BoliviaColors.inactiveOnLight,
  );

  /// Red on white: diplomatic corps (`CD`). Measured.
  static final PlateTheme diplomatic = _livery(
    field: BoliviaColors.diplomaticWhite,
    ink: BoliviaColors.diplomaticRed,
    inactive: BoliviaColors.inactiveOnLight,
    rim: BoliviaColors.diplomaticWhite,
  );

  /// White on blue: consular corps (`CC`). Not photographed.
  static final PlateTheme consular = _livery(
    field: BoliviaColors.consularBlue,
    ink: BoliviaColors.white,
    inactive: BoliviaColors.inactiveOnDark,
  );

  /// Black on yellow: international missions (`MI`). Not photographed.
  static final PlateTheme mission = _livery(
    field: BoliviaColors.missionYellow,
    ink: BoliviaColors.black,
    inactive: BoliviaColors.inactiveOnDark,
  );

  /// White on green: international organisations (`OI`). Not photographed.
  static final PlateTheme organization = _livery(
    field: BoliviaColors.organizationGreen,
    ink: BoliviaColors.white,
    inactive: BoliviaColors.inactiveOnDark,
  );

  /// Black on white under the blue band: the Mercosur plate.
  static final PlateTheme mercosur = _livery(
    field: BoliviaColors.mercosurWhite,
    ink: BoliviaColors.mercosurBlack,
    inactive: BoliviaColors.inactiveOnLight,
    borderWidthRatio: 0.019,
  );
}
