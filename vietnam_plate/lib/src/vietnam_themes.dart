import 'package:flutter/widgets.dart';

import 'package:plate_core/plate_core.dart';

import 'vietnam_colors.dart';

/// The Vietnamese liveries. Every one is one ink on one field, so they are one
/// helper and four calls.
///
/// QCVN 08 §1.4: the rim is printed in the characters' colour. The military
/// plate has no visible rim in its template, so its border is the field.
/// The corner radius is R10 mm; as a fraction of height that is 6–9% across
/// the three shapes, and 0.07 is the compromise (the ratio is the theme's, not
/// the spec's). The border width is per spec: see `VietnamPlates`.
abstract final class VietnamThemes {
  static const double _radius = 0.07;

  static PlateTheme _livery({
    required Color field,
    required Color ink,
    required Color inactive,
    bool rim = true,
  }) => PlateTheme(
    plateBackground: field,
    plateBorder: rim ? ink : field,
    ink: ink,
    dividerColor: ink,
    borderWidthRatio: 0.03,
    plateRadiusRatio: _radius,
    activeColor: ink,
    inactiveColor: inactive,
  );

  /// Black on white: private, diplomatic, foreign and temporary plates.
  static final PlateTheme white = _livery(
    field: VietnamColors.white,
    ink: VietnamColors.black,
    inactive: VietnamColors.inactiveOnLight,
  );

  /// Black on yellow: commercial vehicles since 1 August 2020.
  static final PlateTheme yellow = _livery(
    field: VietnamColors.yellow,
    ink: VietnamColors.black,
    inactive: VietnamColors.inactiveOnLight,
  );

  /// White on blue: state organisations.
  static final PlateTheme blue = _livery(
    field: VietnamColors.blue,
    ink: VietnamColors.whiteInk,
    inactive: VietnamColors.inactiveOnDark,
  );

  /// White on red: Ministry of National Defence.
  static final PlateTheme red = _livery(
    field: VietnamColors.red,
    ink: VietnamColors.whiteInk,
    inactive: VietnamColors.inactiveOnDark,
    rim: false,
  );
}
