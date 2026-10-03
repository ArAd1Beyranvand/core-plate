import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'indonesia_colors.dart';

/// The Indonesian liveries: one ink on one field, a rim in the ink, and —
/// for the banded specs — a band colour. The band is a background region
/// filled with `PlateFill.divider`, so [PlateTheme.dividerColor] *is* the band:
/// [IndonesiaColors.evBlue] on an EV, black on the diplomatic trim. No spec
/// draws a divider rule, so the colour is used for nothing else.
///
/// **Rim drawn at the edge.** The artwork's rim is inset: 1.5 mm of field,
/// then 2.9 mm of ink (y 1.6–4.5 on both sizes). `PlateTheme` paints its border
/// at the plate edge, so the rim is drawn 2.9 mm thick from the edge and the
/// outer sliver of field is lost. Corner radius ~8 mm at the rim's outer edge
/// on both sizes; 0.06 of height gives 8.1 (car) and 6.9 (motorcycle).
abstract final class IndonesiaThemes {
  static const double _borderWidthRatio = 0.022;
  static const double _plateRadiusRatio = 0.06;

  static PlateTheme _livery({
    required Color field,
    required Color ink,
    required Color inactive,
    Color? band,
  }) => PlateTheme(
    plateBackground: field,
    plateBorder: ink,
    ink: ink,
    dividerColor: band ?? ink,
    borderWidthRatio: _borderWidthRatio,
    plateRadiusRatio: _plateRadiusRatio,
    activeColor: ink,
    inactiveColor: inactive,
    alertColor: const Color(0xFFD32F2F),
  );

  /// Black on white: private vehicles, private trucks and ambulances. Also the
  /// Greater Jakarta temporary `SS…` plates, which differ only in suffix.
  static final PlateTheme private = _livery(
    field: IndonesiaColors.white,
    ink: IndonesiaColors.black,
    inactive: IndonesiaColors.inactiveOnLight,
  );

  /// Black on yellow: buses, taxis, angkot and commercial trucks.
  static final PlateTheme public = _livery(
    field: IndonesiaColors.publicYellow,
    ink: IndonesiaColors.black,
    inactive: IndonesiaColors.inactiveOnLight,
  );

  /// White on red: government vehicles.
  static final PlateTheme government = _livery(
    field: IndonesiaColors.governmentRed,
    ink: IndonesiaColors.white,
    inactive: IndonesiaColors.inactiveOnDark,
  );

  /// Black on green: vehicles restricted to a free-trade zone.
  static final PlateTheme freeTradeZone = _livery(
    field: IndonesiaColors.ftzGreen,
    ink: IndonesiaColors.black,
    inactive: IndonesiaColors.inactiveOnLight,
  );

  static final PlateTheme privateEv = _livery(
    field: IndonesiaColors.white,
    ink: IndonesiaColors.black,
    inactive: IndonesiaColors.inactiveOnLight,
    band: IndonesiaColors.evBlue,
  );

  static final PlateTheme publicEv = _livery(
    field: IndonesiaColors.publicYellow,
    ink: IndonesiaColors.black,
    inactive: IndonesiaColors.inactiveOnLight,
    band: IndonesiaColors.evBlue,
  );

  static final PlateTheme governmentEv = _livery(
    field: IndonesiaColors.governmentRed,
    ink: IndonesiaColors.white,
    inactive: IndonesiaColors.inactiveOnDark,
    band: IndonesiaColors.evBlue,
  );

  static final PlateTheme freeTradeZoneEv = _livery(
    field: IndonesiaColors.ftzGreen,
    ink: IndonesiaColors.black,
    inactive: IndonesiaColors.inactiveOnLight,
    band: IndonesiaColors.evBlue,
  );

  /// Black on white over a black trim band.
  static final PlateTheme diplomatic = _livery(
    field: IndonesiaColors.white,
    ink: IndonesiaColors.black,
    inactive: IndonesiaColors.inactiveOnLight,
    band: IndonesiaColors.black,
  );

  /// White on black over the EV blue band.
  static final PlateTheme diplomaticEv = _livery(
    field: IndonesiaColors.black,
    ink: IndonesiaColors.white,
    inactive: IndonesiaColors.inactiveOnDark,
    band: IndonesiaColors.evBlue,
  );
}
