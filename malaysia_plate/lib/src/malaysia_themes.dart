import 'package:plate_core/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'malaysia_colors.dart';

/// The Malaysian liveries. Every one is one ink on one field, so they are
/// one helper and five calls.
///
/// A standard Malaysian plate is frameless — the chrome surrounds in the
/// photos are dealer frames — so the border is drawn in the field colour and
/// disappears. Only the JPJePlate has a printed black rim.
abstract final class MalaysiaThemes {
  static const double _plateRadiusRatio = 0.04; // CALIBRATE

  static PlateTheme _field({
    required Color field,
    required Color ink,
    required Color inactive,
    Color? rim,
    double borderWidthRatio = 0.02,
  }) => PlateTheme(
    plateBackground: field,
    plateBorder: rim ?? field,
    ink: ink,
    dividerColor: ink,
    borderWidthRatio: borderWidthRatio,
    plateRadiusRatio: _plateRadiusRatio,
    activeColor: ink,
    inactiveColor: inactive,
    alertColor: const Color(0xFFD32F2F),
  );

  /// White on black: every private and commercial vehicle, and the military
  /// `Z` series.
  static final PlateTheme standard = _field(
    field: MalaysiaColors.black,
    ink: MalaysiaColors.lightInk,
    inactive: MalaysiaColors.inactiveOnDark,
  );

  /// Black on white (reflective aluminium): taxis and hire cars, `H` series.
  static final PlateTheme taxi = _field(
    field: MalaysiaColors.taxiField,
    ink: MalaysiaColors.darkInk,
    inactive: MalaysiaColors.inactiveOnLight,
  );

  /// White on red: the diplomatic corps (`DC`) and, on some plates, `UN`.
  static final PlateTheme diplomatic = _field(
    field: MalaysiaColors.diplomaticRed,
    ink: MalaysiaColors.diplomaticInk,
    inactive: MalaysiaColors.inactiveOnDark,
  );

  /// White on black: consular (`CC`) and international-organisation (`PA`)
  /// plates — the diplomatic geometry on the standard colours.
  static final PlateTheme consular = standard;

  /// Black on white with a black rim: the JPJePlate. The artwork's rim lies
  /// outside the 1241 px interior mapped to 520 mm, so drawn at its 8 mm it
  /// would cover MAL; 3.3 mm keeps the rim and clears the strip's wording.
  static final PlateTheme ev = _field(
    field: MalaysiaColors.evField,
    ink: MalaysiaColors.darkInk,
    inactive: MalaysiaColors.inactiveOnLight,
    rim: MalaysiaColors.darkInk,
    borderWidthRatio: 0.03,
  );
}
