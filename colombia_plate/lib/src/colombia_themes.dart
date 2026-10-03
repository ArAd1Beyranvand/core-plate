import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'colombia_colors.dart';

/// The Colombian liveries: one ink on one field, framed in the ink.
///
/// Measured off the private artwork normalised to 330×165: the rim line is
/// ~2 mm, 0.015 of the height, and the outer corner ~6 mm, 0.036.
abstract final class ColombiaThemes {
  static PlateTheme _livery({
    required Color field,
    required Color ink,
    required Color inactive,
    Color? rim,
    Color? divider,
  }) => PlateTheme(
    plateBackground: field,
    plateBorder: rim ?? ink,
    ink: ink,
    dividerColor: divider ?? ink,
    borderWidthRatio: 0.015,
    plateRadiusRatio: 0.036,
    activeColor: ink,
    inactiveColor: inactive,
    alertColor: const Color(0xFFD32F2F),
  );

  /// Black on yellow: private cars and private mototaxis.
  static final PlateTheme private = _livery(
    field: ColombiaColors.privateYellow,
    ink: ColombiaColors.privateBlack,
    inactive: ColombiaColors.inactiveOnLight,
  );

  /// Black on white: public service, commercial mototaxis.
  static final PlateTheme commercial = _livery(
    field: ColombiaColors.commercialWhite,
    ink: ColombiaColors.commercialBlack,
    inactive: ColombiaColors.inactiveOnLight,
  );

  /// White on teal: official vehicles and trailers.
  static final PlateTheme official = _livery(
    field: ColombiaColors.officialTeal,
    ink: ColombiaColors.officialWhite,
    inactive: ColombiaColors.inactiveOnDark,
  );

  /// Dark on white; the divider colour paints the cyan side strips.
  static final PlateTheme antique = _livery(
    field: ColombiaColors.antiqueWhite,
    ink: ColombiaColors.antiqueInk,
    inactive: ColombiaColors.inactiveOnLight,
    divider: ColombiaColors.antiqueBlue,
  );

  /// White on red: tank trucks. Not photographed.
  static final PlateTheme tank = _livery(
    field: ColombiaColors.tankRed,
    ink: ColombiaColors.officialWhite,
    inactive: ColombiaColors.inactiveOnDark,
  );

  static final PlateTheme consular = _livery(
    field: ColombiaColors.consularBlue,
    ink: ColombiaColors.consularWhite,
    inactive: ColombiaColors.inactiveOnDark,
  );

  static final PlateTheme organization = _livery(
    field: ColombiaColors.organizationBlue,
    ink: ColombiaColors.organizationWhite,
    inactive: ColombiaColors.inactiveOnDark,
  );

  static final PlateTheme staff = _livery(
    field: ColombiaColors.staffBlue,
    ink: ColombiaColors.staffWhite,
    inactive: ColombiaColors.inactiveOnDark,
  );

  /// Green on white: National Police.
  static final PlateTheme police = _livery(
    field: ColombiaColors.policeWhite,
    ink: ColombiaColors.policeGreen,
    inactive: ColombiaColors.inactiveOnLight,
  );

  /// Dark grey on white in a dark rim: the new diplomatic-corps plate.
  static final PlateTheme diplomatic = _livery(
    field: ColombiaColors.diplomaticWhite,
    ink: ColombiaColors.diplomaticInk,
    inactive: ColombiaColors.inactiveOnLight,
    rim: ColombiaColors.diplomaticRim,
  );
}
